# Liafon Cloud - Microservices Setup Guide

## 🚀 Quick Start

This guide helps you set up and run all three microservices for the Liafon Cloud ecosystem.

---

## 📋 Prerequisites

- **Python 3.9+** installed
- **Node.js 18+** (for main backend)
- **Ollama** (optional, for AI features)
- **PocketBase** (optional, for database)
- **Redis** (optional, for caching)

---

## 🔧 Service 1: OCR Service (PaddleOCR)

### Installation

```bash
cd backend/services/ocr

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Run Service

```bash
# Basic run (mock mode without PaddleOCR)
python app.py

# Full run with PaddleOCR (requires installation above)
export PORT=5001
python app.py
```

**Endpoint:** `http://localhost:5001`

### Test OCR

```bash
curl -X POST http://localhost:5001/api/ocr/extract \
  -F "image=@test_prescription.jpg" \
  -F "language=en"
```

---

## 🔧 Service 2: Voice Service (Whisper + TTS)

### Installation

```bash
cd backend/services/voice

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

> ⚠️ **Note:** Coqui TTS requires ~2GB disk space for models on first run.

### Run Service

```bash
# Basic run (mock mode)
python app.py

# Full run with Whisper + TTS
export PORT=5002
python app.py
```

**Endpoint:** `http://localhost:5002`

### Test Transcription

```bash
curl -X POST http://localhost:5002/api/voice/transcribe \
  -F "audio=@recording.wav" \
  -F "language=en"
```

### Test Text-to-Speech

```bash
curl -X POST http://localhost:5002/api/voice/synthesize \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, I am your health assistant", "language": "en"}' \
  --output speech.wav
```

---

## 🔧 Service 3: AI Chat Service (Ollama + Llama 3.1)

### Installation

```bash
cd backend/services/ai-chat

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Install Ollama (Required for Real AI)

```bash
# macOS/Linux
curl -fsSL https://ollama.ai/install.sh | sh

# Windows: Download from https://ollama.ai

# Pull Llama 3.1 model
ollama pull llama3.1:8b
```

### Run Service

```bash
# Make sure Ollama is running first
ollama serve

# In another terminal, start the Flask service
export PORT=5000
export OLLAMA_BASE_URL=http://localhost:11434
python app.py
```

**Endpoint:** `http://localhost:5000`

### Test Chat

```bash
curl -X POST http://localhost:5000/api/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "What should I do if my heart rate is high?"}
    ],
    "context": {
      "healthMetrics": {
        "heartRate": 110,
        "steps": 5000
      }
    }
  }'
```

---

## 🔄 Running All Services Together

### Option 1: Manual Terminals

Open 3 separate terminals:

```bash
# Terminal 1 - AI Chat
cd backend/services/ai-chat && source venv/bin/activate && python app.py

# Terminal 2 - OCR
cd backend/services/ocr && source venv/bin/activate && python app.py

# Terminal 3 - Voice
cd backend/services/voice && source venv/bin/activate && python app.py
```

### Option 2: Using tmux/screen

```bash
# Create tmux session
tmux new-session -d -s liafon

# Split windows and run services
tmux send-keys -t liafon "cd backend/services/ai-chat && python app.py" Enter
tmux new-window -t liafon
tmux send-keys -t liafon "cd backend/services/ocr && python app.py" Enter
tmux new-window -t liafon
tmux send-keys -t liafon "cd backend/services/voice && python app.py" Enter

# Attach to session
tmux attach -t liafon
```

---

## ✅ Verify All Services

Run health checks:

```bash
# AI Chat
curl http://localhost:5000/health

# OCR
curl http://localhost:5001/health

# Voice
curl http://localhost:5002/health
```

All should return:
```json
{
  "status": "ok",
  "timestamp": "..."
}
```

---

## 🛠️ Troubleshooting

### OCR Service Issues

**Problem:** PaddleOCR import error  
**Solution:** Install in mock mode first, then add PaddleOCR later
```bash
pip install flask flask-cors  # Skip paddlepaddle initially
```

### Voice Service Issues

**Problem:** Coqui TTS slow or fails  
**Solution:** Use CPU-only mode or skip TTS initially
```bash
# Only install Whisper
pip install faster-whisper flask flask-cors
```

### AI Chat Service Issues

**Problem:** Ollama connection refused  
**Solution:** Ensure Ollama is running
```bash
ollama serve
```

---

## 📊 Architecture Overview

```
┌─────────────────┐
│  Mobile App     │
│   (Flutter)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Main Backend   │
│   (Node.js)     │
│   Port: 3000    │
└────────┬────────┘
         │
    ┌────┴────┬────────────┐
    ▼         ▼            ▼
┌────────┐ ┌────────┐ ┌──────────┐
│   AI   │ │  OCR   │ │  Voice   │
│ :5000  │ │ :5001  │ │  :5002   │
└────────┘ └────────┘ └──────────┘
```

---

## 🎯 Next Steps

1. ✅ Start all three services
2. ✅ Configure main backend `.env` file
3. ✅ Start main Node.js backend
4. ✅ Connect mobile app to backend
5. ✅ Test end-to-end flows

For more details, see the main README.md
