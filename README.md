# Liafon Cloud

Zero-cost healthcare ecosystem with AI companion, emergency alerts, and marketplace.

## Architecture

```
┌──────────────────┐     ┌─────────────┐
│  Flutter Mobile  │────▶│ Node.js API │
│   (BLE/AI/OCR)   │     │  (Port 3000)│
└──────────────────┘     └──────┬──────┘
                                │
          ┌─────────────┬───────┼───────┬─────────────┐
          ▼             ▼       ▼       ▼             ▼
     ┌────────┐   ┌────────┐ ┌──────┐ ┌────────┐ ┌──────────┐
     │PocketBase│  │ Redis  │ │ Ollama│ │  OCR   │ │  Voice   │
     │  :8090  │  │ :6379  │ │:11434│ │ :5001  │ │ :5002    │
     └────────┘   └────────┘ └──────┘ └────────┘ └──────────┘
```

## Features

### ✅ Implemented
- **Health Tracking**: Heart rate, SpO2, steps, sleep, stress via BLE
- **AI Companion**: Ollama + Llama 3.1 for health insights
- **Emergency System**: Fall detection, WhatsApp/SMS alerts with GPS
- **OCR Scanning**: PaddleOCR for prescription reading
- **Voice Commands**: Whisper STT + Coqui TTS
- **Marketplace**: Service matching with points economy
- **Edge AI**: TFLite models for on-device inference

## Quick Start

### Backend

```bash
cd backend
npm install

# Start microservices (separate terminals)
python services/ai-chat/app.py &    # Port 5000
python services/ocr/app.py &        # Port 5001
python services/voice/app.py &      # Port 5002

# Start main API
npm start                           # Port 3000
```

### Mobile (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Environment Setup

Create `backend/.env`:

```env
PORT=3000
NODE_ENV=development
POCKETBASE_URL=http://localhost:8090
REDIS_URL=redis://localhost:6379
OLLAMA_BASE_URL=http://localhost:11434
AI_SERVICE_URL=http://localhost:5000
OCR_SERVICE_URL=http://localhost:5001
VOICE_SERVICE_URL=http://localhost:5002
```

## API Endpoints

| Route | Description |
|-------|-------------|
| POST `/api/auth/register` | User registration |
| POST `/api/auth/login` | User login |
| GET `/api/health/metrics` | Get health data |
| POST `/api/health/sync` | Sync from watch |
| POST `/api/ai/chat` | Chat with AI |
| POST `/api/ocr/scan` | Scan prescription |
| POST `/api/voice/transcribe` | Speech to text |
| POST `/api/emergency/alert` | Trigger emergency |
| GET `/api/marketplace/listings` | Browse services |
| GET `/api/points/balance` | Check points |

## Testing

```bash
# Health check
curl http://localhost:3000/health

# AI Chat
curl -X POST http://localhost:3000/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"How is my health?"}'

# OCR Scan
curl -X POST http://localhost:3000/api/ocr/scan \
  -F "image=@prescription.jpg"

# Emergency Alert
curl -X POST http://localhost:3000/api/emergency/alert \
  -H "Content-Type: application/json" \
  -d '{"type":"fall_detection","location":{"lat":12.97,"lng":77.59}}'
```

## Project Structure

```
liafon-cloud/
├── backend/
│   ├── src/
│   │   ├── routes/         # API route handlers
│   │   ├── services/       # Business logic
│   │   ├── middleware/     # Request processing
│   │   └── index.js        # Entry point
│   └── services/
│       ├── ai-chat/        # Flask + Ollama
│       ├── ocr/            # Flask + PaddleOCR
│       └── voice/          # Flask + Whisper/TTS
└── apps/mobile/
    └── lib/
        ├── screens/        # UI pages
        ├── providers/      # State management
        ├── services/       # API clients
        └── models/         # Data classes
```

## Requirements

- Node.js 18+
- Python 3.9+
- Flutter 3.x
- PocketBase (optional)
- Redis (optional)
- Ollama (optional, for real AI)


## Microservices Detail

Three isolated Python microservices for heavy ML/AI processing:

| Service | Port | Purpose | Dependencies |
|---------|------|---------|--------------|
| **AI Chat** | 5000 | Health companion with memory | Ollama, Llama 3.1 |
| **OCR** | 5001 | Prescription scanning | PaddleOCR |
| **Voice** | 5002 | Speech-to-text & TTS | Whisper, Coqui TTS |

### Microservices Quick Start

```bash
# Install dependencies
pip install -r backend/services/ai-chat/requirements.txt
pip install -r backend/services/ocr/requirements.txt
pip install -r backend/services/voice/requirements.txt

# Run services (separate terminals)
python backend/services/ai-chat/app.py &    # Port 5000
python backend/services/ocr/app.py &        # Port 5001
python backend/services/voice/app.py &      # Port 5002
```

### Test Microservices Directly

```bash
# AI Chat
curl -X POST http://localhost:5000/api/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello!"}]}'

# OCR
curl -X POST http://localhost:5001/api/ocr/extract \
  -F "image=@test.jpg"

# Voice Transcribe
curl -X POST http://localhost:5002/api/voice/transcribe \
  -F "audio=@test.wav"

# Voice Synthesize
curl -X POST http://localhost:5002/api/voice/synthesize \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello"}' --output out.wav
```

## License

MIT
