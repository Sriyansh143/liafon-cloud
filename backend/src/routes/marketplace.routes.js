import express from 'express';
import { validateRequirement, validatePagination } from '../middleware/validators.js';
import pocketbaseService from '../services/pocketbase.service.js';
import redisService from '../services/redis.service.js';
import ollamaService from '../services/ollama.service.js';
import logger from '../utils/logger.js';

const router = express.Router();

/**
 * @route   GET /api/marketplace/requirements
 * @desc    Get marketplace requirements with filtering
 * @access  Public
 */
router.get('/requirements', validatePagination, async (req, res, next) => {
  try {
    const { category, location, page = 1, perPage = 20 } = req.query;

    // Try cache first
    const cacheKey = `marketplace:requirements:${category || 'all'}:${location || 'all'}:${page}:${perPage}`;
    let cachedData = await redisService.get(cacheKey);

    if (!cachedData) {
      const result = await pocketbaseService.getRequirements({
        page: parseInt(page),
        perPage: parseInt(perPage),
        category,
        location
      });

      cachedData = {
        requirements: result.items,
        totalItems: result.totalItems,
        totalPages: result.totalPages,
        page: result.page,
        perPage: result.perPage
      };

      // Cache for 2 minutes
      await redisService.set(cacheKey, cachedData, 120);
    }

    res.json({
      success: true,
      data: cachedData
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/marketplace/requirements
 * @desc    Create a new requirement post
 * @access  Private
 */
router.post('/requirements', validateRequirement, async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const requirementData = req.body;

    // Calculate points reward based on budget
    const budget = parseFloat(requirementData.budget);
    const pointsReward = Math.min(500, Math.max(100, Math.floor(budget / 100)));

    const requirement = await pocketbaseService.createRequirement(userId, {
      ...requirementData,
      pointsReward,
      postedAt: new Date().toISOString()
    });

    // Award points for posting
    await pocketbaseService.addPoints(userId, 20, 'Posted requirement', 'earn');

    // Invalidate cache
    await redisService.del(`marketplace:requirements:*`);

    logger.info(`New requirement posted by user ${userId}: ${requirement.id}`);

    res.status(201).json({
      success: true,
      message: 'Requirement posted successfully',
      data: requirement
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/marketplace/matches/:requirementId
 * @desc    Get AI-powered matches for a requirement
 * @access  Private
 */
router.get('/matches/:requirementId', async (req, res, next) => {
  try {
    const { requirementId } = req.params;

    // Try cache first
    const cachedMatches = await redisService.getCachedMatches(requirementId);
    if (cachedMatches) {
      return res.json({
        success: true,
        data: cachedMatches,
        cached: true
      });
    }

    // TODO: Fetch requirement and user profiles from database
    // For now, simulate AI matching
    const mockRequirement = {
      title: 'Need a yoga instructor',
      category: 'fitness',
      budget: 2000,
      location: 'Mumbai',
      description: 'Looking for a certified yoga instructor for home sessions'
    };

    const mockUserProfiles = [
      { userId: 'user1', name: 'Priya S.', skills: ['yoga', 'meditation'], location: 'Mumbai', rating: 4.8 },
      { userId: 'user2', name: 'Rahul K.', skills: ['yoga', 'pilates'], location: 'Pune', rating: 4.6 },
      { userId: 'user3', name: 'Anjali M.', skills: ['fitness', 'yoga'], location: 'Mumbai', rating: 4.9 }
    ];

    // Use AI to match
    const matches = await ollamaService.matchRequirementToUsers(mockRequirement, mockUserProfiles);

    // Cache matches for 10 minutes
    await redisService.cacheMatches(requirementId, matches, 600);

    res.json({
      success: true,
      data: {
        requirementId,
        matches,
        totalMatches: matches.length
      },
      cached: false
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/marketplace/offer
 * @desc    Make an offer on a requirement
 * @access  Private
 */
router.post('/offer', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { requirementId, message, proposedBudget } = req.body;

    if (!requirementId || !message) {
      return res.status(400).json({
        success: false,
        message: 'Requirement ID and message are required'
      });
    }

    // TODO: Save offer to database
    const offer = {
      id: `offer_${Date.now()}`,
      requirementId,
      userId,
      message,
      proposedBudget: proposedBudget || null,
      status: 'pending',
      createdAt: new Date().toISOString()
    };

    logger.info(`Offer made by user ${userId} on requirement ${requirementId}`);

    res.json({
      success: true,
      message: 'Offer submitted successfully',
      data: offer
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/marketplace/categories
 * @desc    Get all marketplace categories
 * @access  Public
 */
router.get('/categories', async (req, res, next) => {
  try {
    const categories = [
      { id: 'plumber', name: 'Plumber', icon: '🔧' },
      { id: 'electrician', name: 'Electrician', icon: '⚡' },
      { id: 'tutor', name: 'Tutor', icon: '📚' },
      { id: 'doctor', name: 'Doctor', icon: '🩺' },
      { id: 'lawyer', name: 'Lawyer', icon: '⚖️' },
      { id: 'designer', name: 'Designer', icon: '🎨' },
      { id: 'programmer', name: 'Programmer', icon: '💻' },
      { id: 'chef', name: 'Chef', icon: '👨‍🍳' },
      { id: 'trainer', name: 'Fitness Trainer', icon: '💪' },
      { id: 'photographer', name: 'Photographer', icon: '📷' },
      { id: 'mechanic', name: 'Mechanic', icon: '🔧' },
      { id: 'cleaner', name: 'Cleaner', icon: '🧹' }
    ];

    res.json({
      success: true,
      data: categories
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/marketplace/stats
 * @desc    Get marketplace statistics
 * @access  Public
 */
router.get('/stats', async (req, res, next) => {
  try {
    // TODO: Fetch real stats from database
    const stats = {
      totalRequirements: 1247,
      activeRequirements: 834,
      fulfilledRequirements: 413,
      totalUsers: 2156,
      averageFulfillmentTime: '2.3 days',
      topCategories: [
        { category: 'tutor', count: 234 },
        { category: 'programmer', count: 189 },
        { category: 'trainer', count: 156 }
      ]
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
});

export default router;
