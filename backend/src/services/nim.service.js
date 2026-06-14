/**
 * NVIDIA NIM API Service
 * 
 * Emergency fallback AI service using NVIDIA's free tier.
 * Implements intelligent caching to minimize API calls.
 * 
 * Usage Limits (Free Tier):
 * - 1000 requests/month per endpoint
 * - Rate limit: 60 requests/minute
 * - Only used when local Ollama models fail
 */

const axios = require('axios');
const crypto = require('crypto');

class NimService {
  constructor() {
    this.baseURL = process.env.NVIDIA_NIM_BASE_URL || 'https://integrate.api.nvidia.com/v1';
    this.apiKey = process.env.NVIDIA_NIM_API_KEY;
    this.enabled = !!this.apiKey;
    this.monthlyLimit = parseInt(process.env.NVIDIA_MONTHLY_LIMIT) || 1000;
    this.requestCount = 0;
    this.cachePrefix = 'nim_cache:';
    
    // Available free models on NVIDIA NIM
    this.availableModels = {
      'llama3-70b': 'meta/llama3-70b-instruct',
      'llama3-8b': 'meta/llama3-8b-instruct',
      'mistral-large': 'mistralai/mistral-large',
      'mixtral-8x7b': 'mistralai/mixtral-8x7b-instruct-v0.1',
      'phi3-mini': 'microsoft/phi-3-mini-128k-instruct',
    };
  }

  /**
   * Generate cache key from request parameters
   */
  generateCacheKey(message, model, systemPrompt = '') {
    const hash = crypto.createHash('sha256');
    hash.update(`${message}|${model}|${systemPrompt}`);
    return `${this.cachePrefix}${hash.digest('hex')}`;
  }

  /**
   * Check if we can make API calls (within limits)
   */
  async checkLimits() {
    if (!this.enabled) {
      return { allowed: false, reason: 'NVIDIA NIM not configured' };
    }

    if (this.requestCount >= this.monthlyLimit) {
      return { allowed: false, reason: 'Monthly limit reached' };
    }

    // Check Redis for monthly counter
    try {
      const redis = require('./redis.service');
      const monthKey = `nim:monthly:${new Date().toISOString().slice(0, 7)}`;
      const count = await redis.get(monthKey);
      this.requestCount = parseInt(count) || 0;

      if (this.requestCount >= this.monthlyLimit) {
        return { allowed: false, reason: 'Monthly limit reached' };
      }

      return { allowed: true, remaining: this.monthlyLimit - this.requestCount };
    } catch (error) {
      console.error('Error checking NIM limits:', error);
      return { allowed: true, remaining: this.monthlyLimit - this.requestCount };
    }
  }

  /**
   * Increment usage counter
   */
  async incrementUsage() {
    try {
      const redis = require('./redis.service');
      const monthKey = `nim:monthly:${new Date().toISOString().slice(0, 7)}`;
      await redis.incr(monthKey);
      await redis.expire(monthKey, 2592000); // 30 days
      this.requestCount++;
    } catch (error) {
      console.error('Error incrementing NIM usage:', error);
    }
  }

  /**
   * Get cached response if available
   */
  async getCachedResponse(cacheKey) {
    try {
      const redis = require('./redis.service');
      const cached = await redis.get(cacheKey);
      if (cached) {
        const parsed = JSON.parse(cached);
        console.log('[NIM] Cache HIT for request');
        return { ...parsed, cached: true };
      }
      return null;
    } catch (error) {
      console.error('Error getting cached NIM response:', error);
      return null;
    }
  }

  /**
   * Cache response for future use
   */
  async cacheResponse(cacheKey, response) {
    try {
      const redis = require('./redis.service');
      // Permanent cache for NIM responses (no expiry)
      await redis.setex(cacheKey, 31536000, JSON.stringify(response)); // 1 year
      console.log('[NIM] Response cached permanently');
    } catch (error) {
      console.error('Error caching NIM response:', error);
    }
  }

  /**
   * Call NVIDIA NIM API
   */
  async chat({ message, model = 'llama3-8b', systemPrompt = '', temperature = 0.7 }) {
    const startTime = Date.now();
    const nimModel = this.availableModels[model] || this.availableModels['llama3-8b'];
    const cacheKey = this.generateCacheKey(message, nimModel, systemPrompt);

    // Check cache first
    const cachedResponse = await this.getCachedResponse(cacheKey);
    if (cachedResponse) {
      return {
        success: true,
        response: cachedResponse.response,
        source: 'cache',
        model: nimModel,
        cached: true,
        timeMs: Date.now() - startTime
      };
    }

    // Check limits
    const limitCheck = await this.checkLimits();
    if (!limitCheck.allowed) {
      throw new Error(`NVIDIA NIM unavailable: ${limitCheck.reason}`);
    }

    if (!this.enabled) {
      throw new Error('NVIDIA NIM API key not configured');
    }

    try {
      const messages = [];
      
      if (systemPrompt) {
        messages.push({ role: 'system', content: systemPrompt });
      }
      
      messages.push({ role: 'user', content: message });

      const response = await axios.post(
        `${this.baseURL}/chat/completions`,
        {
          model: nimModel,
          messages,
          temperature,
          max_tokens: 1024,
          stream: false
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          timeout: 30000 // 30s timeout
        }
      );

      const result = response.data.choices[0].message.content;

      // Cache the response
      await this.cacheResponse(cacheKey, { response: result, model: nimModel });

      // Increment usage counter
      await this.incrementUsage();

      console.log(`[NIM] Request successful (${Date.now() - startTime}ms), remaining: ${limitCheck.remaining - 1}`);

      return {
        success: true,
        response: result,
        source: 'nvidia-nim',
        model: nimModel,
        cached: false,
        timeMs: Date.now() - startTime,
        usage: {
          remaining: limitCheck.remaining - 1,
          limit: this.monthlyLimit
        }
      };

    } catch (error) {
      console.error('[NIM] API call failed:', error.message);
      
      if (error.response) {
        throw new Error(`NVIDIA NIM API error: ${error.response.status} - ${JSON.stringify(error.response.data)}`);
      }
      
      throw new Error(`NVIDIA NIM request failed: ${error.message}`);
    }
  }

  /**
   * Health check
   */
  async health() {
    const limitCheck = await this.checkLimits();
    return {
      enabled: this.enabled,
      configured: !!this.apiKey,
      withinLimits: limitCheck.allowed,
      requestCount: this.requestCount,
      monthlyLimit: this.monthlyLimit,
      remaining: limitCheck.remaining || 0,
      availableModels: Object.keys(this.availableModels)
    };
  }
}

module.exports = new NimService();
