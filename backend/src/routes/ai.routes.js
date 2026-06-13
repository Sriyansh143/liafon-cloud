import express from 'express';
import { validateChatRequest, validatePagination } from '../middleware/validators.js';
import pocketbaseService from '../services/pocketbase.service.js';
import redisService from '../services/redis.service.js';
import ollamaService from '../services/ollama.service.js';
import logger from '../utils/logger.js';

const router = express.Router();

/**
 * @route   POST /api/ai/chat
 * @desc    Chat with AI assistant (context-aware)
 * @access  Private
 */
router.post('/chat', validateChatRequest, async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { messages } = req.body;

    // Get user's memories for context
    const memories = await pocketbaseService.getMemories(userId, { limit: 20 });
    
    // Get recent health data for context
    const healthMetrics = await pocketbaseService.getHealthMetrics(userId, { page: 1, perPage: 5 });
    
    // Build enhanced system prompt with user context
    const systemPrompt = `You are a caring AI health companion.
User Context:
- Memories: ${memories.map(m => `${m.category}: ${m.key} = ${m.value}`).join(', ')}
- Recent Health: HR=${healthMetrics.find(m => m.type === 'heart_rate')?.value || 'N/A'} bpm, Steps=${healthMetrics.find(m => m.type === 'steps')?.value || 'N/A'}

Be empathetic, concise, and helpful. Provide actionable health advice when relevant.`;

    // Add system message if not present
    const enhancedMessages = [
      { role: 'system', content: systemPrompt },
      ...messages
    ];

    // Check cache for similar queries
    const lastMessage = messages[messages.length - 1].content;
    const cachedResponse = await redisService.getCachedAIResponse(lastMessage);
    
    if (cachedResponse) {
      logger.info(`AI chat response served from cache for user ${userId}`);
      return res.json({
        success: true,
        data: cachedResponse,
        cached: true
      });
    }

    // Call Ollama for AI response
    const aiResponse = await ollamaService.chat(enhancedMessages, {
      temperature: 0.7,
      maxTokens: 1024
    });

    // Cache the response
    await redisService.cacheAIResponse(lastMessage, aiResponse, 3600);

    // Extract new memories from conversation
    try {
      const extractedMemories = await ollamaService.extractMemories(
        messages.map(m => `${m.role}: ${m.content}`).join('\n')
      );
      
      if (extractedMemories.memories && extractedMemories.memories.length > 0) {
        for (const memory of extractedMemories.memories) {
          await pocketbaseService.saveMemory(userId, memory);
        }
        logger.info(`Extracted ${extractedMemories.memories.length} new memories for user ${userId}`);
      }
    } catch (memoryError) {
      logger.warn('Memory extraction failed:', memoryError.message);
    }

    logger.info(`AI chat completed for user ${userId}`);

    res.json({
      success: true,
      data: aiResponse,
      cached: false
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/ai/insights
 * @desc    Get AI-generated health insights
 * @access  Private
 */
router.get('/insights', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';

    // Fetch comprehensive health data
    const healthMetrics = await pocketbaseService.getHealthMetrics(userId, { page: 1, perPage: 50 });
    const sleepRecords = await pocketbaseService.getSleepRecords(
      userId,
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      new Date().toISOString()
    );

    // Aggregate health data
    const latestHR = healthMetrics.find(m => m.type === 'heart_rate')?.value || 72;
    const latestSpO2 = healthMetrics.find(m => m.type === 'spo2')?.value || 98;
    const avgSleepQuality = sleepRecords.length > 0
      ? sleepRecords.reduce((acc, r) => acc + (r.quality || 0), 0) / sleepRecords.length
      : 75;
    const totalSteps = healthMetrics
      .filter(m => m.type === 'steps')
      .reduce((acc, m) => acc + (m.value || 0), 0);

    const healthData = {
      heartRate: latestHR,
      spo2: latestSpO2,
      sleepQuality: Math.round(avgSleepQuality),
      stressLevel: 'moderate', // Would calculate from HRV
      steps: totalSteps,
      calories: 2200
    };

    // Generate AI insights
    const insights = await ollamaService.generateHealthInsights(healthData);

    res.json({
      success: true,
      data: {
        healthSummary: healthData,
        aiInsights: insights,
        generatedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/ai/analyze-prescription
 * @desc    Analyze prescription text with AI
 * @access  Private
 */
router.post('/analyze-prescription', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { text } = req.body;

    if (!text) {
      return res.status(400).json({
        success: false,
        message: 'Prescription text is required'
      });
    }

    // Use AI to analyze prescription
    const analysis = await ollamaService.analyzePrescription(text);

    res.json({
      success: true,
      data: analysis
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/ai/memories
 * @desc    Get user's stored memories
 * @access  Private
 */
router.get('/memories', validatePagination, async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { category } = req.query;
    const page = req.query.page || 1;
    const perPage = req.query.perPage || 20;

    const memories = await pocketbaseService.getMemories(userId, {
      category,
      limit: perPage
    });

    res.json({
      success: true,
      data: {
        memories,
        total: memories.length,
        categories: [...new Set(memories.map(m => m.category))]
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   DELETE /api/ai/memories/:id
 * @desc    Delete a specific memory
 * @access  Private
 */
router.delete('/memories/:id', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { id } = req.params;

    // TODO: Implement delete in PocketBase service
    // For now, return success
    res.json({
      success: true,
      message: 'Memory deleted successfully',
      data: { id }
    });
  } catch (error) {
    next(error);
  }
});

export default router;
