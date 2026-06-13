import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Import routes
import healthRoutes from './routes/health.routes.js';
import aiRoutes from './routes/ai.routes.js';
import voiceRoutes from './routes/voice.routes.js';
import emergencyRoutes from './routes/emergency.routes.js';
import marketplaceRoutes from './routes/marketplace.routes.js';
import pointsRoutes from './routes/points.routes.js';
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';

// Import services
import pocketbaseService from './services/pocketbase.service.js';
import redisService from './services/redis.service.js';
import ollamaService from './services/ollama.service.js';

// Import middleware
import errorHandler from './middleware/error.middleware.js';
import logger from './utils/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression
app.use(compression());

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined', { stream: logger.stream }));
}

// Static files for uploads
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API Routes
app.use('/api/health', healthRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/voice', voiceRoutes);
app.use('/api/emergency', emergencyRoutes);
app.use('/api/marketplace', marketplaceRoutes);
app.use('/api/points', pointsRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Error handling middleware
app.use(errorHandler);

// Initialize services and start server
const startServer = async () => {
  try {
    // Connect to PocketBase
    await pocketbaseService.connect();
    logger.info('✅ Connected to PocketBase');

    // Connect to Redis
    await redisService.connect();
    logger.info('✅ Connected to Redis');

    // Test Ollama connection
    await ollamaService.testConnection();
    logger.info('✅ Connected to Ollama');

    // Start server
    app.listen(PORT, () => {
      logger.info(`🚀 Liafon Cloud API running on port ${PORT}`);
      logger.info(`📊 Environment: ${process.env.NODE_ENV}`);
      logger.info(`🔗 Health check: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app;
