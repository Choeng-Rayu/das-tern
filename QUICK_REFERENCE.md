# Das-Tern Backend - Quick Reference Guide

## Directory Structure Quick Map

```
/backend_nestjs
├── src/
│   ├── main.ts                    # Application entry point
│   ├── app.module.ts              # Root module (imports all services)
│   ├── app.controller.ts          # Root endpoint
│   ├── common/
│   │   ├── decorators/            # @CurrentUser, @Roles
│   │   └── guards/                # RolesGuard
│   ├── database/
│   │   ├── database.module.ts     # Prisma setup
│   │   └── prisma.service.ts      # Database connection
│   └── modules/                   # Feature modules
│       ├── auth/                  # Authentication (JWT, OAuth)
│       ├── users/                 # User profiles
│       ├── connections/           # Doctor-patient relationships
│       ├── prescriptions/         # Medication prescriptions
│       ├── doses/                 # Medication tracking
│       ├── health-monitoring/     # Vitals tracking
│       ├── ocr/                   # OCR service integration
│       ├── bakong-payment/        # Payment integration
│       ├── notifications/         # Push/email notifications
│       ├── email/                 # SendGrid integration
│       ├── audit/                 # Activity logging
│       ├── subscriptions/         # Tier management
│       ├── doctor-dashboard/      # Doctor analytics
│       ├── medicines/             # Drug database
│       ├── adherence/             # Adherence metrics
│       └── batch-medication/      # Medication grouping
├── prisma/
│   └── schema.prisma              # Database schema (all models)
├── docker-compose.yml             # Dev environment
├── package.json                   # Dependencies
└── Dockerfile                     # Container config

/bakong_payment
├── src/
│   ├── main.ts                    # Service entry point
│   ├── app.module.ts              # Root module
│   ├── controllers/
│   │   ├── payment.controller.ts  # /api/payments/* endpoints
│   │   └── subscription.controller.ts  # /api/subscriptions/* endpoints
│   ├── services/
│   │   ├── payment.service.ts     # KHQR generation, QR codes
│   │   └── subscription.service.ts   # Subscription management
│   ├── bakong/
│   │   ├── client.ts              # Bakong API client
│   │   └── khqr.ts                # KHQR code generation
│   └── prisma/
│       └── prisma.service.ts      # Payment database connection
├── prisma/
│   └── schema.prisma              # Payment-specific schema
├── docker-compose.yml
├── package.json
└── Dockerfile

/ocr
├── app/
│   ├── main.py                    # FastAPI app entry
│   ├── config.py                  # Configuration
│   ├── api/
│   │   ├── routes.py              # /api/v1/extract, /api/v1/health
│   │   └── models.py              # Request/response models
│   └── pipeline/
│       ├── orchestrator.py        # Main pipeline
│       ├── ocr_engine.py          # Kiri-OCR wrapper
│       ├── preprocessor.py        # Image preprocessing
│       ├── text_parser.py         # Parse OCR text
│       ├── formatter.py           # Format JSON response
│       └── layout.py              # Table/region detection
├── Dockerfile
├── requirements.txt               # Python dependencies
└── test_ocr_direct.py

/ai-llm-service
├── app/
│   ├── main.py                    # FastAPI app entry
│   ├── api/
│   │   └── extraction_routes.py   # /api/v1/enhance, /api/v1/validate
│   ├── core/
│   │   ├── llm_client.py          # LLM client (Ollama/OpenRouter)
│   │   ├── model_loader.py        # Model initialization
│   │   └── generation.py          # LLM generation logic
│   ├── features/
│   │   └── prescription/
│   │       ├── enhancer.py        # Prescription enhancement
│   │       ├── validator.py       # Validation logic
│   │       └── processor.py       # Processing
│   └── safety/
│       ├── medical.py             # Medical safety checks
│       └── language.py            # Language detection
├── Dockerfile
├── requirements.txt
└── prompts/                       # LLM prompt templates

/database
└── init-scripts/                  # PostgreSQL init scripts

docker-compose.yml                 # Main orchestration (all services)
docker-compose.prod.yml            # Production deployment
.env.example                        # Environment template
```

---

## Database Models - Cheat Sheet

### Users
- **PK**: id (UUID)
- **Unique**: email, phoneNumber, googleId, licenseNumber, idCardNumber
- **Roles**: PATIENT, DOCTOR, FAMILY_MEMBER
- **Status**: ACTIVE, PENDING_VERIFICATION, VERIFIED, REJECTED, LOCKED

