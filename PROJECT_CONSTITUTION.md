# 🏛️ LIAFON CLOUD PROJECT CONSTITUTION

**Version:** 2.0  
**Last Updated:** June 2025  
**Status:** ACTIVE - MANDATORY COMPLIANCE

---

## 📜 PREAMBLE

This document serves as the **supreme governing authority** for all Liafon Cloud repositories. All development, updates, and architectural decisions MUST comply with these principles. AI assistants and human developers are equally bound by these rules.

---

## ⚖️ THE FIVE IMMUTABLE LAWS

### 1️⃣ ZERO-COST & OPEN SOURCE ONLY

**Principle:** No paid APIs, subscriptions, or proprietary tools shall ever be used.

**Rules:**
- ✅ **FOSS Mandate:** All dependencies must be Free and Open Source (MIT, Apache 2.0, GPL, BSD)
- ✅ **Self-Hosted First:** Prefer self-hosted solutions over cloud services
- ✅ **No Vendor Lock-in:** Avoid proprietary formats or protocols
- ✅ **Free Model Priority:** Use Ollama, HuggingFace free models, NVIDIA NIM free tier
- ✅ **Cost Monitoring:** Track and log all API calls to free tiers to avoid unexpected charges

**Approved Stack:**
- **AI/LLM:** Ollama (Llama 3, Phi-3, Mistral), NVIDIA NIM (free tier)
- **OCR:** Tesseract OCR
- **Voice:** Whisper.cpp, Coqui TTS
- **Database:** MongoDB Community Edition, Redis
- **Infrastructure:** Docker, Kubernetes, NGINX

**Emergency Override:**
- NVIDIA NIM free tier may be used ONLY when:
  - Local models fail or are unavailable
  - Response time critical (< 2s required)
  - User explicitly requests high-accuracy mode
- All NVIDIA requests/responses MUST be cached permanently
- Monthly usage limit: 1000 requests per service (configurable)

---

### 2️⃣ THIN CLIENT, HEAVY SERVER

**Principle:** Mobile clients shall remain lightweight; all heavy processing occurs server-side.

**Rules:**
- ✅ **Mobile Memory Limit:** < 50MB RAM usage on client device
- ✅ **Mobile Storage Limit:** < 100MB app size (excluding user data)
- ✅ **Zero Heavy Processing:** No AI inference, OCR, or voice processing on device
- ✅ **Streaming Responses:** Use Server-Sent Events (SSE) for long-running tasks
- ✅ **Compressed Payloads:** All responses compressed (gzip/brotli)
- ✅ **Lazy Loading:** Load resources only when needed

**Server Responsibilities:**
- AI model inference and caching
- Image/video processing
- Voice transcription and synthesis
- Complex business logic
- Data aggregation and analytics

**Mobile Client Responsibilities:**
- UI rendering
- User input capture
- Display server responses
- Offline queue management
- Minimal local storage (user preferences only)

---

### 3️⃣ FEDERATED REPOSITORY ARCHITECTURE

**Principle:** Main repository remains lightweight; specialized sub-repositories handle domain-specific logic.

**Rules:**
- ✅ **Main Repo Size:** < 10MB (excluding node_modules, .git)
- ✅ **Sub-Repo Autonomy:** Each service is independently deployable
- ✅ **Single Responsibility:** One repo = one domain (AI, OCR, Voice, etc.)
- ✅ **API-First Communication:** Services communicate via REST/gRPC only
- ✅ **No Cross-Repo Imports:** Never import code directly between repos
- ✅ **Shared Contracts:** API schemas defined in main repo, implemented in sub-repos

**Repository Structure:**
```
liafon-cloud/           # Main orchestrator (lightweight)
├── backend/            # API Gateway + Auth + Emergency
├── docker-compose.yml  # Service orchestration
└── docs/              # Shared documentation

liafon-ai-chat/        # AI Chat Service (independent)
liafon-ocr/            # OCR Service (independent)
liafon-voice/          # Voice Service (independent)
```

**Domain Rules:**
- Each sub-repo MUST have its own Dockerfile
- Each sub-repo MUST expose health endpoints
- Each sub-repo MUST define memory limits
- Each sub-repo MUST be independently testable

---

### 4️⃣ PERFORMANCE, STABILITY & CRASH PREVENTION

**Principle:** System must remain stable under load; crashes are unacceptable.

**Rules:**
- ✅ **Memory Limits:** Hard caps enforced per service
  - Backend Gateway: 512MB
  - AI Chat Service: 256MB
  - OCR Service: 384MB
  - Voice Service: 256MB
- ✅ **Request Timeouts:** Max 30s for sync, 5min for async
- ✅ **Circuit Breakers:** Auto-disable failing services after 5 errors
- ✅ **Graceful Degradation:** Return cached/stale data if service unavailable
- ✅ **Health Checks:** All services expose `/health` and `/health/detailed`
- ✅ **Auto-Restart:** Failed services restart within 10s
- ✅ **Error Budget:** < 0.1% error rate allowed

**Crash Prevention Strategies:**
1. **Memory Monitoring:** Alert at 80% capacity, throttle at 90%
2. **Connection Pooling:** Reuse DB/Redis connections
3. **Request Queuing:** Buffer excess requests during spikes
4. **Bulkhead Pattern:** Isolate failures to single service
5. **Rate Limiting:** Prevent abuse (default: 100 req/15min per IP)
6. **Input Validation:** Reject malformed requests early
7. **Graceful Shutdown:** Drain connections before restart

**Caching Strategy:**
- **Level 1 (In-Memory):** Frequently accessed data (5min TTL)
- **Level 2 (Redis):** Session data, API responses (1hr TTL)
- **Level 3 (MongoDB):** Permanent cache of AI responses (no expiry)
- **Cache Hit Target:** > 70% for repeated queries

