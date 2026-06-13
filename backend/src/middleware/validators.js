import { body, param, query, validationResult } from 'express-validator';

// Validation error handler
export const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array()
    });
  }
  next();
};

// Health metric validation
export const validateHealthMetric = [
  body('type').isIn(['heart_rate', 'spo2', 'temperature', 'steps', 'calories', 'sleep', 'stress']).withMessage('Invalid metric type'),
  body('value').isNumeric().withMessage('Value must be a number'),
  body('timestamp').optional().isISO8601().withMessage('Invalid timestamp format'),
  handleValidationErrors
];

// Sleep record validation
export const validateSleepRecord = [
  body('date').isISO8601().withMessage('Invalid date format'),
  body('duration').isFloat({ min: 0 }).withMessage('Duration must be positive'),
  body('quality').isInt({ min: 0, max: 100 }).withMessage('Quality must be between 0-100'),
  body('stages').optional().isObject(),
  handleValidationErrors
];

// Emergency contact validation
export const validateEmergencyContact = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('phone').matches(/^\+?[1-9]\d{1,14}$/).withMessage('Invalid phone number'),
  body('relationship').trim().notEmpty().withMessage('Relationship is required'),
  body('priority').isInt({ min: 1, max: 5 }).withMessage('Priority must be 1-5'),
  handleValidationErrors
];

// Marketplace requirement validation
export const validateRequirement = [
  body('title').trim().isLength({ min: 5, max: 100 }).withMessage('Title must be 5-100 characters'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('budget').isFloat({ min: 0 }).withMessage('Budget must be positive'),
  body('location').trim().notEmpty().withMessage('Location is required'),
  body('description').trim().isLength({ min: 10, max: 1000 }).withMessage('Description must be 10-1000 characters'),
  body('timeline').optional().isString(),
  handleValidationErrors
];

// AI chat validation
export const validateChatRequest = [
  body('messages').isArray({ min: 1 }).withMessage('Messages array is required'),
  body('messages.*.role').isIn(['user', 'assistant', 'system']).withMessage('Invalid role'),
  body('messages.*.content').trim().notEmpty().withMessage('Message content is required'),
  handleValidationErrors
];

// Voice command validation
export const validateVoiceCommand = [
  body('audio').exists().withMessage('Audio data is required'),
  body('language').optional().isString(),
  handleValidationErrors
];

// Prescription scan validation
export const validatePrescriptionScan = [
  body('image').exists().withMessage('Image is required'),
  handleValidationErrors
];

// Points redemption validation
export const validatePointsRedemption = [
  body('amount').isInt({ min: 1 }).withMessage('Amount must be positive'),
  body('reason').trim().notEmpty().withMessage('Reason is required'),
  handleValidationErrors
];

// User profile update validation
export const validateUserProfile = [
  body('name').optional().trim().isLength({ min: 2, max: 50 }),
  body('email').optional().isEmail().normalizeEmail(),
  body('age').optional().isInt({ min: 1, max: 120 }),
  body('gender').optional().isIn(['male', 'female', 'other']),
  body('weight').optional().isFloat({ min: 1, max: 300 }),
  body('height').optional().isFloat({ min: 50, max: 250 }),
  body('blood_group').optional().isIn(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']),
  handleValidationErrors
];

// Authentication validation
export const validateRegister = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('name').trim().notEmpty().withMessage('Name is required'),
  handleValidationErrors
];

export const validateLogin = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required'),
  handleValidationErrors
];

// Pagination validation
export const validatePagination = [
  query('page').optional().isInt({ min: 1 }).toInt(),
  query('perPage').optional().isInt({ min: 1, max: 100 }).toInt(),
  handleValidationErrors
];

// ID parameter validation
export const validateIdParam = [
  param('id').trim().notEmpty().withMessage('ID is required'),
  handleValidationErrors
];