### Prescriptions
- **PK**: id (UUID)
- **FK**: patientId, doctorId (nullable)
- **Status**: DRAFT, ACTIVE, PAUSED, INACTIVE
- **Relations**: medications[], doseEvents[], versions[]
- **Metadata**: ocrMetadata (JSON from OCR)

### Medications
- **PK**: id (UUID)
- **FK**: prescriptionId, batchId (nullable)
- **Dosage**: morningDosage, afternoonDosage, eveningDosage, nightDosage (JSON)
- **Properties**: medicineName, medicineNameKhmer, dosageAmount, frequency, isPRN, beforeMeal

### DoseEvents
- **PK**: id (UUID)
- **FK**: prescriptionId, medicationId, patientId
- **Status**: DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED
- **Period**: MORNING, AFTERNOON, EVENING, NIGHT
- **Tracking**: scheduledTime, takenAt, skipReason, wasOffline

### Connections
- **PK**: id (UUID)
- **FK**: initiatorId, recipientId (both Users)
- **Status**: PENDING, ACCEPTED, REVOKED
- **Permission**: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED

### HealthVitals
- **PK**: id (UUID)
- **FK**: patientId
- **Type**: BLOOD_PRESSURE, GLUCOSE, HEART_RATE, WEIGHT, TEMPERATURE, SPO2
- **Fields**: value, valueSecondary (e.g., diastolic), unit, measuredAt

### Notifications
- **Type**: CONNECTION_REQUEST, PRESCRIPTION_UPDATE, MISSED_DOSE_ALERT, VITAL_ANOMALY, etc.
- **Status**: isRead, readAt
- **Delivery**: In-app, Email (SendGrid), Push (FCM)

### AuditLog
- **Action**: CONNECTION_REQUEST, DOSE_TAKEN, PRESCRIPTION_UPDATE, etc.
- **Tracking**: actorId, resourceType, resourceId, details (JSON), ipAddress

---

## API Endpoints Quick Reference

### Authentication
```
POST   /api/v1/auth/login                     # Email/Phone + Password
POST   /api/v1/auth/register/patient          # Patient signup
POST   /api/v1/auth/register/doctor           # Doctor signup
POST   /api/v1/auth/otp/send                  # Send OTP
POST   /api/v1/auth/otp/verify                # Verify OTP
POST   /api/v1/auth/refresh                   # Refresh JWT
POST   /api/v1/auth/google                    # Google OAuth
POST   /api/v1/auth/telegram                  # Telegram OAuth
```

### Prescriptions
```
GET    /api/v1/prescriptions                  # List (patient/doctor)
GET    /api/v1/prescriptions/:id              # Get details
POST   /api/v1/prescriptions                  # Create (doctor)
POST   /api/v1/prescriptions/patient          # Create (patient from OCR)
PATCH  /api/v1/prescriptions/:id              # Update (doctor)
POST   /api/v1/prescriptions/:id/urgent-update    # Urgent update
POST   /api/v1/prescriptions/:id/confirm      # Confirm (patient)
POST   /api/v1/prescriptions/:id/pause        # Pause
POST   /api/v1/prescriptions/:id/resume       # Resume
DELETE /api/v1/prescriptions/:id              # Delete
```

### Doses
```
GET    /api/v1/doses/schedule?date=YYYY-MM-DD    # Daily schedule
POST   /api/v1/doses/:id/mark-taken              # Mark taken
POST   /api/v1/doses/:id/skip                    # Skip dose
GET    /api/v1/doses/history                     # Dose history
GET    /api/v1/doses/adherence                   # Adherence stats
```

### Health Monitoring
```
POST   /api/v1/health-monitoring/vitals      # Record vital
GET    /api/v1/health-monitoring/vitals      # Get vitals
POST   /api/v1/health-monitoring/thresholds  # Set alert thresholds
GET    /api/v1/health-monitoring/alerts      # Get health alerts
POST   /api/v1/health-monitoring/emergency   # Emergency alert
```

### Connections
```
POST   /api/v1/connections                   # Create request
GET    /api/v1/connections                   # List connections
POST   /api/v1/connections/:id/accept        # Accept request
POST   /api/v1/connections/:id/revoke        # Revoke connection
POST   /api/v1/connection-tokens             # Generate invite token
POST   /api/v1/connections/token/use         # Use invite token
GET    /api/v1/doctor-search                 # Search doctors
```