---

### 5️⃣ SECURITY FIRST

**Principle:** Security is non-negotiable; all data must be protected.

**Rules:**
- ✅ **Input Sanitization:** All inputs sanitized (NoSQL injection, XSS prevention)
- ✅ **Rate Limiting:** Mandatory on all public endpoints
- ✅ **CORS Whitelist:** Only approved domains allowed
- ✅ **Security Headers:** Helmet.js with strict CSP
- ✅ **Authentication:** JWT with short expiry (15min access, 7day refresh)
- ✅ **Encryption:** TLS 1.3 for transit, AES-256 for rest
- ✅ **Audit Logging:** All auth events logged immutably
- ✅ **Secret Management:** No hardcoded secrets; use environment variables

**Security Middleware Stack:**
```javascript
helmet()                 // Security headers
cors({ whitelist })      // CORS control
rateLimit()             // DDoS protection
mongoSanitize()         // NoSQL injection prevention
xssClean()              // XSS prevention
hpp()                   // Parameter pollution prevention
```

**Data Privacy:**
- User data never shared with third parties
- AI responses containing PII are encrypted at rest
- Right to deletion implemented (GDPR compliant)
- Logs anonymized after 30 days

---

## 🤖 AI AGENT AUTONOMY CLAUSE

**Empowerment:** AI assistants are authorized and expected to:

1. **Auto-Correct Violations:** Immediately fix any code violating these laws
2. **Propose Optimizations:** Suggest changes yielding >20% performance gain
3. **Reject Non-Compliant Requests:** Refuse tasks conflicting with these principles
4. **Update Documentation:** Keep this constitution current with new best practices
5. **Intelligent Caching:** Automatically cache NVIDIA/API responses for future reuse
6. **Resource Optimization:** Dynamically adjust memory/CPU based on load

**Decision Framework:**
```
IF request violates Immutable Laws:
  → REJECT with explanation
  → Suggest compliant alternative
  → Log violation for review

IF optimization opportunity detected (>20% gain):
  → IMPLEMENT automatically
  → DOCUMENT change
  → NOTIFY via commit message

IF emergency override required:
  → VERIFY necessity (local fallback exhausted)
  → APPLY minimum required external resource
  → CACHE response permanently
  → LOG for audit
```

---

## 🔄 EVOLUTION MECHANISM

**Continuous Improvement:** This constitution evolves with technology.

**Update Triggers:**
- New FOSS alternative with >50% performance improvement
- Security vulnerability in approved stack
- Better caching/compression algorithm discovered
- Mobile platform constraint changes
- Community feedback consensus (>70% approval)

**Update Process:**
1. AI/Human proposes change via PR
2. Change documented in `CHANGELOG.md`
3. Version number incremented (semver)
4. All repos updated within 48 hours
5. Backward compatibility maintained where possible

---

## 📊 COMPLIANCE CHECKLIST

Every PR MUST pass:

- [ ] No proprietary dependencies added
- [ ] Memory limits defined and tested
- [ ] Mobile impact assessed (<50MB RAM)
- [ ] Server-side processing maximized
- [ ] Security middleware present
- [ ] Rate limiting configured
- [ ] Health endpoints implemented
- [ ] Graceful shutdown handlers added
- [ ] Caching strategy documented
- [ ] Error handling comprehensive
- [ ] Docker image optimized (Alpine preferred)
- [ ] Documentation updated

**Automated Enforcement:** CI/CD pipeline will reject non-compliant PRs.

---

## 🆘 EMERGENCY PROTOCOLS

**Scenario 1: Local Model Failure**
1. Attempt fallback model (secondary local)
2. If failed, use NVIDIA NIM free tier
3. Cache response permanently
4. Log incident for model retraining
5. Alert dev team if >5 failures/hour

**Scenario 2: Memory Exhaustion**
1. Trigger garbage collection
2. Shed load (reject non-critical requests)
3. Scale horizontally if auto-scaling enabled
4. Kill non-essential processes
5. Restart with increased limits (temporary)

**Scenario 3: Security Breach**
1. Isolate affected service
2. Rotate all secrets immediately
3. Enable enhanced logging
4. Notify users if PII compromised
5. Post-mortem within 24 hours

---

## 📞 GOVERNANCE

**Final Authority:** Project maintainer (@Sriyansh143) has veto power.

**Dispute Resolution:**
1. Technical discussion in GitHub Issues
2. Community vote if unresolved (48hr window)
3. Maintainer decision is final
4. Decision documented in `GOVERNANCE_LOG.md`

**Enforcement:**
- First violation: Warning + auto-fix
- Second violation: PR rejection
- Third violation: Temporary branch restriction
- Repeated violations: Access revocation

---

## 🎯 SUCCESS METRICS

**Monthly Targets:**
- Mobile RAM usage: < 50MB average
- Server memory efficiency: > 80% utilization
- Cache hit rate: > 70%
- API response time (p95): < 500ms
- Error rate: < 0.1%
- Uptime: > 99.9%
- Zero security incidents
- Zero unexpected costs

**Tracking:** Metrics dashboard updated hourly at `https://metrics.liafon.cloud`

---

## ✨ ACKNOWLEDGMENT

By contributing to Liafon Cloud, you agree to abide by this Constitution. Ignorance is not an excuse. AI agents are bound by these rules as strictly as human developers.

**Remember:** Build fast, stay free, keep it light, secure everything.

---

*This document is living and will evolve. Check for updates before starting any major feature.*

**License:** CC BY-SA 4.0 (Same as all Liafon Cloud projects)
