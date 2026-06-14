import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import logger from '../utils/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

// Configure multer for voice file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/voice/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25MB limit for audio
  fileFilter: (req, file, cb) => {
    const allowedTypes = /wav|mp3|webm|ogg|m4a/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype) || file.mimetype.startsWith('audio/');
    
    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files (wav, mp3, webm, ogg, m4a) are allowed'));
    }
  }
});

/**
 * @route   POST /api/voice/transcribe
 * @desc    Convert speech to text using Whisper/Faster-Whisper
 * @access  Private
 */
router.post('/transcribe', upload.single('audio'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No audio file provided'
      });
    }

    const audioPath = req.file.path;
    logger.info(`Processing voice transcription for file: ${audioPath}`);

    // Call local Voice microservice
    const voiceServiceUrl = process.env.VOICE_SERVICE_URL || 'http://localhost:5002';
    
    const fs = await import('fs');
    const formData = new FormData();
    const audioBuffer = fs.readFileSync(audioPath);
    const blob = new Blob([audioBuffer], { type: req.file.mimetype });
    
    formData.append('audio', blob, req.file.filename);
    formData.append('language', req.body.language || 'en');
    formData.append('task', req.body.task || 'transcribe'); // transcribe or translate

    const response = await fetch(`${voiceServiceUrl}/api/voice/transcribe`, {
      method: 'POST',
      body: formData
    });

    if (!response.ok) {
      throw new Error(`Voice service returned ${response.status}`);
    }

    const transcriptionResult = await response.json();

    // Clean up uploaded file
    fs.unlinkSync(audioPath);

    logger.info(`Voice transcription completed for user ${req.user?.id || 'demo'}`);

    res.json({
      success: true,
      message: 'Voice transcribed successfully',
      data: {
        text: transcriptionResult.text,
        language: transcriptionResult.language,
        duration: transcriptionResult.duration,
        confidence: transcriptionResult.confidence,
        words: transcriptionResult.words || [],
        processingTime: transcriptionResult.processingTime
      }
    });
  } catch (error) {
    logger.error('Voice transcription error:', error);
    
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
 * @route   POST /api/voice/command
 * @desc    Process voice command and execute action
 * @access  Private
 */
router.post('/command', upload.single('audio'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No audio file provided'
      });
    }

    const audioPath = req.file.path;
    const voiceServiceUrl = process.env.VOICE_SERVICE_URL || 'http://localhost:5002';
    const fs = await import('fs');

    // First transcribe the audio
    const formData = new FormData();
    const audioBuffer = fs.readFileSync(audioPath);
    const blob = new Blob([audioBuffer], { type: req.file.mimetype });
    
    formData.append('audio', blob, req.file.filename);
    formData.append('language', req.body.language || 'en');

    const transcriptionResponse = await fetch(`${voiceServiceUrl}/api/voice/transcribe`, {
      method: 'POST',
      body: formData
    });

    const transcriptionResult = await transcriptionResponse.json();
    const commandText = transcriptionResult.text;

    // Parse and categorize the command
    const parsedCommand = parseVoiceCommand(commandText);

    // Clean up
    fs.unlinkSync(audioPath);

    logger.info(`Voice command processed: ${commandText}`);

    res.json({
      success: true,
      message: 'Voice command processed',
      data: {
        originalText: commandText,
        intent: parsedCommand.intent,
        entities: parsedCommand.entities,
        action: parsedCommand.action,
        parameters: parsedCommand.parameters,
        confidence: transcriptionResult.confidence
      }
    });
  } catch (error) {
    logger.error('Voice command error:', error);
    next(error);
  }
});

/**
 * @route   POST /api/voice/synthesize
 * @desc    Convert text to speech using Coqui TTS
 * @access  Private
 */
router.post('/synthesize', async (req, res, next) => {
  try {
    const { text, language = 'en', speaker = 'default', speed = 1.0 } = req.body;

    if (!text || text.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Text is required'
      });
    }

    const voiceServiceUrl = process.env.VOICE_SERVICE_URL || 'http://localhost:5002';

    const response = await fetch(`${voiceServiceUrl}/api/voice/synthesize`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        text,
        language,
        speaker,
        speed
      })
    });

    if (!response.ok) {
      throw new Error(`Voice service returned ${response.status}`);
    }

    // Return audio as base64 or stream
    const audioBuffer = await response.arrayBuffer();
    const base64Audio = Buffer.from(audioBuffer).toString('base64');

    logger.info(`Voice synthesis completed for user ${req.user?.id || 'demo'}`);

    res.json({
      success: true,
      message: 'Speech synthesized successfully',
      data: {
        audio: base64Audio,
        format: 'wav',
        duration: parseFloat(response.headers.get('x-audio-duration') || '0'),
        textLength: text.length
      }
    });
  } catch (error) {
    logger.error('Voice synthesis error:', error);
    next(error);
  }
});

