# Liafon Cloud Backend API

Complete open-source backend API for Liafon Cloud smartwatch ecosystem.

## Tech Stack
- **Runtime**: Node.js 20+ with Express.js
- **Database**: PocketBase (self-hosted)
- **Cache**: Redis
- **AI**: Ollama (Llama 3.1)
- **OCR**: PaddleOCR
- **Voice**: Faster-Whisper + Coqui TTS
- **Auth**: JWT + PocketBase Auth
- **Realtime**: WebSocket + Server-Sent Events

## Features
- RESTful API for all app features
- Real-time health data sync
- AI chat endpoint (Ollama integration)
- OCR prescription processing
- Emergency alert system
- Marketplace matching engine
- Points economy ledger
- WhatsApp bot integration
- Voice command processing

## Installation

```bash
npm install
cp .env.example .env
npm run dev
```

## API Endpoints

### Health
- `POST /api/health/sync` - Sync health metrics from watch
- `GET /api/health/metrics` - Get user health metrics
- `GET /api/health/sleep` - Get sleep analysis
- `GET /api/health/stress` - Get stress levels
- `POST /api/health/prescription/scan` - Scan prescription (OCR)

### AI & Voice
- `POST /api/ai/chat` - Chat with AI assistant
- `POST /api/voice/command` - Process voice command
- `POST /api/voice/tts` - Text-to-speech generation

### Emergency
- `POST /api/emergency/trigger` - Trigger emergency alert
- `GET /api/emergency/contacts` - Get emergency contacts
- `PUT /api/emergency/contacts` - Update emergency contacts

### Marketplace
- `GET /api/marketplace/requirements` - Get requirements
- `POST /api/marketplace/requirements` - Post requirement
- `POST /api/marketplace/offer` - Make offer
- `GET /api/marketplace/matches` - Get AI matches

### Points
- `GET /api/points/balance` - Get points balance
- `GET /api/points/history` - Get points history
- `POST /api/points/redeem` - Redeem points

### Users
- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login user
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile

## Environment Variables

See `.env.example` for required variables.

## License
MIT
