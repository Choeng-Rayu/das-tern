# Das Tern Backend - NestJS Implementation

> **Enterprise-grade medication management platform backend built with NestJS, PostgreSQL, and Redis**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Deployment](#deployment)

---

## 🎯 Overview

This is the NestJS implementation of the Das Tern backend API, providing a robust, scalable, and type-safe server infrastructure for the medication management platform.

### Key Features

- ✅ **Type-Safe**: Full TypeScript with Prisma ORM
- ✅ **Authentication**: JWT + Google OAuth
- ✅ **Authorization**: Role-based access control (RBAC)
- ✅ **Database**: PostgreSQL 17 with Prisma
- ✅ **Caching**: Redis for sessions and performance
- ✅ **Security**: Helmet, rate limiting, input validation
- ✅ **Scalability**: Modular architecture, connection pooling
- ✅ **Audit Logging**: Complete transparency of all actions
- ✅ **Offline Sync**: Support for offline-first mobile apps

---

## 🛠️ Technology Stack

### Core Framework
- **NestJS**: `^10.3.0` - Enterprise Node.js framework
- **Node.js**: `>=22.0.0` - JavaScript runtime
- **TypeScript**: `^5.7.2` - Type-safe development

### Database & ORM
- **PostgreSQL**: `17` - Relational database
- **Prisma**: `^6.2.0` - Type-safe ORM
- **Redis**: `7.4` - Caching and sessions

### Authentication & Security
- **Passport.js**: JWT and OAuth strategies
- **bcryptjs**: Password hashing
- **Helmet**: Security headers
- **class-validator**: Input validation

### Additional Tools
- **Jest**: Testing framework
- **date-fns**: Date manipulation
- **compression**: Response compression

---

## 📁 Project Structure

```
backend_nestjs/
├── src/
│   ├── main.ts                    # Application entry point
│   ├── app.module.ts              # Root module
│   │
│   ├── common/                    # Shared utilities
│   │   ├── decorators/
│   │   │   ├── current-user.decorator.ts
│   │   │   └── roles.decorator.ts
│   │   └── guards/
│   │       └── roles.guard.ts
│   │
│   ├── database/                  # Database layer
│   │   ├── database.module.ts
│   │   └── prisma.service.ts
│   │
│   └── modules/                   # Feature modules
│       ├── auth/                  # Authentication
│       │   ├── auth.module.ts
│       │   ├── auth.service.ts
│       │   ├── auth.controller.ts
│       │   ├── dto/
│       │   └── strategies/
│       │       ├── jwt.strategy.ts
│       │       └── google.strategy.ts
│       │
│       ├── users/                 # User management
│       ├── prescriptions/         # Prescription management
│       ├── doses/                 # Dose tracking
│       ├── connections/           # Doctor-Patient connections
│       ├── notifications/         # Notifications
│       ├── audit/                 # Audit logging
│       └── subscriptions/         # Subscription management
│
├── prisma/
│   ├── schema.prisma              # Database schema
│   ├── migrations/                # Database migrations
│   └── seed.ts                    # Seed data
│
├── test/                          # Test files
├── .env.example                   # Environment variables template
├── nest-cli.json                  # NestJS CLI configuration
├── package.json                   # Dependencies
├── tsconfig.json                  # TypeScript configuration
└── README.md                      # This file
```

---

## 📦 Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js**: >= 22.0.0 ([Download](https://nodejs.org/))
- **npm**: >= 10.0.0 (comes with Node.js)
- **PostgreSQL**: 17 (via Docker or local installation)
- **Redis**: 7.4 (via Docker or local installation)
- **Docker** (optional but recommended): For running PostgreSQL and Redis

---

## 🚀 Installation

### 1. Clone the repository

```bash
cd /home/rayu/das-tern/backend_nestjs
```

### 2. Install dependencies

```bash
npm install
```

### 3. Copy environment variables

```bash
cp .env.example .env
```

Edit `.env` with your configuration (see [Configuration](#configuration) section).

---

## ⚙️ Configuration

### Environment Variables

Edit the `.env` file with your settings:

```env
# Server
NODE_ENV=development
PORT=3000
API_PREFIX=api/v1

# Database
DATABASE_URL="postgresql://dastern_user:dastern_password@localhost:5432/dastern?schema=public"

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_CALLBACK_URL=http://localhost:3000/api/v1/auth/google/callback

# Timezone
TZ=Asia/Phnom_Penh
```

---

## 🗄️ Database Setup

### Option 1: Using Docker (Recommended)

The project follows the agent rules: **Docker is ONLY used for PostgreSQL and Redis**.

Create a `docker-compose.yml` in the project root:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:17-alpine
    container_name: dastern-postgres
    environment:
      POSTGRES_USER: dastern_user
      POSTGRES_PASSWORD: dastern_password
      POSTGRES_DB: dastern
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dastern_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7.4-alpine
    container_name: dastern-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  postgres_data:
  redis_data:
```

Start the containers:

```bash
docker compose up -d
```

### Option 2: Local Installation

Install PostgreSQL 17 and Redis 7.4 locally and update the `.env` file accordingly.

### Run Migrations

```bash
npm run prisma:generate
npm run prisma:migrate
```

### Seed Database (Optional)

```bash
npm run prisma:seed
```

---

## 🏃 Running the Application

### Development Mode

```bash
npm run start:dev
```

The API will be available at: `http://localhost:3000/api/v1`

### Production Mode

```bash
npm run build
npm run start:prod
```

### Debug Mode

```bash
npm run start:debug
```

---

## 📚 API Documentation

### Base URL

```
http://localhost:3000/api/v1
```

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | Login with phone number and password |
| POST | `/auth/register` | Register new user |
| POST | `/auth/refresh` | Refresh access token |
| GET | `/auth/google` | Initiate Google OAuth |
| GET | `/auth/google/callback` | Google OAuth callback |
| GET | `/auth/me` | Get current user profile |

### User Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users/me` | Get current user profile |
| GET | `/users/:id` | Get user by ID |
| PATCH | `/users/me` | Update current user profile |

### Prescription Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/prescriptions` | Get all prescriptions |
| GET | `/prescriptions/:id` | Get prescription by ID |
| POST | `/prescriptions` | Create new prescription |
| PATCH | `/prescriptions/:id` | Update prescription |
| POST | `/prescriptions/:id/urgent-update` | Urgent prescription update |
| PATCH | `/prescriptions/:id/activate` | Activate prescription |
| PATCH | `/prescriptions/:id/pause` | Pause prescription |
| PATCH | `/prescriptions/:id/deactivate` | Deactivate prescription |

### Dose Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/doses` | Get all dose events |
| PATCH | `/doses/:id/taken` | Mark dose as taken |
| PATCH | `/doses/:id/skipped` | Mark dose as skipped |

### Connection Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/connections` | Get all connections |
| POST | `/connections` | Create connection request |
| PATCH | `/connections/:id/accept` | Accept connection |
| PATCH | `/connections/:id/revoke` | Revoke connection |

### Notification Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications` | Get all notifications |
| PATCH | `/notifications/:id/read` | Mark notification as read |

### Audit Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/audit` | Get audit logs |

### Subscription Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/subscriptions/me` | Get current subscription |
| PATCH | `/subscriptions/tier` | Update subscription tier |

---

## 🧪 Testing

### Run Unit Tests

```bash
npm run test
```

### Run E2E Tests

```bash
npm run test:e2e
```

### Run Tests with Coverage

```bash
npm run test:cov
```

---

## 🚢 Deployment

### Build for Production

```bash
npm run build
```

### Start Production Server

```bash
npm run start:prod
```

### Docker Deployment (Backend)

**Note**: Following agent rules, Docker is ONLY for PostgreSQL and Redis. The NestJS backend runs outside Docker.

However, if you need to containerize the backend for deployment:

```dockerfile
# Dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "start:prod"]
```

---

## 🔒 Security Best Practices

- ✅ Never commit `.env` files
- ✅ Use strong JWT secrets in production
- ✅ Enable HTTPS in production
- ✅ Configure CORS properly
- ✅ Use rate limiting
- ✅ Validate all inputs
- ✅ Keep dependencies updated
- ✅ Use environment-specific configurations

---

## 📝 Database Migrations

### Create a New Migration

```bash
npm run prisma:migrate
```

### Apply Migrations

```bash
npx prisma migrate deploy
```

### Reset Database (Development Only)

```bash
npx prisma migrate reset
```

---

## 🐛 Troubleshooting

### Database Connection Issues

1. Ensure PostgreSQL is running:
   ```bash
   docker compose ps
   ```

2. Check database logs:
   ```bash
   docker compose logs postgres
   ```

3. Verify connection string in `.env`

### Redis Connection Issues

1. Ensure Redis is running:
   ```bash
   docker compose ps
   ```

2. Check Redis logs:
   ```bash
   docker compose logs redis
   ```

### Port Already in Use

Change the `PORT` in `.env` or kill the process using the port:

```bash
lsof -ti:3000 | xargs kill -9
```

---

## 📞 Support

For issues or questions:

- 📧 Email: support@dastern.com
- 📚 Documentation: https://docs.dastern.com
- 🐛 Issues: GitHub Issues

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

**Built with ❤️ using NestJS**

[⬆ Back to Top](#das-tern-backend---nestjs-implementation)

</div>