### OCR
```
POST   /api/v1/ocr/scan                      # Scan & create prescription
POST   /api/v1/ocr/extract                   # Extract preview
GET    /api/v1/ocr/health                    # Check service status
```

### Bakong Payment
```
POST   /api/v1/bakong-payment/create         # Create payment + QR
GET    /api/v1/bakong-payment/status/:md5    # Check status
GET    /api/v1/bakong-payment/history        # Payment history
POST   /api/v1/bakong-payment/webhook        # Bakong webhook
```

### Notifications
```
GET    /api/v1/notifications                 # List notifications
PATCH  /api/v1/notifications/:id/read        # Mark as read
```

### Users
```
GET    /api/v1/users/me                      # Current user
GET    /api/v1/users/:id                     # Get user details
PATCH  /api/v1/users/me                      # Update profile
GET    /api/v1/users/search?query=...        # Search users
```

---

## Environment Variables Quick Setup

### Backend
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/dastern?schema=public
POSTGRES_USER=dastern_user
POSTGRES_PASSWORD=dastern_rayu

# Redis (cache)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=dastern_redis_password

# JWT
JWT_SECRET=your-secret-key-min-32-chars
JWT_REFRESH_SECRET=your-refresh-secret-min-32-chars
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Services
OCR_SERVICE_URL=http://localhost:8003
AI_SERVICE_URL=http://localhost:8001
BAKONG_SERVICE_URL=http://localhost:3002

# Email (SendGrid)
SENDGRID_API_KEY=your-api-key
SENDGRID_FROM_EMAIL=noreply@dastern.com

# Port
PORT=3001
NODE_ENV=development
```

### OCR Service
```bash
PORT=8000
OCR_MODEL=kiri_ocr
MAX_UPLOAD_SIZE_MB=10
PREPROCESS_MAX_DIMENSION=2048
```

### AI-LLM Service
```bash
PORT=8001
LLM_PROVIDER=ollama
OLLAMA_ENDPOINT=http://localhost:11434
MODEL_NAME=llama2
```

### Bakong Payment
```bash
PORT=3002
DATABASE_URL=postgresql://...
BAKONG_API_KEY=...
BAKONG_WEBHOOK_SECRET=...
```

---

## Common Development Tasks

### Start Development Environment
```bash
# Backend NestJS
cd backend_nestjs
npm install
npm run start:dev

# OCR Service
cd ocr
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000

# AI-LLM Service
cd ai-llm-service
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8001

# Bakong Payment Service
cd bakong_payment
npm install
npm run start:dev
```

### Database Migrations (Prisma)
```bash
# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate dev --name add_feature

# Open database UI
npx prisma studio

# Seed database
npx prisma db seed
```

### Docker Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Reset data
docker-compose down -v
docker-compose up -d
```

### Testing
```bash
# NestJS tests
npm run test
npm run test:watch
npm run test:cov

# E2E tests
npm run test:e2e
```

---

## Key Files by Component

### Authentication & Security
- `src/modules/auth/auth.service.ts` - Core auth logic
- `src/modules/auth/otp.service.ts` - OTP handling
- `src/modules/auth/strategies/jwt.strategy.ts` - JWT validation
- `src/common/decorators/current-user.decorator.ts` - User injection
- `src/common/guards/roles.guard.ts` - Role validation

### Prescription & OCR Flow
- `src/modules/prescriptions/prescriptions.service.ts` - Prescription management
- `src/modules/prescriptions/prescriptions.controller.ts` - REST endpoints
- `src/modules/ocr/ocr.service.ts` - OCR integration
- `src/modules/ocr/ocr.controller.ts` - OCR endpoints

### Dose Tracking
- `src/modules/doses/doses.service.ts` - Dose scheduling & marking
- `src/modules/doses/doses.controller.ts` - REST endpoints
- `src/modules/doses/missed-dose.job.ts` - Background job

### Health Monitoring
- `src/modules/health-monitoring/health-monitoring.service.ts` - Vitals tracking
- `src/modules/health-monitoring/health-monitoring.controller.ts` - REST endpoints

### Connections & Relationships
- `src/modules/connections/connections.service.ts` - Doctor-patient linking
- `src/modules/connections/connection-token.service.ts` - Invite token management
- `src/modules/connections/nudge.service.ts` - Reminder nudges

