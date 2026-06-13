import express from 'express';
import {
  validateHealthMetric,
  validateSleepRecord,
  validatePagination
} from '../middleware/validators.js';
import pocketbaseService from '../services/pocketbase.service.js';
import redisService from '../services/redis.service.js';
import ollamaService from '../services/ollama.service.js';
import logger from '../utils/logger.js';

const router = express.Router();

/**
 * @route   POST /api/health/sync
 * @desc    Sync health metrics from watch to backend
 * @access  Private (requires auth)
 */
router.post('/sync', validateHealthMetric, async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user'; // Replace with actual auth
    const { type, value, timestamp } = req.body;

    // Save to database
    const metric = await pocketbaseService.saveHealthMetric(userId, {
      type,
      value,
      timestamp: timestamp || new Date().toISOString()
    });

    // Cache latest metrics
    const cachedMetrics = await redisService.getCachedHealthMetrics(userId);
    const updatedMetrics = {
      ...cachedMetrics,
      [type]: { value, timestamp: metric.created }
    };
    await redisService.cacheHealthMetrics(userId, updatedMetrics, 300);

    // Award points for health check
    if (type === 'heart_rate' || type === 'steps') {
      await pocketbaseService.addPoints(userId, 10, `Health check: ${type}`, 'earn');
    }

    logger.info(`Health metric synced: ${type} for user ${userId}`);

    res.json({
      success: true,
      message: 'Health metric synced successfully',
      data: metric
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/health/metrics
 * @desc    Get user's health metrics
 * @access  Private
 */
router.get('/metrics', validatePagination, async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const page = req.query.page || 1;
    const perPage = req.query.perPage || 20;

    // Try cache first
    let metrics = await redisService.getCachedHealthMetrics(userId);
    
    if (!metrics) {
      metrics = await pocketbaseService.getHealthMetrics(userId, { page, perPage });
      // Cache for 5 minutes
      await redisService.cacheHealthMetrics(userId, metrics, 300);
    }

    res.json({
      success: true,
      data: metrics
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/health/sleep
 * @desc    Get sleep analysis and insights
 * @access  Private
 */
router.get('/sleep', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { startDate, endDate } = req.query;

    const start = startDate || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const end = endDate || new Date().toISOString();

    const sleepRecords = await pocketbaseService.getSleepRecords(userId, start, end);

    // Generate AI insights if we have recent data
    let aiInsights = null;
    if (sleepRecords.length > 0) {
      const latestSleep = sleepRecords[0];
      const healthData = {
        heartRate: 72, // Would fetch from latest metrics
        spo2: 98,
        sleepQuality: latestSleep.quality,
        stressLevel: 'moderate',
        steps: 8000,
        calories: 2200
      };
      
      try {
        aiInsights = await ollamaService.generateHealthInsights(healthData);
      } catch (aiError) {
        logger.warn('AI insights generation failed:', aiError.message);
      }
    }

    res.json({
      success: true,
      data: {
        records: sleepRecords,
        aiInsights,
        summary: {
          totalRecords: sleepRecords.length,
          averageQuality: sleepRecords.reduce((acc, r) => acc + (r.quality || 0), 0) / sleepRecords.length || 0
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/health/stress
 * @desc    Get stress levels and HRV analysis
 * @access  Private
 */
router.get('/stress', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    
    // Get recent health metrics including HRV data
    const metrics = await pocketbaseService.getHealthMetrics(userId, { page: 1, perPage: 50 });
    
    // Filter stress-related metrics
    const stressMetrics = metrics.filter(m => 
      ['stress', 'heart_rate_variability', 'heart_rate'].includes(m.type)
    );

    // Calculate stress trends
    const stressTrend = stressMetrics.length > 0 
      ? stressMetrics.reduce((acc, m) => acc + (m.value || 0), 0) / stressMetrics.length 
      : 0;

    res.json({
      success: true,
      data: {
        currentStress: stressMetrics[0]?.value || null,
        trend: stressTrend,
        history: stressMetrics,
        recommendations: [
          'Practice deep breathing exercises',
          'Take regular breaks during work',
          'Maintain consistent sleep schedule'
        ]
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/health/prescription/scan
 * @desc    Scan prescription using OCR and save to profile
 * @access  Private
 */
router.post('/prescription/scan', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { imageData } = req.body; // Base64 encoded image

    if (!imageData) {
      return res.status(400).json({
        success: false,
        message: 'Image data is required'
      });
    }

    // TODO: Call PaddleOCR service to extract text
    // For now, simulate OCR result
    const extractedText = 'Simulated OCR text from prescription';

    // Use AI to analyze prescription
    const prescriptionData = await ollamaService.analyzePrescription(extractedText);

    // Save to database
    const prescription = await pocketbaseService.savePrescription(userId, {
      rawText: extractedText,
      ...prescriptionData,
      scannedAt: new Date().toISOString()
    });

    // Award points for scanning
    await pocketbaseService.addPoints(userId, 50, 'Prescription scan', 'earn');

    logger.info(`Prescription scanned for user ${userId}`);

    res.json({
      success: true,
      message: 'Prescription scanned successfully',
      data: prescription
    });
  } catch (error) {
    next(error);
  }
});

export default router;
