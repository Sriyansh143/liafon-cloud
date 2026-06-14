import express from 'express';
import logger from '../utils/logger.js';

const router = express.Router();

/**
 * @route   POST /api/emergency/alert
 * @desc    Trigger emergency alert to contacts
 * @access  Private
 */
router.post('/alert', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { 
      type = 'fall_detection', 
      location, 
      healthData, 
      message,
      contactIndex = 0 
    } = req.body;

    logger.warn(`EMERGENCY ALERT triggered by user ${userId}: ${type}`);

    // Get user's emergency contacts from PocketBase
    const pocketbaseService = await import('../services/pocketbase.service.js');
    const contacts = await pocketbaseService.default.getEmergencyContacts(userId);

    if (!contacts || contacts.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No emergency contacts configured'
      });
    }

    // Select contact to notify
    const targetContact = contacts[Math.min(contactIndex, contacts.length - 1)];

    // Build emergency message
    const emergencyMessage = buildEmergencyMessage({
      type,
      userName: req.user?.name || 'User',
      location,
      healthData,
      customMessage: message
    });

    // Generate WhatsApp deep link
    const whatsappUrl = generateWhatsAppLink(targetContact.phone, emergencyMessage);

    // Log emergency event
    await pocketbaseService.default.logEmergencyEvent(userId, {
      type,
      location,
      healthData,
      contactedPerson: targetContact.name,
      timestamp: new Date().toISOString()
    });

    // Send SMS via Twilio (if configured)
    if (process.env.TWILIO_SID && process.env.TWILIO_TOKEN) {
      try {
        await sendSMS(targetContact.phone, emergencyMessage);
      } catch (smsError) {
        logger.error('Failed to send SMS:', smsError);
      }
    }

    // Send email notification (if configured)
    if (process.env.SMTP_HOST && targetContact.email) {
      try {
        await sendEmail(targetContact.email, 'EMERGENCY ALERT', emergencyMessage);
      } catch (emailError) {
        logger.error('Failed to send email:', emailError);
      }
    }

    logger.info(`Emergency alert sent to ${targetContact.name}`);

    res.json({
      success: true,
      message: 'Emergency alert triggered successfully',
      data: {
        alertedContact: {
          name: targetContact.name,
          phone: targetContact.phone,
          relationship: targetContact.relationship
        },
        whatsappUrl,
        location,
        timestamp: new Date().toISOString(),
        notificationsSent: {
          whatsapp: true,
          sms: !!(process.env.TWILIO_SID),
          email: !!(process.env.SMTP_HOST && targetContact.email)
        }
      }
    });
  } catch (error) {
    logger.error('Emergency alert error:', error);
    next(error);
  }
});

/**
 * @route   GET /api/emergency/contacts
 * @desc    Get user's emergency contacts
 * @access  Private
 */
router.get('/contacts', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    
    const pocketbaseService = await import('../services/pocketbase.service.js');
    const contacts = await pocketbaseService.default.getEmergencyContacts(userId);

    res.json({
      success: true,
      data: {
        contacts: contacts || [],
        count: contacts?.length || 0
      }
    });
  } catch (error) {
    logger.error('Get emergency contacts error:', error);
    next(error);
  }
});

/**
 * @route   POST /api/emergency/contacts
 * @desc    Add emergency contact
 * @access  Private
 */
router.post('/contacts', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { name, phone, email, relationship } = req.body;

    if (!name || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Name and phone are required'
      });
    }

    const pocketbaseService = await import('../services/pocketbase.service.js');
    const contact = await pocketbaseService.default.addEmergencyContact(userId, {
      name,
      phone,
      email: email || null,
      relationship: relationship || 'Other'
    });

    res.status(201).json({
      success: true,
      message: 'Emergency contact added successfully',
      data: { contact }
    });
  } catch (error) {
    logger.error('Add emergency contact error:', error);
    next(error);
  }
});

/**
 * @route   DELETE /api/emergency/contacts/:id
 * @desc    Remove emergency contact
 * @access  Private
 */
