import express from 'express';
import axios from 'axios';
import logger from '../utils/logger.js';

const router = express.Router();

// Service URL from environment
const AI_CHAT_SERVICE_URL = process.env.AI_CHAT_SERVICE_URL || 'http://localhost:3001';

/**
 * @route   POST /api/ai/chat-remote
 * @desc    Chat with AI using remote liafon-ai-chat service
 * @access  Private
 */
router.post('/chat-remote', async (req, res, next) => {
  try {
    const { message, model = 'phi3:mini', system, history = [] } = req.body;

    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Message is required'
      });
    }

    // Forward request to AI Chat service
    const response = await axios.post(
      `${AI_CHAT_SERVICE_URL}/chat`,
      { message, model, system, history }
    );

    logger.info('Chat request forwarded to AI Chat service');

    res.json({
      success: true,
      data: response.data,
      source: 'liafon-ai-chat'
    });
  } catch (error) {
    logger.error('AI Chat service error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        success: false,
        message: 'AI Chat service unavailable',
        details: 'The AI chat service is not running'
      });
    }

    next(error);
  }
});

/**
 * @route   POST /api/ai/generate-remote
 * @desc    Generate text using remote liafon-ai-chat service
 * @access  Private
 */
router.post('/generate-remote', async (req, res, next) => {
  try {
    const { prompt, model = 'phi3:mini', system } = req.body;

    if (!prompt) {
      return res.status(400).json({
        success: false,
        message: 'Prompt is required'
      });
    }

    // Forward request to AI Chat service
    const response = await axios.post(
      `${AI_CHAT_SERVICE_URL}/generate`,
      { prompt, model, system }
    );

    logger.info('Generate request forwarded to AI Chat service');

    res.json({
      success: true,
      data: response.data,
      source: 'liafon-ai-chat'
    });
  } catch (error) {
    logger.error('AI Generate service error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        success: false,
        message: 'AI Chat service unavailable',
        details: 'The AI chat service is not running'
      });
    }

    next(error);
  }
});

/**
 * @route   GET /api/ai/models-remote
 * @desc    Get available models from remote liafon-ai-chat service
 * @access  Public
 */
router.get('/models-remote', async (req, res) => {
  try {
    const response = await axios.get(`${AI_CHAT_SERVICE_URL}/models`);
    
    res.json({
      success: true,
      data: response.data,
      source: 'liafon-ai-chat'
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      message: 'AI Chat service unhealthy',
      details: error.message
    });
  }
});

/**
 * @route   GET /api/ai/health-remote
 * @desc    Check AI Chat service health
 * @access  Public
 */
router.get('/health-remote', async (req, res) => {
  try {
    const response = await axios.get(`${AI_CHAT_SERVICE_URL}/health`);
    
    res.json({
      success: true,
      data: {
        aiChatService: response.data,
        url: AI_CHAT_SERVICE_URL
      }
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      message: 'AI Chat service unhealthy',
      details: error.message
    });
  }
});

export default router;
