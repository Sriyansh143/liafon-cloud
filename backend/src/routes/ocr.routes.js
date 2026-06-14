import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import logger from '../utils/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/ocr/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error('Only image files (jpeg, jpg, png, webp) are allowed'));
    }
  }
});

/**
 * @route   POST /api/ocr/scan
 * @desc    Scan prescription/medical document using PaddleOCR
 * @access  Private
 */
router.post('/scan', upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    const imagePath = req.file.path;
    logger.info(`Processing OCR for file: ${imagePath}`);

    // Call local PaddleOCR microservice
    const ocrServiceUrl = process.env.OCR_SERVICE_URL || 'http://localhost:5001';
    
    const formData = new FormData();
    const fs = await import('fs');
    const imageBuffer = fs.readFileSync(imagePath);
    const blob = new Blob([imageBuffer], { type: req.file.mimetype });
    formData.append('image', blob, req.file.filename);
    formData.append('language', req.body.language || 'en');

    const response = await fetch(`${ocrServiceUrl}/api/ocr/extract`, {
      method: 'POST',
      body: formData
    });

    if (!response.ok) {
      throw new Error(`OCR service returned ${response.status}`);
    }

    const ocrResult = await response.json();

    // Clean up uploaded file
    fs.unlinkSync(imagePath);

    // Parse medical information from OCR result
    const parsedData = parseMedicalInformation(ocrResult.text);

    logger.info(`OCR completed successfully for user ${req.user?.id || 'demo'}`);

    res.json({
      success: true,
      message: 'Prescription scanned successfully',
      data: {
        rawText: ocrResult.text,
        confidence: ocrResult.confidence,
        parsed: parsedData,
        processingTime: ocrResult.processingTime
      }
    });
  } catch (error) {
    logger.error('OCR scan error:', error);
    
    // Clean up file on error
    if (req.file) {
      const fs = await import('fs');
      try {
        fs.unlinkSync(req.file.path);
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    
    next(error);
  }
});

/**
 * @route   POST /api/ocr/extract-text
 * @desc    Extract text from any image
 * @access  Private
 */
router.post('/extract-text', upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    const ocrServiceUrl = process.env.OCR_SERVICE_URL || 'http://localhost:5001';
    const fs = await import('fs');
    
    const imageBuffer = fs.readFileSync(req.file.path);
    const blob = new Blob([imageBuffer], { type: req.file.mimetype });
    
    const formData = new FormData();
    formData.append('image', blob, req.file.filename);
    formData.append('language', req.body.language || 'en');

    const response = await fetch(`${ocrServiceUrl}/api/ocr/extract`, {
      method: 'POST',
      body: formData
    });

    const ocrResult = await response.json();
    
    // Clean up
    fs.unlinkSync(req.file.path);

    res.json({
      success: true,
      data: {
        text: ocrResult.text,
        confidence: ocrResult.confidence,
        lines: ocrResult.lines || []
      }
    });
  } catch (error) {
    logger.error('Text extraction error:', error);
    next(error);
  }
});

/**
 * Parse medical information from OCR text
 * Extracts medicine names, dosages, frequency, etc.
 */
function parseMedicalInformation(text) {
  const result = {
    medicines: [],
    dosages: [],
    frequencies: [],
    instructions: [],
    doctorName: null,
    hospitalName: null,
    date: null
  };

  const lines = text.split('\n').filter(line => line.trim().length > 0);

  // Common medicine patterns
  const medicinePattern = /\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+(?:Tablet|Capsule|Syrup|Injection|Drops|Ointment)/gi;
  const dosagePattern = /(\d+(?:\.\d+)?)\s*(mg|ml|g|mcg|units)/gi;
  const frequencyPattern = /\b(once|twice|thrice|daily|morning|night|before\s+meal|after\s+meal|every\s+\d+\s+hours)\b/gi;

  lines.forEach(line => {
    // Extract medicines
    const medicineMatches = line.match(medicinePattern);
    if (medicineMatches) {
      result.medicines.push(...medicineMatches);
    }

    // Extract dosages
    const dosageMatches = line.match(dosagePattern);
    if (dosageMatches) {
      result.dosages.push(...dosageMatches);
    }

    // Extract frequencies
    const frequencyMatches = line.match(frequencyPattern);
    if (frequencyMatches) {
      result.frequencies.push(...frequencyMatches);
    }

    // Check for doctor/hospital
    if (/dr\.?\s+[a-z]+/i.test(line)) {
      result.doctorName = line.match(/dr\.?\s+[a-z\s]+/i)?.[0] || null;
    }
    
    if (/hospital|clinic|medical center/i.test(line)) {
      result.hospitalName = line.trim();
    }
  });

  // Remove duplicates
  result.medicines = [...new Set(result.medicines)];
  result.dosages = [...new Set(result.dosages)];
  result.frequencies = [...new Set(result.frequencies)];

  return result;
}

export default router;
