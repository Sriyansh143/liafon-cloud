import { createClient } from 'redis';
import logger from '../utils/logger.js';

class RedisService {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.retryCount = 0;
    this.maxRetries = 3;
  }

  async connect() {
    try {
      const host = process.env.REDIS_HOST || 'localhost';
      const port = parseInt(process.env.REDIS_PORT) || 6379;
      const password = process.env.REDIS_PASSWORD || undefined;
      const db = parseInt(process.env.REDIS_DB) || 0;

      this.client = createClient({
        url: `redis://${host}:${port}/${db}`,
        password,
        socket: {
          reconnectStrategy: (retries) => {
            if (retries > this.maxRetries) {
              logger.error('Max Redis reconnection attempts reached');
              return new Error('Redis max retries reached');
            }
            return Math.min(retries * 50, 2000);
          },
          connectTimeout: 10000
        }
      });

      this.client.on('error', (err) => {
        logger.error('Redis Client Error:', err);
        this.isConnected = false;
      });

      this.client.on('connect', () => {
        logger.info('Redis client connected successfully');
        this.isConnected = true;
        this.retryCount = 0;
      });

      await this.client.connect();
      
      return this.client;
    } catch (error) {
      logger.error('Redis connection failed:', error.message);
      throw error;
    }
  }

  getClient() {
    if (!this.isConnected || !this.client) {
      throw new Error('Redis not connected');
    }
    return this.client;
  }

  // Health check with ping
  async ping() {
    try {
      const result = await this.client.ping();
      return result === 'PONG';
    } catch (error) {
      logger.error('Redis ping failed:', error);
      throw error;
    }
  }

  // Cache operations
  async set(key, value, ttl = 3600) {
    try {
      await this.client.setEx(key, ttl, JSON.stringify(value));
      return true;
    } catch (error) {
      logger.error('Redis SET error:', error);
      throw error;
    }
  }

  async get(key) {
    try {
      const data = await this.client.get(key);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      logger.error('Redis GET error:', error);
      throw error;
    }
  }

  async del(key) {
    try {
      await this.client.del(key);
      return true;
    } catch (error) {
      logger.error('Redis DEL error:', error);
      throw error;
    }
  }

  // Health metrics cache
  async cacheHealthMetrics(userId, metrics, ttl = 300) {
    const key = `health:${userId}:latest`;
    return await this.set(key, metrics, ttl);
  }

  async getCachedHealthMetrics(userId) {
    const key = `health:${userId}:latest`;
    return await this.get(key);
  }

  // User session cache
  async cacheUserSession(userId, sessionData, ttl = 86400) {
    const key = `session:${userId}`;
    return await this.set(key, sessionData, ttl);
  }

  async getUserSession(userId) {
    const key = `session:${userId}`;
    return await this.get(key);
  }

  // AI response cache
  async cacheAIResponse(prompt, response, ttl = 3600) {
    const key = `ai:response:${this.hash(prompt)}`;
    return await this.set(key, response, ttl);
  }

  async getCachedAIResponse(prompt) {
    const key = `ai:response:${this.hash(prompt)}`;
    return await this.get(key);
  }

  // Rate limiting
  async incrementRateLimit(key, windowMs) {
    const redisKey = `ratelimit:${key}`;
    const current = await this.client.get(redisKey);
    
    if (current === null) {
      await this.client.setEx(redisKey, Math.ceil(windowMs / 1000), '1');
      return 1;
    }
    
    return await this.client.incr(redisKey);
  }

  // Marketplace matching cache
  async cacheMatches(requirementId, matches, ttl = 600) {
    const key = `marketplace:matches:${requirementId}`;
    return await this.set(key, matches, ttl);
  }

  async getCachedMatches(requirementId) {
    const key = `marketplace:matches:${requirementId}`;
    return await this.get(key);
  }

  // Points balance cache
  async cachePointsBalance(userId, balance, ttl = 300) {
    const key = `points:${userId}:balance`;
    return await this.set(key, balance, ttl);
  }

  async getCachedPointsBalance(userId) {
    const key = `points:${userId}:balance`;
    return await this.get(key);
  }

  // Helper method to hash strings for cache keys
  hash(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(36);
  }

  async disconnect() {
    if (this.client) {
      await this.client.quit();
      this.isConnected = false;
      logger.info('Redis connection closed');
    }
  }
}

export default new RedisService();
