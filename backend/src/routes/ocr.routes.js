import express from 'express';
import axios from 'axios';
import logger from '../utils/logger.js';

const router = express.Router();

// Service URL from environment
const OCR_SERVICE_URL = process.env.OCR_SERVICE_URL || 'http://localhost:3002';

/**
 * @route   POST /api/ocr/extract
 * @desc    Extract text from image using OCR service
 * @access  Private
 */
router.post('/extract', async (req, res, next) => {
  try {
    // Forward request to OCR service
    const response = await axios.post(
      `${OCR_SERVICE_URL}/extract`,
      req.body,
      {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        // Pass through the raw request data for multipart
        data: req.body
      }
    );

    logger.info('OCR extract request forwarded to OCR service');

    res.json({
      success: true,
      data: response.data
    });
  } catch (error) {
    logger.error('OCR extract service error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        success: false,
        message: 'OCR service unavailable',
        details: 'The optical character recognition service is not running'
      });
    }

    next(error);
  }
});

/**
 * @route   POST /api/ocr/extract-batch
 * @desc    Extract text from multiple images
 * @access  Private
 */
router.post('/extract-batch', async (req, res, next) => {
  try {
    // Forward request to OCR service
    const response = await axios.post(
      `${OCR_SERVICE_URL}/extract-batch`,
      req.body,
      {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      }
    );

    logger.info('OCR batch extract request forwarded to OCR service');

    res.json({
      success: true,
      data: response.data
    });
  } catch (error) {
    logger.error('OCR batch extract service error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        success: false,
        message: 'OCR service unavailable',
        details: 'The optical character recognition service is not running'
      });
    }

    next(error);
  }
});

/**
 * @route   GET /api/ocr/health
 * @desc    Check OCR service health
 * @access  Public
 */
router.get('/health', async (req, res) => {
  try {
    const response = await axios.get(`${OCR_SERVICE_URL}/health`);
    
    res.json({
      success: true,
      data: {
        ocrService: response.data,
        url: OCR_SERVICE_URL
      }
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      message: 'OCR service unhealthy',
      details: error.message
    });
  }
});

export default router;
