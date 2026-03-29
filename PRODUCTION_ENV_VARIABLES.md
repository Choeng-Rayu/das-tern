# Production Environment Variables Documentation

**VPS Deployment Guide for Das Tern**  
Domain: `dastern.site` | IP: `167.71.194.68`

---

## Table of Contents

1. [Quick Start Checklist](#quick-start-checklist)
2. [Infrastructure Variables (Shared)](#infrastructure-variables-shared)
3. [Backend Service Variables](#backend-service-variables)
4. [OCR Service Variables](#ocr-service-variables)
5. [AI-LLM Service Variables](#ai-llm-service-variables)
6. [Bakong Payment Service Variables](#bakong-payment-service-variables)
7. [Docker Network Configuration](#docker-network-configuration)
8. [Security Best Practices](#security-best-practices)
9. [Deployment Checklist](#deployment-checklist)

---

## Quick Start Checklist

Before deploying, ensure you have:

- [ ] Generated strong, unique passwords for all services
- [ ] Created a 32-character encryption key
- [ ] Obtained API keys for third-party services (Google OAuth, Telegram, SendGrid, etc.)
- [ ] Configured DNS records for subdomains (api, ocr, ai, payment)
- [ ] Set up SSL certificates (Let's Encrypt via Certbot)
- [ ] Reviewed all URL-encoded passwords for special characters

---

## Infrastructure Variables (Shared)

These variables are used by multiple services in the shared infrastructure layer. They should be defined in `/home/rayu/das-tern/.env` (root level).

### PostgreSQL 17

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `POSTGRES_DB` | Database name | `dastern` | ✅ Yes | Shared by all services |
| `POSTGRES_USER` | Database username | `dastern_user` | ✅ Yes | Shared by all services |
| `POSTGRES_PASSWORD` | Database password | `P@ssw0rd!Strong123` | ✅ Yes | Use strong password with special chars |
| `POSTGRES_PORT` | Port for PostgreSQL | `5432` | Optional | Default: 5432 |
| `DATABASE_URL` | Full connection string | `postgresql://dastern_user:P%40ssw0rd%21Strong123@postgres:5432/dastern?schema=public` | ✅ Yes | **Must URL-encode password** (see notes) |

**⚠️ IMPORTANT:** If your password contains special characters (`@`, `#`, `!`, etc.), you **must** URL-encode them in `DATABASE_URL`:
- `@` → `%40`
- `#` → `%23`
- `!` → `%21`
- `$` → `%24`
- `%` → `%25`

### Redis 7.4

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `REDIS_PASSWORD` | Redis authentication password | `redis_secure_pass_2026` | ✅ Yes | Used for caching and sessions |
| `REDIS_PORT` | Port for Redis | `6379` | Optional | Default: 6379 |
| `REDIS_HOST` | Redis host (in Docker) | `redis` | ✅ Yes | Use Docker service name |
| `REDIS_DB` | Redis database index | `0` | Optional | Default: 0 |
| `REDIS_URL` | Full connection string | `redis://:redis_secure_pass_2026@redis:6379` | Optional | Alternative to individual vars |

### RabbitMQ 4.0

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `RABBITMQ_USER` | RabbitMQ username | `dastern_user` | ✅ Yes | For async job processing |
| `RABBITMQ_PASSWORD` | RabbitMQ password | `rabbitmq_secure_2026` | ✅ Yes | Use strong password |
| `RABBITMQ_PORT` | AMQP port | `5672` | Optional | Default: 5672 |
| `RABBITMQ_MANAGEMENT_PORT` | Management UI port | `15672` | Optional | Default: 15672 |
| `RABBITMQ_URL` | Full connection string | `amqp://dastern_user:rabbitmq_secure_2026@rabbitmq:5672` | Optional | Alternative to individual vars |

### MinIO (S3-compatible Storage)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `MINIO_ROOT_USER` | MinIO admin username | `dastern_admin` | ✅ Yes | S3-compatible object storage |
| `MINIO_ROOT_PASSWORD` | MinIO admin password | `minio_secure_2026` | ✅ Yes | Min 8 characters |
| `MINIO_PORT` | MinIO API port | `9000` | Optional | Default: 9000 |
| `MINIO_CONSOLE_PORT` | MinIO web console port | `9001` | Optional | Default: 9001 |
| `MINIO_ENDPOINT` | MinIO endpoint URL | `http://minio:9000` | ✅ Yes | Use Docker service name internally |
| `MINIO_BUCKET_NAME` | Default bucket name | `dastern-uploads` | ✅ Yes | Created automatically if not exists |

---

## Backend Service Variables

These variables are specific to the NestJS backend service. They should be defined in `/home/rayu/das-tern/backend_nestjs/.env`.

### Server Configuration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `NODE_ENV` | Environment mode | `production` | ✅ Yes | Set to `production` for VPS |
| `PORT` | Backend server port | `3001` | ✅ Yes | Internal port (proxied via Nginx) |
| `HOST` | Bind address | `0.0.0.0` | Optional | Default: 0.0.0.0 |
| `API_PREFIX` | API path prefix | `api/v1` | ✅ Yes | Routes: `/api/v1/*` |

### Database (Backend-specific)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `DATABASE_URL` | Primary DB connection | `postgresql://dastern_user:P%40ssw0rd%21Strong123@postgres:5432/dastern?schema=public` | ✅ Yes | **URL-encode password**, use `postgres` as host |
| `DATABASE_READ_URL` | Read replica connection | `postgresql://dastern_user:P%40ssw0rd%21Strong123@postgres:5432/dastern?schema=public` | Optional | Same as primary for single-server setup |

### Redis (Backend-specific)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `REDIS_HOST` | Redis hostname | `redis` | ✅ Yes | Docker service name |
| `REDIS_PORT` | Redis port | `6379` | ✅ Yes | |
| `REDIS_PASSWORD` | Redis password | `redis_secure_pass_2026` | ✅ Yes | Must match infrastructure Redis password |
| `REDIS_DB` | Database index | `0` | Optional | |

### JWT Authentication

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `JWT_SECRET` | Access token secret | `c8e9f4a6b2d1e5f7a3b4c6d8e9f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9` | ✅ Yes | **Min 32 chars**, use random string |
| `JWT_REFRESH_SECRET` | Refresh token secret | `f9e8d7c6b5a4321098765fedcba9876543210abcdef0123456789abcdef012345` | ✅ Yes | **Min 32 chars**, different from JWT_SECRET |
| `JWT_EXPIRES_IN` | Access token expiry | `15m` | Optional | Default: 15m |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token expiry | `7d` | Optional | Default: 7d |

### Encryption

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `ENCRYPTION_KEY` | Encryption key for sensitive data | `12345678901234567890123456789012` | ✅ Yes | **EXACTLY 32 characters** |

### Google OAuth

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `GOOGLE_CLIENT_ID` | Google OAuth Client ID | `123456789-abcdefg.apps.googleusercontent.com` | ✅ Yes | From Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | Google OAuth Client Secret | `GOCSPX-abcdefghijklmnop` | ✅ Yes | Keep secret |
| `GOOGLE_CALLBACK_URL` | OAuth callback URL | `https://api.dastern.site/api/v1/auth/google/callback` | ✅ Yes | Must match Google Console |

### Telegram Bot OAuth

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `TELEGRAM_BOT_CLIENT_ID` | Telegram bot ID | `8764946066` | ✅ Yes | From @BotFather |
| `TELEGRAM_BOT_CLIENT_SECRET` | Bot secret (if needed) | `your-bot-secret` | Optional | |
| `TELEGRAM_BOT_USERNAME` | Bot username | `dasternbot` | ✅ Yes | Without @ symbol |
| `TELEGRAM_BOT_TOKEN` | Bot API token | `8764946066:AAFhuIq-ohuo69...` | ✅ Yes | From @BotFather |
| `TELEGRAM_APP_REDIRECT_URI` | Mobile app deep link | `dastern://auth/telegram/callback` | Optional | For mobile app |
| `TELEGRAM_OAUTH_REDIRECT_URI` | Web OAuth callback | `https://api.dastern.site/api/v1/auth/telegram/callback` | ✅ Yes | Production callback URL |

### File Storage (S3/MinIO)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `AWS_ACCESS_KEY_ID` | S3/MinIO access key | `dastern_admin` | ✅ Yes | Should match `MINIO_ROOT_USER` |
| `AWS_SECRET_ACCESS_KEY` | S3/MinIO secret key | `minio_secure_2026` | ✅ Yes | Should match `MINIO_ROOT_PASSWORD` |
| `AWS_REGION` | AWS region | `us-east-1` | Optional | Required for AWS S3, optional for MinIO |
| `AWS_S3_BUCKET` | S3 bucket name | `dastern-uploads` | ✅ Yes | Created automatically |
| `AWS_S3_ENDPOINT` | S3 endpoint URL | `http://minio:9000` | ✅ Yes | Use Docker service name `minio` |

### SMS Provider (Twilio)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `TWILIO_ACCOUNT_SID` | Twilio account SID | `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | Optional | For OTP SMS |
| `TWILIO_AUTH_TOKEN` | Twilio auth token | `your_auth_token_here` | Optional | Keep secret |
| `TWILIO_PHONE_NUMBER` | Twilio phone number | `+1234567890` | Optional | Sending number |

### Email (SendGrid)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `SENDGRID_API_KEY` | SendGrid API key | `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | Optional | For transactional emails |
| `SENDGRID_FROM_EMAIL` | Sender email address | `noreply@dastern.com` | Optional | Must be verified in SendGrid |
| `SENDGRID_FROM_NAME` | Sender name | `Das Tern` | Optional | Display name |

### Rate Limiting

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `THROTTLE_TTL` | Rate limit window (seconds) | `60` | Optional | Default: 60 |
| `THROTTLE_LIMIT` | Max requests per window | `100` | Optional | Default: 100 |

### CORS Configuration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `ALLOWED_ORIGINS` | Allowed CORS origins | `https://api.dastern.site,https://dastern.site` | ✅ Yes | Comma-separated list |

### Internal Service URLs

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `OCR_SERVICE_URL` | OCR service endpoint | `http://ocr:8000` | ✅ Yes | Docker service name |
| `AI_SERVICE_URL` | AI-LLM service endpoint | `http://ai-llm:8001` | ✅ Yes | Docker service name |
| `BAKONG_SERVICE_URL` | Bakong payment service | `http://bakong-payment:3002` | ✅ Yes | Docker service name |

### Bakong Integration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `BAKONG_API_KEY` | API key for Bakong service | `changeme_secure_api_key_here` | ✅ Yes | Shared secret between backend and Bakong service |
| `BAKONG_WEBHOOK_SECRET` | Webhook verification secret | `changeme_webhook_secret_here` | ✅ Yes | For webhook signature verification |

### Timezone

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `TZ` | Timezone | `Asia/Phnom_Penh` | ✅ Yes | Cambodia timezone |

---

## OCR Service Variables

These variables are specific to the OCR service. They should be defined in `/home/rayu/das-tern/ocr/.env`.

### Server Configuration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `HOST` | Bind address | `0.0.0.0` | Optional | Default: 0.0.0.0 |
| `PORT` | OCR service port | `8000` | ✅ Yes | Internal port |
| `TZ` | Timezone | `Asia/Phnom_Penh` | Optional | |

### OCR Model Configuration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `OCR_MODEL` | OCR model to use | `kiri-ocr` | ✅ Yes | Options: `tesseract`, `kiri-ocr`, `glm-ocr` |
| `HF_TOKEN` | HuggingFace API token | `hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | ✅ Yes | Required for downloading models |
| `MODEL_CACHE_DIR` | Model cache directory | `./models` | Optional | Default: `~/.cache/huggingface` |

### Kiri-OCR Specific Settings

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `KIRI_MODEL_NAME` | Kiri model name | `mrrtmob/kiri-ocr` | Optional | Default model |
| `KIRI_DEVICE` | Compute device | `cpu` | Optional | Options: `cpu`, `cuda`, `auto` |
| `KIRI_DECODE_METHOD` | Decoding method | `fast` | Optional | Optimization setting |
| `KIRI_MAX_OCR_DIMENSION` | Max image dimension | `2200` | Optional | Pixels |
| `KIRI_PNG_COMPRESS_LEVEL` | PNG compression | `3` | Optional | 0-9 |
| `KIRI_CONF_BLEND_DET` | Confidence blend | `0.25` | Optional | 0.0-1.0 |
| `KIRI_CONF_TEXTLEN_BOOST` | Text length boost | `0.03` | Optional | |

### File Handling

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `MAX_UPLOAD_SIZE_MB` | Max file size (MB) | `10` | Optional | Default: 10 |
| `MAX_IMAGE_DIMENSION` | Max image dimension | `4000` | Optional | Pixels |
| `PREPROCESS_MAX_DIMENSION` | Preprocess max dimension | `3000` | Optional | Pixels |

### OCR Thresholds

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `AUTO_ACCEPT_THRESHOLD` | Auto-accept threshold | `0.80` | Optional | Confidence level |
| `FLAG_REVIEW_THRESHOLD` | Review threshold | `0.60` | Optional | Confidence level |

### Layout Processing

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `ROW_Y_TOLERANCE` | Row Y tolerance | `15` | Optional | Pixels |
| `ROW_Y_TOLERANCE_ADAPTIVE` | Adaptive tolerance | `true` | Optional | Boolean |
| `ROW_Y_TOLERANCE_ADAPTIVE_FACTOR` | Adaptive factor | `0.6` | Optional | 0.0-1.0 |

---

## AI-LLM Service Variables

These variables are specific to the AI-LLM service. They should be defined in `/home/rayu/das-tern/ai-llm-service/.env`.

### Provider Configuration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `LLM_PROVIDER` | LLM provider | `ollama` | ✅ Yes | Options: `ollama`, `openrouter` |

### Ollama (Local) Settings

**Only used when `LLM_PROVIDER=ollama`**

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `OLLAMA_BASE_URL` | Ollama server URL | `http://localhost:11434` | Optional | Local Ollama instance |
| `OLLAMA_MODEL` | Main model | `llama3.2:3b` | Optional | Default model |
| `OLLAMA_FAST_MODEL` | Fast model | `llama3.2:3b` | Optional | For quick responses |
| `OLLAMA_TIMEOUT` | Request timeout (seconds) | `60` | Optional | Default: 60 |

### OpenRouter (API) Settings

**Only used when `LLM_PROVIDER=openrouter`**

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `OPENROUTER_API_KEY` | OpenRouter API key | `sk-or-v1-your_key_here` | ✅ Yes (if using) | From https://openrouter.ai/keys |
| `OPENROUTER_MODEL` | Model to use | `google/gemma-3-4b-it:free` | Optional | Free or paid models |
| `OPENROUTER_TIMEOUT` | Request timeout (seconds) | `60` | Optional | Default: 60 |

### Application Settings

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `LOG_LEVEL` | Logging level | `INFO` | Optional | Options: `DEBUG`, `INFO`, `WARNING`, `ERROR` |
| `LOG_FILE` | Log file path | `/tmp/ai-llm-service.log` | Optional | Optional file logging |
| `DEBUG` | Debug mode | `false` | Optional | Set to `true` for verbose logging |
| `TZ` | Timezone | `Asia/Phnom_Penh` | Optional | |

### Security (Optional)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `API_KEY` | API key for authentication | `your_api_key_here` | Optional | If implementing API key auth |
| `SECRET_KEY` | Secret key | `your_secret_key_here` | Optional | For signing/encryption |

---

## Bakong Payment Service Variables

Bakong Payment runs as a separate Docker Compose stack. Variables should be defined in `/home/rayu/das-tern/bakong_payment/.env`.

### Database (Bakong-specific)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `POSTGRES_USER` | Database username | `postgres` | ✅ Yes | Bakong uses separate DB |
| `POSTGRES_PASSWORD` | Database password | `postgres_bakong_2026` | ✅ Yes | Use strong password |
| `POSTGRES_DB` | Database name | `bakong_payment` | ✅ Yes | Separate database for Bakong |
| `DATABASE_URL` | Full connection string | `postgresql://postgres:postgres_bakong_2026@postgres:5432/bakong_payment?schema=public` | ✅ Yes | Use `postgres` as host (Docker service) |

### Redis (Bakong-specific)

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `REDIS_HOST` | Redis hostname | `redis` | ✅ Yes | Docker service name (Bakong stack) |
| `REDIS_PORT` | Redis port | `6379` | ✅ Yes | |
| `REDIS_PASSWORD` | Redis password | `` | Optional | Leave empty if no auth in Bakong stack |

### Server Configuration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `NODE_ENV` | Environment mode | `production` | ✅ Yes | |
| `PORT` | Service port | `3002` | ✅ Yes | Internal port |

### Bakong API Credentials

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `BAKONG_MERCHANT_ID` | Bakong merchant ID | `your_merchant_id` | ✅ Yes | From Bakong developer portal |
| `BAKONG_PHONE_NUMBER` | Merchant phone number | `+855xxxxxxxx` | ✅ Yes | Registered phone |
| `BAKONG_DEVELOPER_TOKEN` | Bakong API token | `your_developer_token` | ✅ Yes | Keep secret |
| `BAKONG_API_URL` | Bakong API endpoint | `https://api.bakong.gov.kh` | ✅ Yes | Production API URL |

### Merchant Information

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `DEFAULT_MERCHANT_NAME` | Merchant name | `Das Tern` | ✅ Yes | Display name |
| `DEFAULT_MERCHANT_CITY` | Merchant city | `Phnom Penh` | ✅ Yes | Location |

### Pricing Configuration

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `PREMIUM_PRICE` | Premium plan price (USD) | `0.50` | ✅ Yes | Monthly subscription |
| `FAMILY_PREMIUM_PRICE` | Family plan price (USD) | `1.00` | ✅ Yes | Monthly subscription |

### Integration with Backend

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `MAIN_BACKEND_API_KEY` | API key for backend auth | `changeme_secure_api_key_here` | ✅ Yes | Must match backend's `BAKONG_API_KEY` |
| `MAIN_BACKEND_WEBHOOK_URL` | Backend webhook URL | `https://api.dastern.site/api/v1/payments/webhook` | ✅ Yes | Backend callback URL |
| `WEBHOOK_SECRET` | Webhook signature secret | `changeme_webhook_secret_here` | ✅ Yes | Must match backend's `BAKONG_WEBHOOK_SECRET` |

### Encryption

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `ENCRYPTION_KEY` | Encryption key | `12345678901234567890123456789012` | ✅ Yes | **EXACTLY 32 characters** |

### CORS

| Variable | Description | Example Value | Required | Notes |
|----------|-------------|---------------|----------|-------|
| `CORS_ORIGIN` | Allowed origins | `*` | Optional | Use `*` or specific domains |

---

## Docker Network Configuration

### Service Name Resolution

When services run inside Docker Compose, they communicate using **Docker service names** instead of `localhost` or external IPs.

#### Infrastructure Service Names

| Service | Docker Name | Internal URL | External URL (via Nginx) |
|---------|-------------|--------------|--------------------------|
| PostgreSQL | `postgres` | `postgres:5432` | N/A (internal only) |
| Redis | `redis` | `redis:6379` | N/A (internal only) |
| RabbitMQ | `rabbitmq` | `rabbitmq:5672` | N/A (internal only) |
| MinIO | `minio` | `minio:9000` | N/A (internal only) |

#### Application Service Names

| Service | Docker Name | Internal URL | External URL (via Nginx) |
|---------|-------------|--------------|--------------------------|
| Backend | `backend` | `http://backend:3001` | `https://api.dastern.site` |
| OCR | `ocr` | `http://ocr:8000` | `https://ocr.dastern.site` |
| AI-LLM | `ai-llm` | `http://ai-llm:8001` | `https://ai.dastern.site` |
| Bakong Payment | `bakong-payment` | `http://bakong-payment:3002` | `https://payment.dastern.site` |

### Port Binding Strategy

- **Infrastructure services**: No host port binding (internal only)
- **Application services**: Bound to `127.0.0.1` (localhost only)
  - Example: `127.0.0.1:3001:3001` (only accessible from VPS, not externally)
- **Nginx**: Exposes ports 80 and 443 publicly, proxies to internal services

### Connection String Examples

#### ✅ CORRECT (Inside Docker)

```bash
DATABASE_URL="postgresql://user:pass@postgres:5432/dastern"
REDIS_HOST=redis
AWS_S3_ENDPOINT="http://minio:9000"
OCR_SERVICE_URL="http://ocr:8000"
```

#### ❌ INCORRECT (Will not work in production)

```bash
DATABASE_URL="postgresql://user:pass@localhost:5432/dastern"
REDIS_HOST=localhost
AWS_S3_ENDPOINT="http://localhost:9000"
OCR_SERVICE_URL="http://localhost:8000"
```

---

## Security Best Practices

### 🔒 Critical Security Considerations

1. **Never commit `.env` files to version control**
   - Add `.env` to `.gitignore`
   - Use `.env.example` as a template

2. **Use strong, unique passwords**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, special characters
   - Different passwords for each service

3. **Generate secure encryption keys**
   ```bash
   # Generate 32-character encryption key
   openssl rand -hex 16
   
   # Generate JWT secrets (64 characters)
   openssl rand -hex 32
   ```

4. **URL-encode passwords with special characters**
   - Use online URL encoders or:
   ```bash
   python3 -c "import urllib.parse; print(urllib.parse.quote('P@ssw0rd!', safe=''))"
   ```

5. **Protect sensitive API keys**
   - Store in environment variables only
   - Never log or expose in error messages
   - Rotate keys periodically

6. **Use HTTPS for all external communication**
   - Let's Encrypt SSL certificates via Certbot
   - Configure Nginx with SSL

7. **Restrict CORS origins**
   - Only allow your domains in production
   - Never use `*` in production (except for Bakong if needed)

8. **Enable rate limiting**
   - Protect against brute force attacks
   - Configure appropriate limits per endpoint

9. **Regular security updates**
   - Keep Docker images updated
   - Monitor security advisories for dependencies

10. **Backup encryption keys**
    - Store securely offline
    - Document recovery procedures

---

## Deployment Checklist

### Pre-Deployment

- [ ] Clone repository to VPS: `git clone <repo-url> /home/rayu/das-tern`
- [ ] Install Docker and Docker Compose
- [ ] Configure firewall (UFW): Allow 22, 80, 443; Block all other ports
- [ ] Point DNS records to VPS IP (A records for subdomains)

### Environment Setup

#### Root Infrastructure (`.env`)

- [ ] `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- [ ] `REDIS_PASSWORD`
- [ ] `RABBITMQ_USER`, `RABBITMQ_PASSWORD`
- [ ] `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_BUCKET_NAME`

#### Backend Service (`backend_nestjs/.env`)

- [ ] `NODE_ENV=production`, `PORT=3001`
- [ ] `DATABASE_URL` (URL-encoded password, use `postgres` as host)
- [ ] `REDIS_HOST=redis`, `REDIS_PASSWORD`
- [ ] `JWT_SECRET`, `JWT_REFRESH_SECRET` (32+ chars)
- [ ] `ENCRYPTION_KEY` (exactly 32 chars)
- [ ] `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- [ ] `GOOGLE_CALLBACK_URL=https://api.dastern.site/api/v1/auth/google/callback`
- [ ] `TELEGRAM_BOT_TOKEN`, `TELEGRAM_BOT_CLIENT_ID`, `TELEGRAM_BOT_USERNAME`
- [ ] `TELEGRAM_OAUTH_REDIRECT_URI=https://api.dastern.site/api/v1/auth/telegram/callback`
- [ ] `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_S3_BUCKET`
- [ ] `AWS_S3_ENDPOINT=http://minio:9000`
- [ ] `SENDGRID_API_KEY`, `SENDGRID_FROM_EMAIL` (optional)
- [ ] `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` (optional)
- [ ] `ALLOWED_ORIGINS=https://api.dastern.site,https://dastern.site`
- [ ] `OCR_SERVICE_URL=http://ocr:8000`
- [ ] `AI_SERVICE_URL=http://ai-llm:8001`
- [ ] `BAKONG_SERVICE_URL=http://bakong-payment:3002`
- [ ] `BAKONG_API_KEY`, `BAKONG_WEBHOOK_SECRET`
- [ ] `TZ=Asia/Phnom_Penh`

#### OCR Service (`ocr/.env`)

- [ ] `OCR_MODEL=kiri-ocr`
- [ ] `HF_TOKEN` (HuggingFace token)
- [ ] `KIRI_DEVICE=cpu` (or `cuda` if GPU available)
- [ ] `MODEL_CACHE_DIR=./models`
- [ ] `MAX_UPLOAD_SIZE_MB=10`
- [ ] `TZ=Asia/Phnom_Penh`

#### AI-LLM Service (`ai-llm-service/.env`)

- [ ] `LLM_PROVIDER=ollama` or `openrouter`
- [ ] `OLLAMA_BASE_URL=http://localhost:11434` (if using Ollama)
- [ ] `OLLAMA_MODEL=llama3.2:3b` (if using Ollama)
- [ ] `OPENROUTER_API_KEY` (if using OpenRouter)
- [ ] `OPENROUTER_MODEL=google/gemma-3-4b-it:free` (if using OpenRouter)
- [ ] `LOG_LEVEL=INFO`
- [ ] `TZ=Asia/Phnom_Penh`

#### Bakong Payment Service (`bakong_payment/.env`)

- [ ] `NODE_ENV=production`, `PORT=3002`
- [ ] `POSTGRES_USER=postgres`, `POSTGRES_PASSWORD`, `POSTGRES_DB=bakong_payment`
- [ ] `DATABASE_URL` (use `postgres` as host for Bakong stack)
- [ ] `REDIS_HOST=redis`, `REDIS_PORT=6379`, `REDIS_PASSWORD` (if any)
- [ ] `BAKONG_MERCHANT_ID`, `BAKONG_PHONE_NUMBER`
- [ ] `BAKONG_DEVELOPER_TOKEN`, `BAKONG_API_URL`
- [ ] `DEFAULT_MERCHANT_NAME`, `DEFAULT_MERCHANT_CITY`
- [ ] `PREMIUM_PRICE`, `FAMILY_PREMIUM_PRICE`
- [ ] `MAIN_BACKEND_API_KEY` (matches backend's `BAKONG_API_KEY`)
- [ ] `MAIN_BACKEND_WEBHOOK_URL=https://api.dastern.site/api/v1/payments/webhook`
- [ ] `WEBHOOK_SECRET` (matches backend's `BAKONG_WEBHOOK_SECRET`)
- [ ] `ENCRYPTION_KEY` (exactly 32 chars)

### SSL/HTTPS Setup

- [ ] Install Certbot: `sudo apt install certbot python3-certbot-nginx`
- [ ] Obtain SSL certificates:
  ```bash
  sudo certbot --nginx -d api.dastern.site -d ocr.dastern.site -d ai.dastern.site -d payment.dastern.site
  ```
- [ ] Configure auto-renewal: `sudo certbot renew --dry-run`

### Nginx Configuration

- [ ] Configure reverse proxy for all subdomains
- [ ] Set up proxy_pass to internal Docker services
- [ ] Enable SSL and redirect HTTP to HTTPS
- [ ] Configure proper headers (CORS, security headers)
- [ ] Test configuration: `sudo nginx -t`
- [ ] Reload Nginx: `sudo systemctl reload nginx`

### Docker Deployment

- [ ] Build and start main services:
  ```bash
  cd /home/rayu/das-tern
  docker-compose -f docker-compose.prod.yml up -d --build
  ```
- [ ] Build and start Bakong service:
  ```bash
  cd /home/rayu/das-tern/bakong_payment
  docker-compose -f docker-compose.prod.yml up -d --build
  ```
- [ ] Check service health:
  ```bash
  docker ps
  docker logs dastern-backend
  docker logs dastern-ocr
  docker logs dastern-ai-llm
  docker logs bakong_payment_app
  ```

### Database Setup

- [ ] Run Prisma migrations:
  ```bash
  docker exec -it dastern-backend npx prisma migrate deploy
  docker exec -it bakong_payment_app npx prisma migrate deploy
  ```
- [ ] Seed initial data (if needed):
  ```bash
  docker exec -it dastern-backend npx prisma db seed
  ```

### Post-Deployment Testing

- [ ] Test health endpoints:
  - `https://api.dastern.site/api/v1/health`
  - `https://ocr.dastern.site/api/v1/health`
  - `https://ai.dastern.site/`
  - `https://payment.dastern.site/health`
- [ ] Test OAuth flows (Google, Telegram)
- [ ] Test file uploads (MinIO/S3)
- [ ] Test OCR functionality
- [ ] Test AI-LLM responses
- [ ] Test Bakong payment flow
- [ ] Test webhook callbacks
- [ ] Monitor logs for errors

### Monitoring & Maintenance

- [ ] Set up log rotation
- [ ] Configure monitoring (optional: Prometheus, Grafana)
- [ ] Schedule regular backups (database, MinIO data)
- [ ] Document runbook for common issues
- [ ] Set up alerts for service downtime

---

## Quick Reference: Service URLs

### Internal (Docker Network)

```bash
postgres:5432
redis:6379
rabbitmq:5672
minio:9000
backend:3001
ocr:8000
ai-llm:8001
bakong-payment:3002
```

### External (via Nginx)

```bash
https://api.dastern.site       → backend:3001
https://ocr.dastern.site       → ocr:8000
https://ai.dastern.site        → ai-llm:8001
https://payment.dastern.site   → bakong-payment:3002
```

---

## Support & Troubleshooting

### Common Issues

1. **Service won't start**
   - Check logs: `docker logs <container-name>`
   - Verify environment variables are set
   - Ensure database is ready (healthcheck)

2. **Database connection failed**
   - Verify `DATABASE_URL` uses `postgres` (not `localhost`)
   - Check password is URL-encoded
   - Ensure PostgreSQL container is healthy

3. **MinIO connection failed**
   - Verify `AWS_S3_ENDPOINT=http://minio:9000`
   - Check credentials match `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
   - Ensure bucket exists or can be auto-created

4. **OAuth callback errors**
   - Verify callback URLs match exactly in OAuth provider settings
   - Check HTTPS is properly configured
   - Ensure CORS allows your domain

5. **Inter-service communication fails**
   - Verify all services are on `dastern-network`
   - Use Docker service names (not localhost or IP addresses)
   - Check service health endpoints

### Useful Commands

```bash
# View all running containers
docker ps

# View logs
docker logs <container-name>
docker logs -f <container-name>  # Follow logs

# Restart a service
docker-compose -f docker-compose.prod.yml restart <service-name>

# Rebuild a service
docker-compose -f docker-compose.prod.yml up -d --build <service-name>

# Execute command in container
docker exec -it <container-name> bash

# Check network connectivity
docker exec -it dastern-backend ping postgres
docker exec -it dastern-backend curl http://ocr:8000/api/v1/health

# Database backup
docker exec dastern-postgres pg_dump -U dastern_user dastern > backup.sql

# Database restore
docker exec -i dastern-postgres psql -U dastern_user dastern < backup.sql
```

---

**Last Updated:** March 28, 2026  
**Maintainer:** Das Tern DevOps Team  
**Version:** 1.0.0
