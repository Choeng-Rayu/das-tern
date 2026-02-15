# Bakong Payment Integration Service

> Standalone NestJS backend service for Cambodia's Bakong payment system, designed for Das-tern medication management platform subscriptions.

[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-blue)](https://www.typescriptlang.org/)
[![NestJS](https://img.shields.io/badge/NestJS-11-red)](https://nestjs.com/)
[![Prisma](https://img.shields.io/badge/Prisma-Latest-green)](https://www.prisma.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue)](https://www.postgresql.org/)

---

## 🎯 Overview

This service handles all payment operations for Das-tern subscriptions through Cambodia's national Bakong payment system. It runs independently on a separate VPS and communicates with the main Das-tern backend via secure REST APIs.

### Key Features

- ✅ **KHQR Code Generation** - EMV-compliant QR codes for Bakong payments
- ✅ **Real-time Payment Monitoring** - Automatic status checking with configurable intervals
- ✅ **Subscription Management** - Full lifecycle: creation, renewal, upgrades, downgrades
- ✅ **Prorated Billing** - Automatic calculation for plan changes
- ✅ **Security** - API key authentication, rate limiting, IP blocking
- ✅ **Audit Trail** - Complete logging of all operations
- ✅ **Encryption** - AES-256-GCM for sensitive data

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [API Documentation](#api-documentation)
- [Security](#security)
- [Configuration](#configuration)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 17 (via Docker)
- Redis 7 (via Docker)

### Installation

```bash
# Clone the repository
cd /home/rayu/das-tern/bakong_payment

# Install dependencies
npm install

# Start infrastructure (PostgreSQL + Redis)
docker-compose up -d

# Run database migration
npx prisma migrate dev --name init
npx prisma generate

# Start development server
npm run start:dev
```

The service will start on `http://localhost:3002`

### Quick Test

```bash
# Check health
curl http://localhost:3002/api/health

# Run comprehensive tests
./test-api.sh
```

---

## 🏗️ Architecture

### System Components

```
┌─────────────────┐         ┌──────────────────────┐         ┌─────────────────┐
│  Main Backend   │◄───────►│  Bakong Payment      │◄───────►│  Bakong API     │
│  (Das-tern)     │  REST   │  Integration Service │  HTTPS  │  (NBC)          │
└─────────────────┘         └──────────────────────┘         └─────────────────┘
                                     │
                                     ▼
                            ┌──────────────────────┐
                            │  PostgreSQL + Redis  │
                            └──────────────────────┘
```

### Tech Stack

- **Framework**: NestJS 11
- **Language**: TypeScript 5.7
- **Database**: PostgreSQL 17
- **Cache**: Redis 7
- **ORM**: Prisma
- **Logger**: Winston
- **QR Generation**: qrcode-generator
- **Encryption**: AES-256-GCM

---

## 📚 API Documentation

### Authentication

All API endpoints (except health checks) require API key authentication:

```bash
Authorization: Bearer <API_KEY>
```

### Endpoints

#### Payment Endpoints

##### Create Payment
**POST** `/api/payments/create`

Creates a new payment and generates KHQR code.

**Request Body:**
```json
{
  "userId": "string",
  "planType": "PREMIUM" | "FAMILY_PREMIUM",
  "amount": 0.50,
  "currency": "USD" | "KHR",
  "callback": "https://app.dastern.com/payment/success",
  "appName": "Das Tern"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transactionId": "uuid",
    "billNumber": "DT-1234567890-ABCD",
    "md5Hash": "32-char-hash",
    "qrCode": "KHQR-string",
    "qrImagePath": "/qr-codes/hash.png",
    "deepLink": "bakong://qr?qr=...",
    "amount": 0.50,
    "currency": "USD",
    "status": "PENDING",
    "createdAt": "2026-02-11T09:00:00Z"
  }
}
```

##### Check Payment Status
**GET** `/api/payments/status/:md5`

Checks current payment status by MD5 hash.

**Response:**
```json
{
  "success": true,
  "data": {
    "transactionId": "uuid",
    "md5Hash": "32-char-hash",
    "status": "PENDING" | "PAID" | "FAILED" | "TIMEOUT" | "EXPIRED",
    "amount": 0.50,
    "currency": "USD",
    "paidAt": "2026-02-11T09:05:00Z",
    "createdAt": "2026-02-11T09:00:00Z",
    "updatedAt": "2026-02-11T09:05:00Z"
  }
}
```

##### Monitor Payment
**POST** `/api/payments/monitor`

Monitors payment until completion or timeout.

**Request Body:**
```json
{
  "transactionId": "uuid",
  "options": {
    "timeout": 300000,    // 5 minutes
    "interval": 5000,     // 5 seconds
    "maxAttempts": 60,
    "priority": "high"
  }
}
```

##### Bulk Check Payments
**POST** `/api/payments/bulk-check`

Checks multiple payments at once (max 50).

**Request Body:**
```json
{
  "md5Hashes": ["hash1", "hash2", "..."]
}
```

##### Payment History
**GET** `/api/payments/history?userId=xxx&limit=10&offset=0`

Gets payment history for a user.

---

#### Subscription Endpoints

##### Get Subscription Status
**GET** `/api/subscriptions/status/:userId`

Gets current subscription for a user.

**Response:**
```json
{
  "success": true,
  "data": {
    "hasSubscription": true,
    "subscription": {
      "id": "uuid",
      "userId": "user-123",
      "planType": "PREMIUM",
      "status": "ACTIVE",
      "startDate": "2026-02-11T00:00:00Z",
      "nextBillingDate": "2026-03-13T00:00:00Z",
      "lastBillingDate": "2026-02-11T00:00:00Z",
      "createdAt": "2026-02-11T00:00:00Z"
    },
    "recentPayments": [...]
  }
}
```

##### Upgrade Subscription
**POST** `/api/subscriptions/upgrade`

Upgrades from PREMIUM to FAMILY_PREMIUM with prorated payment.

**Request Body:**
```json
{
  "userId": "user-123",
  "callback": "https://app.dastern.com/upgrade/success"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "requiresPayment": true,
    "proratedAmount": 0.25,
    "payment": {
      "transactionId": "uuid",
      "qrCode": "...",
      "deepLink": "bakong://..."
    },
    "message": "Complete payment to upgrade to FAMILY_PREMIUM"
  }
}
```

##### Downgrade Subscription
**POST** `/api/subscriptions/downgrade`

Schedules downgrade to PREMIUM at next billing cycle.

**Request Body:**
```json
{
  "userId": "user-123"
}
```

##### Cancel Subscription
**POST** `/api/subscriptions/cancel`

Cancels active subscription.

**Request Body:**
```json
{
  "userId": "user-123",
  "reason": "User requested cancellation"
}
```

##### Renew Subscription
**POST** `/api/subscriptions/renew`

Manually triggers renewal (usually called after payment).

**Request Body:**
```json
{
  "userId": "user-123"
}
```

---

#### Health Endpoints

##### Health Check
**GET** `/api/health`

Complete health check of all services.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-11T09:00:00Z",
  "services": {
    "database": { "status": "healthy", "message": "Connected to PostgreSQL" },
    "redis": { "status": "healthy", "message": "Connected to Redis" },
    "bakong": { "status": "degraded", "message": "May require Cambodia IP" }
  }
}
```

##### Readiness Probe
**GET** `/api/health/ready`

Checks if service is ready to accept requests.

##### Liveness Probe
**GET** `/api/health/live`

Checks if service is running.

---

## 🔒 Security

### Implemented Security Features

1. **API Key Authentication**
   - Bearer token format
   - Redis caching
   - IP blocking after 10 failed attempts in 5 minutes

2. **Rate Limiting**
   - 100 requests/minute per API key/IP
   - Distributed via Redis
   - Proper HTTP 429 responses

3. **Data Encryption**
   - AES-256-GCM for sensitive data
   - PBKDF2 key derivation (100k iterations)
   - HMAC-SHA256 signatures

4. **Input Validation**
   - Required field validation
   - Type checking
   - SQL injection protection (Prisma)
   - Array size limits

5. **Audit Logging**
   - All operations logged
   - Separate security log file
   - Failed authentication tracking

### Security Testing

Run security tests:
```bash
./test-api.sh
```

See [SECURITY_ASSESSMENT.md](./SECURITY_ASSESSMENT.md) for detailed security analysis.

---

## ⚙️ Configuration

### Environment Variables

Copy and update `.env`:

```bash
# Database
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/bakong_payment"

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Bakong Credentials
BAKONG_MERCHANT_ID=your_merchant_id
BAKONG_PHONE_NUMBER=855xxxxxxxxx
BAKONG_DEVELOPER_TOKEN=your_token

# Security
MAIN_BACKEND_API_KEY=your_secure_api_key
WEBHOOK_SECRET=your_webhook_secret
ENCRYPTION_KEY=32_character_encryption_key

# Pricing
PREMIUM_PRICE=0.50
FAMILY_PREMIUM_PRICE=1.00

# Server
PORT=3002
NODE_ENV=development
```

---

## 💻 Development

### Project Structure

```
src/
├── controllers/        # API endpoints
├── services/          # Business logic
├── middleware/        # Auth & rate limiting
├── bakong/           # KHQR & Bakong API
├── utils/            # Utilities (logger, encryption, retry)
├── types/            # TypeScript types
├── prisma/           # Database service
└── main.ts           # Application entry
```

### Database Migrations

```bash
# Create migration
npx prisma migrate dev --name description

# Generate client
npx prisma generate

# Reset database
npx prisma migrate reset
```

### Logging

Logs are stored in `logs/`:
- `combined.log` - All logs
- `error.log` - Errors only
- `security.log` - Security events

---

## 🧪 Testing

### Run API Tests

```bash
chmod +x test-api.sh
./test-api.sh
```

### Manual Testing

```bash
# Create payment
curl -X POST http://localhost:3002/api/payments/create \
  -H "Authorization: Bearer your_api_key" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "planType": "PREMIUM",
    "amount": 0.50,
    "currency": "USD"
  }'
```

---

## 🚀 Deployment

### Production Checklist

- [ ] Enable HTTPS/TLS
- [ ] Update API keys with strong random values
- [ ] Configure CORS restrictions
- [ ] Set up log aggregation
- [ ] Configure monitoring/alerts
- [ ] Set strong database password
- [ ] Enable Redis password
- [ ] Review security settings

### Docker Deployment

```bash
# Build image
docker build -t bakong-payment:latest .

# Run container
docker run -d \
  -p 3002:3002 \
  --env-file .env \
  --name bakong-payment \
  bakong-payment:latest
```

---

## 📖 Documentation

- [Implementation Report](./IMPLEMENTATION_REPORT.md) - Complete feature list
- [Security Assessment](./SECURITY_ASSESSMENT.md) - Security analysis
- [Implementation Progress](./IMPLEMENTATION_PROGRESS.md) - Task tracking
- [Design Document](../docs/bakong-payment-service/design.md) - System design
- [Requirements](../docs/bakong-payment-service/requirements.md) - Specifications

---

## 📝 License

Private - Das-tern Medication Management Platform

---

## 🤝 Support

For issues or questions:
1. Check logs in `logs/` directory
2. Review error responses
3. Check security logs for auth issues
4. Verify environment configuration

---

## 📊 Status

**Implementation**: 95% Complete  
**Security**: Production-ready with hardening recommendations  
**Testing**: Comprehensive test suite included  
**Documentation**: Complete

Ready for deployment after applying production security measures!