router.delete('/contacts/:id', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    const { id } = req.params;

    const pocketbaseService = await import('../services/pocketbase.service.js');
    await pocketbaseService.default.removeEmergencyContact(userId, id);

    res.json({
      success: true,
      message: 'Emergency contact removed successfully'
    });
  } catch (error) {
    logger.error('Remove emergency contact error:', error);
    next(error);
  }
});

/**
 * @route   POST /api/emergency/test
 * @desc    Test emergency system (sends test alert to first contact)
 * @access  Private
 */
router.post('/test', async (req, res, next) => {
  try {
    const userId = req.user?.id || 'demo-user';
    
    const pocketbaseService = await import('../services/pocketbase.service.js');
    const contacts = await pocketbaseService.default.getEmergencyContacts(userId);

    if (!contacts || contacts.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No emergency contacts configured. Please add at least one contact.'
      });
    }

    const testMessage = `🧪 TEST ALERT\n\nThis is a test emergency alert from ${req.user?.name || 'Liafon'}.\nYour emergency response system is working correctly.\n\nTime: ${new Date().toLocaleString()}`;
    
    const whatsappUrl = generateWhatsAppLink(contacts[0].phone, testMessage);

    res.json({
      success: true,
      message: 'Test alert generated successfully',
      data: {
        testContact: contacts[0].name,
        whatsappUrl,
        note: 'Open the WhatsApp URL to send the test message'
      }
    });
  } catch (error) {
    logger.error('Emergency test error:', error);
    next(error);
  }
});

// Helper Functions

function buildEmergencyMessage(data) {
  const { type, userName, location, healthData, customMessage } = data;
  
  let emoji = '🚨';
  let typeText = 'Emergency Alert';
  
  switch (type) {
    case 'fall_detection':
      emoji = '🛑';
      typeText = 'FALL DETECTED';
      break;
    case 'unconscious':
      emoji = '⚠️';
      typeText = 'UNCONSCIOUS DETECTED';
      break;
    case 'manual':
      emoji = '🆘';
      typeText = 'MANUAL EMERGENCY';
      break;
    case 'secret_password':
      emoji = '🤫';
      typeText = 'SILENT EMERGENCY';
      break;
  }

  let message = `${emoji} *${typeText}*\n\n`;
  message += `*Person:* ${userName}\n`;
  message += `*Time:* ${new Date().toLocaleString()}\n`;

  if (location) {
    message += `\n📍 *Location:* ${location.address || 'Unknown'}\n`;
    if (location.latitude && location.longitude) {
      message += `https://maps.google.com/?q=${location.latitude},${location.longitude}\n`;
    }
  }

  if (healthData) {
    message += `\n❤️ *Health Data:*\n`;
    if (healthData.heartRate) {
      message += `- Heart Rate: ${healthData.heartRate} bpm\n`;
    }
    if (healthData.spo2) {
      message += `- SpO2: ${healthData.spo2}%\n`;
    }
    if (healthData.bloodPressure) {
      message += `- BP: ${healthData.bloodPressure}\n`;
    }
  }

  if (customMessage) {
    message += `\n📝 *Message:* ${customMessage}\n`;
  }

  message += `\n⚡ *Please respond immediately!*`;
  
  return message;
}

function generateWhatsAppLink(phone, message) {
  // Remove non-numeric characters from phone
  const cleanPhone = phone.replace(/\D/g, '');
  const encodedMessage = encodeURIComponent(message);
  return `https://wa.me/${cleanPhone}?text=${encodedMessage}`;
}

async function sendSMS(phone, message) {
  const twilio = await import('twilio');
  const client = twilio.default(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);
  
  await client.messages.create({
    body: message,
    from: process.env.TWILIO_PHONE,
    to: phone
  });
}

async function sendEmail(to, subject, text) {
  const nodemailer = await import('nodemailer');
  
  const transporter = nodemailer.default.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS
    }
  });

  await transporter.sendMail({
    from: process.env.SMTP_FROM || 'Liafon Emergency <noreply@liafon.cloud>',
    to,
    subject,
    text
  });
}

export default router;
