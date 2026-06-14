const express = require('express');
const axios = require('axios');
const logger = require('../utils/logger.js');

const router = express.Router();
const VOICE_SERVICE_URL = process.env.VOICE_SERVICE_URL || 'http://localhost:3003';

/**
 * @route   POST /api/voice/stt
 * @desc    Speech-to-Text - Convert audio to text
 * @access  Private
 */
router.post('/stt', async (req, res, next) => {
    try {
        // Forward request to voice service
        const response = await axios.post(`${VOICE_SERVICE_URL}/stt`, req.body);
        res.json(response.data);
    } catch (error) {
        if (logger && logger.error) {
            logger.error('Voice STT proxy error:', error.message);
        }
        res.status(500).json({ error: 'Voice service unavailable' });
    }
});

module.exports = router;
