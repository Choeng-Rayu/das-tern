# Das Tern Backend API

> **Latest Technology Stack - Updated February 2026**

A comprehensive medication management platform backend built with the latest stable versions of Next.js, PostgreSQL, and modern TypeScript tooling.

---

## 🚀 Technology Stack (Latest Versions)

### Core Framework
- **Next.js**: `^15.1.6` (Latest stable - App Router)
- **React**: `^19.0.0` (Latest stable)
- **TypeScript**: `^5.7.2` (Latest stable)
- **Node.js**: `>=22.0.0` (LTS)

### Database & ORM
- **PostgreSQL**: `17-alpine` (Latest stable)
- **Prisma**: `^6.2.0` (Latest stable)
- **Prisma Client**: `^6.2.0`

### Caching & Queue
- **Redis**: `7.4-alpine` (Latest stable)
- **IORedis**: `^5.4.2`
- **RabbitMQ**: `4.0-management-alpine` (Latest stable)

### Authentication & Security
- **NextAuth.js**: `^5.0.0-beta.25` (Auth.js v5)
- **Zod**: `^3.24.1` (Latest stable)
- **bcryptjs**: `^2.4.3`

### Real-time & WebSocket
- **Socket.io**: `^4.8.1` (Server)
- **Socket.io-client**: `^4.8.1` (Client)

### Date & Time
- **date-fns**: `^4.1.0` (Latest stable)
- **date-fns-tz**: `^3.2.0` (Timezone support)

### Storage
- **MinIO**: `latest` (S3-compatible object storage)

### Development Tools
- **ESLint**: `^9.17.0`
- **Tailwind CSS**: `^4.0.0`
- **tsx**: `^4.19.2` (TypeScript execution)

---

## 📋 Prerequisites

- **Node.js**: 22.x or higher
- **npm**: 10.x or higher
- **Docker**: 24.x or higher
- **Docker Compose**: 2.x or higher

---

## 🛠️ Quick Start

### 1. Clone and Install

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install
```

### 2. Environment Setup

```bash
# Copy environment template
cp ../.env.example .env

# Edit .env with your configuration
nano .env
```

### 3. Start Infrastructure

```bash
# Start PostgreSQL 17, Redis 7.4, RabbitMQ 4.0, MinIO
docker-compose up -d

# Verify services are running
docker-compose ps
```

### 4. Database Setup

```bash
# Generate Prisma Client
npm run db:generate

# Run migrations
npm run db:migrate

# Seed database (optional)
npm run db:seed

# Open Prisma Studio (optional)
npm run db:studio
```

### 5. Start Development Server

```bash
# Start Next.js dev server
npm run dev
```

The API will be available at `http://localhost:3000`

---

## 📦 Available Scripts

```bash
# Development
npm run dev              # Start Next.js dev server with hot reload

# Build
npm run build            # Build for production
npm run start            # Start production server

# Database
npm run db:generate      # Generate Prisma Client
npm run db:push          # Push schema changes (dev only)
npm run db:migrate       # Create and apply migrations
npm run db:studio        # Open Prisma Studio GUI
npm run db:seed          # Seed database with test data

# Code Quality
npm run lint             # Run ESLint
```

---

## 🐳 Docker Services

### PostgreSQL 17
- **Port**: 5432
- **Database**: dastern
- **User**: dastern_user
- **Features**: UTF-8, Cambodia timezone, connection pooling

### Redis 7.4
- **Port**: 6379
- **Max Memory**: 512MB
- **Eviction Policy**: allkeys-lru
- **Persistence**: AOF + RDB

### RabbitMQ 4.0
- **AMQP Port**: 5672
- **Management UI**: http://localhost:15672
- **Default User**: dastern_user

### MinIO (S3-compatible)
- **API Port**: 9000
- **Console**: http://localhost:9001
- **Root User**: dastern_admin

---

## 🗄️ Database Schema

### Core Tables
- **users**: User accounts (Patient, Doctor, Family)
- **connections**: User relationships with permissions
- **prescriptions**: Medication prescriptions with versioning
- **medications**: Individual medications in prescriptions
- **dose_events**: Scheduled medication doses
- **notifications**: User notifications
- **audit_logs**: Immutable audit trail
- **subscriptions**: Subscription plans and storage
- **meal_time_preferences**: User meal time settings

### Key Features
- **UUID Primary Keys**: All tables use UUID for security
- **Timezone Support**: All timestamps in Cambodia time (UTC+7)
- **JSONB Columns**: Flexible data storage for dosages and metadata
- **Indexes**: Optimized for common query patterns
- **Foreign Keys**: Referential integrity with cascade rules
- **Enums**: Type-safe status and role management

---

## 🔐 Authentication

### NextAuth.js v5 (Auth.js)
- **JWT Strategy**: Stateless authentication
- **Access Token**: 15 minutes expiry
- **Refresh Token**: 7 days expiry (stored in Redis)
- **Google OAuth**: Social login support
- **Credentials**: Phone/email + password

