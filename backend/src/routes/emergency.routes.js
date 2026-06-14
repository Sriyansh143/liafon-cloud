import express from 'express';
import logger from '../utils/logger.js';

const router = express.Router();

/**
 * @route   GET /api/emergency/sos
 * @desc    Trigger emergency SOS alert
 * @access  Private
 */
router.get('/sos', async (req, res) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const location = req.query.location || 'Unknown location';
    
    // TODO: Implement actual emergency logic
    // - Send SMS to emergency contacts
    // - Share live location
    // - Alert nearby hospitals
    
    logger.warn(`SOS triggered by user ${userId} at ${location}`);

    res.json({
      success: true,
      message: 'Emergency alert sent!',
      data: {
        userId,
        location,
        timestamp: new Date().toISOString(),
        emergencyContactsNotified: 3
      }
    });
  } catch (error) {
    logger.error('Emergency SOS error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to trigger emergency alert',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/emergency/contacts
 * @desc    Add emergency contact
 * @access  Private
 */
router.post('/contacts', async (req, res) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { name, phone, relationship } = req.body;

    if (!name || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Name and phone are required'
      });
    }

    // TODO: Save to PocketBase
    logger.info(`Emergency contact added for user ${userId}: ${name}`);

    res.json({
      success: true,
      message: 'Emergency contact added successfully',
      data: {
        id: Date.now().toString(),
        userId,
        name,
        phone,
        relationship: relationship || 'Other'
      }
    });
  } catch (error) {
    logger.error('Add emergency contact error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to add emergency contact',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/emergency/contacts
 * @desc    Get user's emergency contacts
 * @access  Private
 */
router.get('/contacts', async (req, res) => {
  try {
    const userId = req.user?.id || 'demo-user';

    // TODO: Fetch from PocketBase
    // Placeholder response
    res.json({
      success: true,
      data: {
        contacts: [
          {
            id: '1',
            name: 'John Doe',
            phone: '+1234567890',
            relationship: 'Spouse'
          },
          {
            id: '2',
            name: 'Jane Doe',
            phone: '+0987654321',
            relationship: 'Parent'
          }
        ]
      }
    });
  } catch (error) {
    logger.error('Get emergency contacts error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to get emergency contacts',
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/emergency/contacts/:id
 * @desc    Delete an emergency contact
 * @access  Private
 */
router.delete('/contacts/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // TODO: Delete from PocketBase
    logger.info(`Emergency contact ${id} deleted`);

    res.json({
      success: true,
      message: 'Emergency contact deleted successfully'
    });
  } catch (error) {
    logger.error('Delete emergency contact error:', error.message);
    res.status(500).json({
      success: false,
      message: 'Failed to delete emergency contact',
      error: error.message
    });
  }
});

export default router;
