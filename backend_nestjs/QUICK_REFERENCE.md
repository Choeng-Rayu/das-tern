# 🚀 Quick Reference - Das Tern NestJS Backend

## 📍 Location
```
/home/rayu/das-tern/backend_nestjs/
```

## ⚡ Quick Start (5 Commands)

```bash
# 1. Install
npm install

# 2. Start Docker (PostgreSQL + Redis)
docker compose up -d

# 3. Generate Prisma
npm run prisma:generate

# 4. Migrate Database
npm run prisma:migrate

# 5. Start Backend
npm run start:dev
```

**API**: http://localhost:3000/api/v1

---

## 🔧 Common Commands

```bash
# Development
npm run start:dev          # Start with hot reload
npm run start:debug        # Start with debugger

# Database
npm run prisma:studio      # Open database GUI
npm run prisma:seed        # Seed test data
npm run prisma:migrate     # Create migration

# Docker
docker compose up -d       # Start containers
docker compose down        # Stop containers
docker compose down -v     # Stop + delete data
docker compose ps          # Check status
docker compose logs        # View logs

# Testing
npm run test               # Unit tests
npm run test:e2e           # E2E tests
npm run test:cov           # Coverage

# Production
npm run build              # Build
npm run start:prod         # Start production
```

---

## 📁 Key Files

```
src/main.ts                 # Entry point
src/app.module.ts           # Root module
src/modules/auth/           # Authentication
src/modules/prescriptions/  # Prescriptions
prisma/schema.prisma        # Database schema
docker-compose.yml          # Docker config
.env                        # Environment vars
```

---

## 🔐 Environment Variables

```env
DATABASE_URL="postgresql://dastern_user:dastern_password@localhost:5432/dastern"
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your-secret-key
PORT=3000
```

---

## 🌐 API Endpoints

```
POST   /api/v1/auth/login
POST   /api/v1/auth/register
GET    /api/v1/auth/me

GET    /api/v1/users/me
PATCH  /api/v1/users/me

GET    /api/v1/prescriptions
POST   /api/v1/prescriptions
GET    /api/v1/prescriptions/:id
PATCH  /api/v1/prescriptions/:id

GET    /api/v1/doses
PATCH  /api/v1/doses/:id/taken

GET    /api/v1/connections
POST   /api/v1/connections
PATCH  /api/v1/connections/:id/accept

GET    /api/v1/notifications
PATCH  /api/v1/notifications/:id/read
```

---

## 🐛 Troubleshooting

**Port in use?**
```bash
lsof -ti:3000 | xargs kill -9
```

**Database issues?**
```bash
docker compose restart postgres
docker compose logs postgres
```

**Redis issues?**
```bash
docker compose restart redis
docker compose logs redis
```

**Reset everything?**
```bash
docker compose down -v
docker compose up -d
npm run prisma:migrate
```

---

## 📚 Documentation

- `README.md` - Full docs
- `SETUP_GUIDE.md` - Quick start
- `COMPLETE.md` - Summary
- `ARCHITECTURE_COMPARISON.md` - Next.js vs NestJS

---

## ✅ Agent Rules

✅ Docker ONLY for PostgreSQL & Redis  
✅ NestJS runs outside Docker  
✅ .env not committed  
✅ .env.example committed  
✅ Clean project structure  

---

**Happy Coding! 🎉**


---

## 🧪 Testing Endpoints with curl

### Patient Registration
```bash
curl -X POST http://localhost:3000/api/v1/auth/register/patient \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "gender": "MALE",
    "dateOfBirth": "2000-01-01",
    "idCardNumber": "123456789",
    "phoneNumber": "+85512345678",
    "password": "password123",
    "pinCode": "1234"
  }'
```

### Send OTP
```bash
curl -X POST http://localhost:3000/api/v1/auth/otp/send \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+85512345678"}'
```

### Verify OTP (check console for OTP)
```bash
curl -X POST http://localhost:3000/api/v1/auth/otp/verify \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+85512345678", "otp": "1234"}'
```

### Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+85512345678", "password": "password123"}'
```

### Get Profile (requires token)
```bash
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 📚 Documentation Files

- **README.md** - Full documentation
- **IMPLEMENTATION_PROGRESS.md** - Current progress (15%)
- **IMPLEMENTATION_GUIDE.md** - Step-by-step guide
- **FINAL_SUMMARY.md** - Implementation summary
- **QUICK_REFERENCE.md** - This file

---

## 🎯 Current Status

- ✅ **Phase 1**: Authentication (COMPLETE)
- 🚧 **Phase 2**: Users (NEXT)
- ⏳ **Phase 3-8**: Remaining modules

**Progress**: 15% (3/40 requirements, 1/8 modules)

---

## 🐛 Troubleshooting

### Port 3000 in use
```bash
lsof -ti:3000 | xargs kill -9
```

### Database connection error
```bash
docker compose restart
docker compose logs postgres
```

### Prisma Client not found
```bash
npm run prisma:generate
```

---

**Last Updated**: 2026-02-08 18:35
