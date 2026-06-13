import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { validateRegister, validateLogin } from '../middleware/validators.js';
import pocketbaseService from '../services/pocketbase.service.js';
import logger from '../utils/logger.js';

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * @route   POST /api/auth/register
 * @desc    Register new user
 * @access  Public
 */
router.post('/register', validateRegister, async (req, res, next) => {
  try {
    const { email, password, name } = req.body;

    // TODO: Check if user exists in PocketBase
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user in PocketBase
    // For now, simulate user creation
    const user = {
      id: `user_${Date.now()}`,
      email,
      name,
      points: 100, // Welcome bonus
      createdAt: new Date().toISOString()
    };

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    logger.info(`New user registered: ${email}`);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          points: user.points
        },
        token
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', validateLogin, async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // TODO: Fetch user from PocketBase
    // For now, simulate login check
    
    // In production, verify password with bcrypt
    // const isMatch = await bcrypt.compare(password, user.password);
    
    // Simulate successful login
    const user = {
      id: 'demo-user',
      email,
      name: 'Demo User',
      points: 500
    };

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    logger.info(`User logged in: ${email}`);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          points: user.points
        },
        token
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   GET /api/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', async (req, res, next) => {
  try {
    // Extract user from token (middleware would set req.user)
    const userId = req.user?.id || 'demo-user';
    
    // Fetch user from PocketBase
    // For now, return mock data
    const user = {
      id: userId,
      email: 'user@liafon.cloud',
      name: 'Demo User',
      age: 28,
      gender: 'male',
      weight: 70,
      height: 175,
      blood_group: 'O+',
      points: 500,
      healthGoals: ['fitness', 'better-sleep'],
      createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
    };

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/auth/forgot-password
 * @desc    Request password reset
 * @access  Public
 */
router.post('/forgot-password', async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    // TODO: Generate reset token and send email
    // For now, just return success

    logger.info(`Password reset requested for: ${email}`);

    res.json({
      success: true,
      message: 'If an account exists, a reset link has been sent to your email'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset password with token
 * @access  Public
 */
router.post('/reset-password', async (req, res, next) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Token and new password are required'
      });
    }

    // Verify token length
    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters'
      });
    }

    // TODO: Verify reset token and update password
    // For now, just return success

    res.json({
      success: true,
      message: 'Password reset successfully'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/auth/verify-token
 * @desc    Verify JWT token validity
 * @access  Private
 */
router.post('/verify-token', async (req, res, next) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'Token is required'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);

    res.json({
      success: true,
      valid: true,
      data: {
        userId: decoded.userId,
        email: decoded.email,
        expiresAt: decoded.exp
      }
    });
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.json({
        success: true,
        valid: false,
        message: 'Invalid or expired token'
      });
    }
    next(error);
  }
});

export default router;