### Notifications
- `src/modules/notifications/notifications.service.ts` - Notification dispatch
- `src/modules/email/email.service.ts` - SendGrid integration

### Payment Integration
- `bakong_payment/src/services/payment.service.ts` - KHQR generation
- `bakong_payment/src/bakong/client.ts` - Bakong API client
- `backend_nestjs/src/modules/bakong-payment/bakong-payment.service.ts` - Backend integration

### OCR Pipeline (Python)
- `ocr/app/pipeline/orchestrator.py` - Full pipeline
- `ocr/app/pipeline/ocr_engine.py` - Kiri-OCR wrapper
- `ocr/app/pipeline/text_parser.py` - Text parsing
- `ocr/app/api/routes.py` - FastAPI routes

### AI Service (Python)
- `ai-llm-service/app/core/llm_client.py` - LLM client
- `ai-llm-service/app/features/prescription/enhancer.py` - Enhancement logic
- `ai-llm-service/app/safety/medical.py` - Safety checks

---

## Deployment Checklist

### Pre-Deployment
- [ ] Update `.env` with production secrets
- [ ] Set `NODE_ENV=production`
- [ ] Configure SSL certificates
- [ ] Set up domain/DNS
- [ ] Configure CORS origins
- [ ] Review rate limiting settings
- [ ] Set up monitoring/logging

### Database
- [ ] Run migrations: `npx prisma migrate deploy`
- [ ] Verify backups configured
- [ ] Set up PostgreSQL replication (optional)

### Services
- [ ] Build Docker images
- [ ] Push to container registry
- [ ] Configure health checks
- [ ] Set up auto-restart policies
- [ ] Configure logging/monitoring

### Infrastructure
- [ ] Configure Nginx reverse proxy
- [ ] Set up SSL/TLS
- [ ] Configure firewalls
- [ ] Set up backups
- [ ] Configure monitoring alerts

### Testing
- [ ] Full system test
- [ ] Load testing
- [ ] Security audit
- [ ] Data migration test
- [ ] Rollback plan

---

## Troubleshooting Common Issues

### OCR Service Not Responding
```bash
# Check if service is running
curl http://localhost:8000/api/v1/health

# Check logs
docker logs dastern-kiri-ocr

# Verify port is open
netstat -an | grep 8000

# Rebuild service
docker-compose up --build ocr
```

### Database Connection Failed
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Verify credentials in .env
# Check DATABASE_URL is correct

# View logs
docker logs dastern-postgres

# Reset database
docker-compose down -v
docker-compose up -d postgres
npx prisma migrate deploy
```

### JWT Token Issues
```bash
# Verify JWT_SECRET is set
echo $JWT_SECRET

# Check token expiry
# Token expires in 15 minutes by default

# Refresh token
POST /api/v1/auth/refresh
{ "refreshToken": "..." }
```

### Payment QR Code Not Generated
```bash
# Check Bakong service is running
curl http://localhost:3002/api/health

# Verify BAKONG_API_KEY is set
# Check public/qr-codes directory permissions

# View logs
docker logs dastern-bakong-payment
```

---

## Performance Tips

1. **Database**
   - Use indexes (already defined in schema)
   - Run `ANALYZE` periodically
   - Monitor query performance
   - Set up read replicas for scaling

2. **Caching**
   - Prescriptions: Cache for 1 hour
   - User profiles: Cache for 24 hours
   - Search results: Cache for 5 minutes

3. **API**
   - Implement pagination (limit 50 records)
   - Use field filtering (select specific columns)
   - Compress responses (already enabled)
   - Rate limit aggressively

4. **Background Jobs**
   - Use Bull queue for async tasks
   - Process missed doses daily (cron)
   - Send batch notifications (hourly)

5. **OCR/AI**
   - Cache OCR results temporarily
   - Implement request timeout (40 seconds)
   - Queue OCR requests during peak times
   - Monitor LLM response times

---

## File Paths Reference

**Main Backend**: `/backend_nestjs`
**Payment Service**: `/bakong_payment`
**OCR Service**: `/ocr`
**AI Service**: `/ai-llm-service`
**Database Schema**: `/backend_nestjs/prisma/schema.prisma`
**Docker Compose**: `/docker-compose.yml`
**Nginx Config**: `/nginx/nginx.conf`
**Documentation**: `/BACKEND_ARCHITECTURE.md`

