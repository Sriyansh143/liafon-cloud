/**
 * Global Error Handling Middleware
 * Handles all errors consistently across the application
 */

import logger from '../utils/logger.js';

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error for debugging
  logger.error('Error:', {
    message: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
    path: req.path,
    method: req.method
  });

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Resource not found';
    error = new AppError(message, 404);
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const message = 'Duplicate field value entered';
    error = new AppError(message, 400);
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message).join(', ');
    error = new AppError(message, 400);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'Invalid token. Please log in again.';
    error = new AppError(message, 401);
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expired. Please log in again.';
    error = new AppError(message, 401);
  }

  // PocketBase errors
  if (err.message?.includes('PocketBase')) {
    const message = 'Database operation failed';
    error = new AppError(message, 500);
  }

  // Redis errors
  if (err.message?.includes('Redis')) {
    const message = 'Cache service unavailable';
    error = new AppError(message, 503);
  }

  // Ollama/AI errors
  if (err.message?.includes('Ollama') || err.message?.includes('AI')) {
    const message = 'AI service temporarily unavailable';
    error = new AppError(message, 503);
  }

  // Default response
  res.status(error.statusCode || 500).json({
    success: false,
    message: error.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && {
      stack: err.stack,
      details: err.details
    })
  });
};

// Async handler wrapper to avoid try-catch blocks
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Authentication middleware
const authMiddleware = (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided, authorization denied'
      });
    }

    const token = authHeader.split(' ')[1];
    
    // TODO: Verify JWT token
    // For now, set demo user
    req.user = { id: 'demo-user', email: 'user@liafon.cloud' };
    
    next();
  } catch (error) {
    next(error);
  }
};

// Rate limit exceeded handler
const rateLimitHandler = (err, req, res, next) => {
  if (err instanceof Error && err.message.includes('Too many requests')) {
    return res.status(429).json({
      success: false,
      message: 'Too many requests, please try again later'
    });
  }
  next(err);
};

// Not found middleware
const notFound = (req, res, next) => {
  const error = new AppError(`Route ${req.originalUrl} not found`, 404);
  next(error);
};

export default errorHandler;
export { AppError, asyncHandler, authMiddleware, rateLimitHandler, notFound };
