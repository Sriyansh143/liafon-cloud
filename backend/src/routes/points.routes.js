import express from 'express';
import { validatePointsRedemption, validatePagination } from '../middleware/validators.js';
import pocketbaseService from '../services/pocketbase.service.js';
import redisService from '../services/redis.service.js';
import logger from '../utils/logger.js';

const router = express.Router();

/**
 * @route   GET /api/points/balance
 * @desc    Get user's points balance
 * @access  Private
 */
router.get('/balance', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';

    // Try cache first
    let balance = await redisService.getCachedPointsBalance(userId);
    
    if (balance === null) {
      balance = await pocketbaseService.getPointsBalance(userId);
      // Cache for 5 minutes
      await redisService.cachePointsBalance(userId, balance, 300);
    }

    res.json({
      success: true,
      data: {
        balance,
        currency: 'Liafon Points (LP)',
        conversionRate: '100 LP = ₹1'
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/points/history
 * @desc    Get user's points transaction history
 * @access  Private
 */
router.get('/history', validatePagination, async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const page = req.query.page || 1;
    const perPage = req.query.perPage || 20;

    // TODO: Fetch from PocketBase
    // For now, return mock data
    const mockTransactions = [
      {
        id: 'txn_1',
        type: 'earn',
        points: 50,
        reason: 'Prescription scan',
        date: new Date(Date.now() - 1000 * 60 * 30).toISOString()
      },
      {
        id: 'txn_2',
        type: 'earn',
        points: 10,
        reason: 'Health check: heart_rate',
        date: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString()
      },
      {
        id: 'txn_3',
        type: 'earn',
        points: 200,
        reason: 'Referral bonus',
        date: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString()
      },
      {
        id: 'txn_4',
        type: 'spend',
        points: -100,
        reason: 'Redeemed for premium features',
        date: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString()
      },
      {
        id: 'txn_5',
        type: 'earn',
        points: 100,
        reason: 'Weekly health goal achieved',
        date: new Date(Date.now() - 1000 * 60 * 60 * 72).toISOString()
      }
    ];

    res.json({
      success: true,
      data: {
        transactions: mockTransactions,
        total: mockTransactions.length,
        page: parseInt(page),
        perPage: parseInt(perPage)
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/points/redeem
 * @desc    Redeem points for rewards
 * @access  Private
 */
router.post('/redeem', validatePointsRedemption, async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { amount, reason } = req.body;

    // Check current balance
    const currentBalance = await pocketbaseService.getPointsBalance(userId);
    
    if (currentBalance < amount) {
      return res.status(400).json({
        success: false,
        message: `Insufficient points. Current balance: ${currentBalance}, Required: ${amount}`
      });
    }

    // Deduct points
    await pocketbaseService.addPoints(userId, amount, reason, 'spend');

    // Invalidate cache
    await redisService.del(`points:${userId}:balance`);

    logger.info(`User ${userId} redeemed ${amount} points for: ${reason}`);

    res.json({
      success: true,
      message: `Successfully redeemed ${amount} points`,
      data: {
        redeemed: amount,
        reason,
        newBalance: currentBalance - amount
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/points/earning-opportunities
 * @desc    Get list of ways to earn points
 * @access  Public
 */
router.get('/earning-opportunities', async (req, res, next) => {
  try {
    const opportunities = [
      {
        action: 'Daily health check',
        points: 10,
        frequency: 'per day',
        description: 'Sync heart rate, steps, or other vitals'
      },
      {
        action: 'Scan prescription',
        points: 50,
        frequency: 'per scan',
        description: 'Use OCR to scan and save prescriptions'
      },
      {
        action: 'Refer a friend',
        points: 200,
        frequency: 'per referral',
        description: 'Invite friends to join Liafon Cloud'
      },
      {
        action: 'Complete weekly health goals',
        points: 100,
        frequency: 'per week',
        description: 'Achieve your weekly fitness targets'
      },
      {
        action: 'Fulfill marketplace requirement',
        points: '100-500',
        frequency: 'per fulfillment',
        description: 'Help someone in the marketplace'
      },
      {
        action: 'Purchase via affiliate deal',
        points: '50-200',
        frequency: 'per purchase',
        description: 'Shop through our partner links'
      },
      {
        action: 'Maintain health streak',
        points: 50,
        frequency: 'per week',
        description: 'Track health metrics for 7 consecutive days'
      },
      {
        action: 'Complete profile',
        points: 100,
        frequency: 'one-time',
        description: 'Fill out all profile information'
      }
    ];

    res.json({
      success: true,
      data: opportunities
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/points/rewards-catalog
 * @desc    Get available rewards to redeem points
 * @access  Public
 */
router.get('/rewards-catalog', async (req, res, next) => {
  try {
    const rewards = [
      {
        id: 'reward_1',
        title: 'Premium Subscription (1 month)',
        points: 1000,
        value: '₹199',
        description: 'Unlock all premium features for 1 month',
        category: 'subscription',
        available: true
      },
      {
        id: 'reward_2',
        title: 'Premium Subscription (1 year)',
        points: 10000,
        value: '₹1,999',
        description: 'Unlock all premium features for 1 year',
        category: 'subscription',
        available: true
      },
      {
        id: 'reward_3',
        title: '₹100 Amazon Gift Card',
        points: 10000,
        value: '₹100',
        description: 'Amazon India gift voucher',
        category: 'gift-card',
        available: true
      },
      {
        id: 'reward_4',
        title: '₹500 Tata 1mg Voucher',
        points: 50000,
        value: '₹500',
        description: 'Discount on medicines and health products',
        category: 'voucher',
        available: true
      },
      {
        id: 'reward_5',
        title: 'Exclusive Watch Face Pack',
        points: 500,
        value: 'Premium',
        description: 'Unlock 10 exclusive watch faces',
        category: 'digital',
        available: true
      },
      {
        id: 'reward_6',
        title: 'Priority Support (1 month)',
        points: 750,
        value: 'Premium',
        description: 'Get priority customer support',
        category: 'service',
        available: true
      },
      {
        id: 'reward_7',
        title: 'Modular Strap Discount (20%)',
        points: 2000,
        value: '20% off',
        description: '20% discount on any modular strap',
        category: 'discount',
        available: true
      }
    ];

    res.json({
      success: true,
      data: {
        rewards,
        categories: ['subscription', 'gift-card', 'voucher', 'digital', 'service', 'discount'],
        conversionInfo: '100 points = ₹1 (for subscriptions)'
      }
    });
  } catch (error) {
    next(error);
  }
});

export default router;
