# Liafon Cloud Microservices

Three isolated Python microservices for AI, OCR, and Voice processing.

## Quick Start

```bash
# Install all services
pip install -r ai-chat/requirements.txt
pip install -r ocr/requirements.txt
pip install -r voice/requirements.txt

# Run services
python ai-chat/app.py &    # Port 5000
python ocr/app.py &        # Port 5001
python voice/app.py &      # Port 5002
```

## Services

| Service | Port | Purpose |
|---------|------|---------|
| AI Chat | 5000 | Health companion (Ollama/Llama 3.1) |
| OCR | 5001 | Prescription scanning (PaddleOCR) |
| Voice | 5002 | Speech-to-text & TTS (Whisper/Coqui) |

## Test Endpoints

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

See main README.md for full documentation.