### Security Features
- Password hashing with bcrypt (10 rounds)
- PIN code hashing for quick access
- Account lockout after 5 failed attempts
- Token rotation on refresh
- Redis-based session management

---

## 🌍 Multi-Language Support

### Supported Languages
- **Khmer** (ភាសាខ្មែរ) - Default
- **English**

### Implementation
- User language preference stored in database
- API responses translated based on `Accept-Language` header
- Error messages in both languages
- Notification content localized

---

## 🎨 Theme Support

### Available Themes
- **Light Mode** (Default)
- **Dark Mode**

### Implementation
- User theme preference stored in database
- Theme setting returned in user profile
- Mobile app applies theme based on preference

---

## 📊 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - User logout
- `GET /api/auth/google` - Google OAuth

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update profile
- `PUT /api/users/language` - Change language
- `PUT /api/users/theme` - Change theme

### Connections
- `POST /api/connections/request` - Send connection request
- `PUT /api/connections/:id/accept` - Accept connection
- `PUT /api/connections/:id/revoke` - Revoke connection
- `GET /api/connections` - List connections

### Prescriptions
- `POST /api/prescriptions` - Create prescription
- `GET /api/prescriptions` - List prescriptions
- `GET /api/prescriptions/:id` - Get prescription details
- `PUT /api/prescriptions/:id` - Update prescription
- `PUT /api/prescriptions/:id/status` - Change status

### Dose Events
- `POST /api/doses/taken` - Mark dose as taken
- `POST /api/doses/skip` - Skip dose with reason
- `GET /api/doses/schedule` - Get daily schedule
- `POST /api/doses/sync` - Sync offline doses

### Notifications
- `GET /api/notifications` - List notifications
- `PUT /api/notifications/:id/read` - Mark as read
- `DELETE /api/notifications/:id` - Delete notification

---

## 🔄 Offline Sync

### Sync Strategy
1. Client stores actions locally when offline
2. Client sends batch sync request when online
3. Server validates and applies changes
4. Server resolves conflicts (client timestamp wins for doses)
5. Server returns sync summary

### Conflict Resolution
- **Dose Events**: Client timestamp wins
- **Prescriptions**: Server version wins
- **Connections**: Latest status wins

---

## 📈 Performance Optimizations

### Caching Strategy
- **User Profiles**: 5 minutes TTL
- **Subscriptions**: 10 minutes TTL
- **Medication Schedules**: 1 minute TTL
- **Connection Lists**: 5 minutes TTL

### Database Optimizations
- Composite indexes for common queries
- Connection pooling (max 20 connections)
- Slow query logging (>1000ms)
- Read replicas support (future)

### Rate Limiting
- **Auth Endpoints**: 5 req/min per IP
- **OTP Endpoints**: 3 req/hour per phone
- **API Endpoints**: 100 req/min per user
- **Upload Endpoints**: 10 req/hour per user

---

## 🧪 Testing

```bash
# Run unit tests
npm test

# Run integration tests
npm run test:integration

# Run e2e tests
npm run test:e2e

# Test coverage
npm run test:coverage
```

---

## 📝 Environment Variables

See `.env.example` for all required environment variables.

### Critical Variables
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `NEXTAUTH_SECRET`: JWT signing secret
- `GOOGLE_CLIENT_ID`: Google OAuth client ID
- `GOOGLE_CLIENT_SECRET`: Google OAuth secret

---

## 🚀 Deployment

### Production Checklist
- [ ] Set `NODE_ENV=production`
- [ ] Use strong secrets for `NEXTAUTH_SECRET` and `JWT_SECRET`
- [ ] Configure production database with SSL
- [ ] Enable Redis persistence
- [ ] Set up database backups
- [ ] Configure monitoring (Sentry, Datadog)
- [ ] Enable rate limiting
- [ ] Set up CDN for static assets
- [ ] Configure CORS for production domain
- [ ] Enable HTTPS/TLS

### Docker Production Build

```bash
# Build production image
docker build -t dastern-backend:latest .

# Run with docker-compose
docker-compose -f docker-compose.prod.yml up -d
```

---

## 📚 Documentation

- [API Documentation](./docs/API.md)
- [Database Schema](./docs/DATABASE.md)
- [Authentication Flow](./docs/AUTH.md)
- [Offline Sync](./docs/SYNC.md)
- [Deployment Guide](./docs/DEPLOYMENT.md)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

## 📞 Support

- **Email**: support@dastern.com
- **Documentation**: https://docs.dastern.com
- **Issues**: https://github.com/dastern/backend/issues

---

<div align="center">

**Built with ❤️ using the latest stable technologies**

**Next.js 15 • PostgreSQL 17 • Prisma 6 • Redis 7.4 • TypeScript 5.7**

</div>
