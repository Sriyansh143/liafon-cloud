import express from 'express';
import axios from 'axios';
import logger from '../utils/logger.js';

const router = express.Router();

// Service URL from environment
const VOICE_SERVICE_URL = process.env.VOICE_SERVICE_URL || 'http://localhost:3003';

/**
 * @route   POST /api/voice/stt
 * @desc    Speech-to-Text - Convert audio to text
 * @access  Private
 */
router.post('/stt', async (req, res, next) => {
  try {
    // Forward request to voice service
    const response = await axios.post(
      `${VOICE_SERVICE_URL}/stt`,
      req.body,
      {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        // Pass through the raw request data for multipart
        data: req.body
      }
    );

    logger.info('STT request forwarded to voice service');

    res.json({
      success: true,
      data: response.data
    });
  } catch (error) {
    logger.error('STT service error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        success: false,
        message: 'Voice service unavailable',
        details: 'The speech-to-text service is not running'
      });
    }

    next(error);
  }
});

/**
 * @route   POST /api/voice/tts
 * @desc    Text-to-Speech - Convert text to audio
 * @access  Private
 */
router.post('/tts', async (req, res, next) => {
  try {
    const { text, voice = 'default' } = req.body;

    if (!text) {
      return res.status(400).json({
        success: false,
        message: 'Text is required for TTS'
      });
    }

    // Forward request to voice service
    const response = await axios.post(
      `${VOICE_SERVICE_URL}/tts`,
      { text, voice }
    );

    logger.info('TTS request forwarded to voice service');

    res.json({
      success: true,
      data: response.data
    });
  } catch (error) {
    logger.error('TTS service error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        success: false,
        message: 'Voice service unavailable',
        details: 'The text-to-speech service is not running'
      });
    }

    next(error);
  }
});

/**
 * @route   GET /api/voice/health
 * @desc    Check voice service health
 * @access  Public
 */
router.get('/health', async (req, res) => {
  try {
    const response = await axios.get(`${VOICE_SERVICE_URL}/health`);
    
    res.json({
      success: true,
      data: {
        voiceService: response.data,
        url: VOICE_SERVICE_URL
      }
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      message: 'Voice service unhealthy',
      details: error.message
    });
  }
});

export default router;