/**
 * Parse voice command into structured intent
 */
function parseVoiceCommand(text) {
  const lowerText = text.toLowerCase();
  
  const result = {
    intent: 'unknown',
    entities: [],
    action: null,
    parameters: {}
  };

  // Health tracking commands
  if (lowerText.includes('log') || lowerText.includes('record')) {
    if (lowerText.includes('heart rate') || lowerText.includes('pulse')) {
      result.intent = 'log_health_metric';
      result.action = 'record_heart_rate';
      const bpm = lowerText.match(/(\d+)\s*(bpm|beats?)/);
      if (bpm) {
        result.parameters.value = parseInt(bpm[1]);
        result.parameters.type = 'heart_rate';
      }
    } else if (lowerText.includes('weight')) {
      result.intent = 'log_health_metric';
      result.action = 'record_weight';
      const weight = lowerText.match(/(\d+(?:\.\d+)?)\s*(kg|lbs?|pounds?)/);
      if (weight) {
        result.parameters.value = parseFloat(weight[1]);
        result.parameters.unit = weight[2];
        result.parameters.type = 'weight';
      }
    } else if (lowerText.includes('sleep')) {
      result.intent = 'log_sleep';
      result.action = 'record_sleep';
      const hours = lowerText.match(/(\d+(?:\.\d+)?)\s*(hours?|hrs?)/);
      if (hours) {
        result.parameters.duration = parseFloat(hours[1]);
      }
    }
  }

  // Emergency commands
  if (lowerText.includes('emergency') || lowerText.includes('help') || lowerText.includes('sos')) {
    result.intent = 'emergency_alert';
    result.action = 'trigger_emergency';
    result.parameters.urgency = 'high';
  }

  // AI chat commands
  if (lowerText.includes('ask') || lowerText.includes('question') || lowerText.includes('tell me')) {
    result.intent = 'ai_chat';
    result.action = 'send_to_ai';
    result.parameters.query = text;
  }

  // Navigation commands
  if (lowerText.includes('open') || lowerText.includes('go to') || lowerText.includes('show')) {
    result.intent = 'navigation';
    result.action = 'navigate';
    
    if (lowerText.includes('home')) {
      result.parameters.screen = 'home';
    } else if (lowerText.includes('health') || lowerText.includes('dashboard')) {
      result.parameters.screen = 'health_dashboard';
    } else if (lowerText.includes('settings')) {
      result.parameters.screen = 'settings';
    } else if (lowerText.includes('marketplace')) {
      result.parameters.screen = 'marketplace';
    }
  }

  // Reminder commands
  if (lowerText.includes('remind') || lowerText.includes('reminder') || lowerText.includes('alarm')) {
    result.intent = 'set_reminder';
    result.action = 'create_reminder';
    
    // Extract time
    const timeMatch = lowerText.match(/at\s+(\d+(?::\d+)?\s*(?:am|pm)?)/);
    if (timeMatch) {
      result.parameters.time = timeMatch[1];
    }
    
    // Extract reminder text
    const aboutMatch = text.match(/to\s+(.+)/i);
    if (aboutMatch) {
      result.parameters.message = aboutMatch[1];
    }
  }

  // Call commands
  if (lowerText.includes('call') || lowerText.includes('phone')) {
    result.intent = 'make_call';
    result.action = 'initiate_call';
    
    const contactMatch = lowerText.match(/call\s+(.+)/);
    if (contactMatch) {
      result.parameters.contact = contactMatch[1];
    }
  }

  // Message commands
  if (lowerText.includes('message') || lowerText.includes('text') || lowerText.includes('send')) {
    result.intent = 'send_message';
    result.action = 'compose_message';
    
    const toMatch = lowerText.match(/to\s+([^.]+)/);
    if (toMatch) {
      result.parameters.recipient = toMatch[1];
    }
  }

  return result;
}

export default router;
