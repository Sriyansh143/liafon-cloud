# Liafon Cloud Microservices Setup Guide

## Overview

Liafon Cloud now uses a modular microservices architecture with three specialized services:

| Service | Port | Technology | Purpose |
|---------|------|------------|---------|
| AI Chat | 3001 | Ollama | Conversational AI |
| OCR | 3002 | Tesseract.js | Text extraction from images |
| Voice | 3003 | Whisper.cpp | Speech-to-text transcription |

## Quick Start

### 1. Clone Submodules

```bash
cd /workspace
git submodule update --init --recursive
```

### 2. Install Dependencies

```bash
# AI Chat Service
cd backend/services/ai-chat
npm install

# OCR Service
cd backend/services/ocr
npm install

# Voice Service
cd backend/services/voice
npm install
```

### 3. Configure Environment

Each service has its own `.env.example` file. Copy and configure:

```bash
cd backend/services/ai-chat
cp .env.example .env

cd ../ocr
cp .env.example .env

cd ../voice
cp .env.example .env
```

### 4. Start Services

```bash
# In separate terminals or using a process manager

# AI Chat (requires Ollama running)
cd backend/services/ai-chat && npm run dev

# OCR (standalone)
cd backend/services/ocr && npm run dev

# Voice (requires Whisper.cpp installed)
cd backend/services/voice && npm run dev
```

## Infrastructure Requirements

### Ollama (for AI Chat)

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a space-efficient model (GGUF quantized)
ollama pull llama3.1:8b-instruct-q4_0

# Or smaller models:
ollama pull phi3:mini      # 2GB, fast
ollama pull gemma2:2b      # 1.5GB, very fast

# Start Ollama server
ollama serve
```

### Whisper.cpp (for Voice)

```bash
# macOS
brew install whisper.cpp

# Linux
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
make
sudo cp main /usr/local/bin/whisper-cli

# Download GGUF models (space efficient!)
cd /opt/whisper/models
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

### Tesseract (for OCR - optional, Tesseract.js bundles it)

Tesseract.js includes its own Tesseract engine, no system installation needed!

## Disk Space Optimization

### Using Quantized GGUF Models

**Ollama Models (AI Chat):**
- `phi3:mini` - 2GB (recommended for low space)
- `gemma2:2b` - 1.5GB (smallest good quality)
- `llama3.1:8b-q4_0` - 5GB (balanced)
- `llama3.1:8b` - 16GB (full precision, avoid if space constrained)

**Whisper Models (Voice):**
- `ggml-tiny.en.bin` - 75MB
- `ggml-base.en.bin` - 142MB (recommended)
- `ggml-small.en.bin` - 466MB
- `ggml-medium.en.bin` - 1.5GB
- `ggml-large-v3.bin` - 3.1GB

### Total Storage Requirements

**Minimal Setup:** ~3GB
- phi3:mini (2GB) + ggml-base.en (142MB) + Node modules (~500MB)

**Recommended Setup:** ~7GB
- llama3.1:8b-q4_0 (5GB) + ggml-small.en (466MB) + Node modules (~500MB)

## API Endpoints Summary

### AI Chat Service (port 3001)
- `POST /chat` - Chat with AI assistant
- `GET /health` - Health check

### OCR Service (port 3002)
- `POST /extract` - Extract text from image
- `POST /extract-prescription` - Prescription-specific extraction
- `GET /health` - Health check

### Voice Service (port 3003)
- `POST /transcribe` - Speech to text
- `POST /translate` - Translate audio to English
- `GET /models` - List available models
- `GET /health` - Health check

## Main Backend Integration

The main backend (`/workspace/backend`) integrates with these services:

```javascript
// Example: Call AI Chat service
const aiResponse = await axios.post('http://localhost:3001/chat', {
  messages: [{ role: 'user', content: 'Hello!' }]
});

// Example: Call OCR service
const ocrResult = await axios.post('http://localhost:3002/extract', formData, {
  headers: { 'Content-Type': 'multipart/form-data' }
});

// Example: Call Voice service
const transcription = await axios.post('http://localhost:3003/transcribe', formData, {
  headers: { 'Content-Type': 'multipart/form-data' }
});
```

## Troubleshooting

### Service won't start
- Check if port is already in use: `lsof -i :3001`
- Verify dependencies: `npm install`
- Check environment variables in `.env`

### Ollama connection failed
- Ensure Ollama is running: `ollama serve`
- Check model is downloaded: `ollama list`
- Verify URL in `.env`: `OLLAMA_BASE_URL=http://localhost:11434`

### Whisper transcription fails
- Verify whisper-cli path: `which whisper-cli`
- Check model exists: `ls /opt/whisper/models/*.bin`
- Test manually: `whisper-cli -m model.bin -f audio.wav`

## License

MIT - All services are open source
