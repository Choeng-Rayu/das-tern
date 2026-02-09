# Design Document: Das Tern Backend and Database

## Overview

The Das Tern Backend and Database system is a comprehensive server-side infrastructure built with Next.js 14+ App Router, PostgreSQL 16, Prisma ORM, Redis, and NextAuth.js. The system provides a type-safe, scalable, and secure foundation for the medication management platform, supporting three user roles (Patient, Doctor, Family), prescription management with version control, offline synchronization, and multi-language support (Khmer and English).

### Key Design Principles

1. **Type Safety**: Full TypeScript coverage with Prisma-generated types and Zod validation
2. **Scalability**: Connection pooling, caching, and efficient database queries
3. **Security**: JWT authentication, bcrypt hashing, rate limiting, and input validation
4. **Maintainability**: Clean architecture with service layer separation
5. **Performance**: Redis caching, database indexing, and query optimization
6. **Reliability**: Database transactions, error handling, and audit logging
7. **Developer Experience**: Automated migrations, seeding, and comprehensive documentation

### Technology Stack

- **Runtime**: Next.js 14+ with App Router and TypeScript
- **Database**: PostgreSQL 16 in Docker with persistent volumes
- **ORM**: Prisma 5+ for type-safe database access and migrations
- **Cache**: Redis 7+ in Docker for sessions, rate limiting, and caching
- **Authentication**: NextAuth.js v5 (Auth.js) with JWT and Google OAuth
- **Validation**: Zod for runtime schema validation
- **File Storage**: AWS S3 or compatible object storage
- **SMS**: Twilio or AWS SNS for OTP delivery
- **Containerization**: Docker and Docker Compose for local development

## Architecture

### System Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        Flutter[Flutter Mobile App]
    end
    
    subgraph "Next.js Backend - App Router"
        API[API Route Handlers]
        Auth[NextAuth.js Middleware]
        Middleware[Custom Middleware Stack]
    end
    
    subgraph "Service Layer"
        UserService[User Service]
        AuthService[Auth Service]
        ConnectionService[Connection Service]
        PrescriptionService[Prescription Service]
        DoseService[Dose Tracking Service]
        SyncService[Offline Sync Service]
        NotificationService[Notification Service]
        AuditService[Audit Log Service]
        SubscriptionService[Subscription Service]
        StorageService[File Storage Service]
    end
    
    subgraph "Data Access Layer"
        PrismaClient[Prisma Client]
        RedisClient[Redis Client]
    end
    
    subgraph "Data Storage"
        PostgreSQL[(PostgreSQL 16)]
        Redis[(Redis 7)]
        S3[AWS S3]
    end
    
    subgraph "External Services"
        SMS[SMS Provider]
        OAuth[Google OAuth]
    end
    
    Flutter -->|HTTPS/JSON| API
    API --> Auth
    API --> Middleware
    Middleware --> UserService
    Middleware --> ConnectionService
    Middleware --> PrescriptionService
    
    UserService --> PrismaClient
    ConnectionService --> PrismaClient
    PrescriptionService --> PrismaClient
    DoseService --> PrismaClient
    SyncService --> PrismaClient
    AuditService --> PrismaClient
    SubscriptionService --> PrismaClient
    
    AuthService --> RedisClient
    UserService --> RedisClient
    
    PrismaClient --> PostgreSQL
    RedisClient --> Redis
    StorageService --> S3
    AuthService --> SMS
    Auth --> OAuth
```

### Request Flow

```
Client Request
    ↓
Next.js API Route Handler (app/api/*/route.ts)
    ↓
Middleware Stack (CORS → Logging → Auth → Validation)
    ↓
Service Layer (Business Logic)
    ↓
Data Access Layer (Prisma Client / Redis Client)
    ↓
Data Storage (PostgreSQL / Redis / S3)
    ↓
Response (JSON with proper status codes)
    ↓
Audit Logging (Async)
```


## Components and Interfaces

### Project Structure

```
das-tern-backend/
├── app/
│   ├── api/
│   │   ├── auth/
│   │   │   ├── register/
│   │   │   │   ├── patient/route.ts
│   │   │   │   └── doctor/route.ts
│   │   │   ├── login/route.ts
│   │   │   ├── otp/
│   │   │   │   ├── send/route.ts
│   │   │   │   └── verify/route.ts
│   │   │   ├── refresh/route.ts
│   │   │   └── logout/route.ts
│   │   ├── users/
│   │   │   ├── profile/route.ts
│   │   │   └── storage/route.ts
│   │   ├── connections/
│   │   │   ├── route.ts
│   │   │   └── [connectionId]/
│   │   │       ├── accept/route.ts
│   │   │       ├── revoke/route.ts
│   │   │       └── permission/route.ts
│   │   ├── prescriptions/
│   │   │   ├── route.ts
│   │   │   └── [prescriptionId]/
│   │   │       ├── route.ts
│   │   │       ├── confirm/route.ts
│   │   │       └── retake/route.ts
│   │   ├── doses/
│   │   │   ├── schedule/route.ts
│   │   │   ├── history/route.ts
│   │   │   └── [doseId]/
│   │   │       ├── mark-taken/route.ts
│   │   │       ├── skip/route.ts
│   │   │       └── reminder-time/route.ts
│   │   ├── sync/
│   │   │   ├── batch/route.ts
│   │   │   └── status/route.ts
│   │   ├── notifications/
│   │   │   ├── route.ts
│   │   │   ├── stream/route.ts
│   │   │   └── [notificationId]/read/route.ts
│   │   ├── audit-logs/route.ts
│   │   ├── subscriptions/
│   │   │   ├── upgrade/route.ts
│   │   │   ├── current/route.ts
│   │   │   └── family/
│   │   │       ├── add-member/route.ts
│   │   │       └── remove-member/route.ts
│   │   ├── onboarding/meal-times/route.ts
│   │   ├── doctor/
│   │   │   ├── patients/route.ts
│   │   │   └── patients/[patientId]/details/route.ts
│   │   ├── health/route.ts
│   │   └── metrics/route.ts
│   └── layout.tsx
├── lib/
│   ├── prisma.ts
│   ├── redis.ts
│   ├── auth.ts
│   ├── services/
│   │   ├── user.service.ts
│   │   ├── auth.service.ts
│   │   ├── connection.service.ts
│   │   ├── prescription.service.ts
│   │   ├── dose.service.ts
│   │   ├── sync.service.ts
│   │   ├── notification.service.ts
│   │   ├── audit.service.ts
│   │   ├── subscription.service.ts
│   │   └── storage.service.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts
│   │   ├── validation.middleware.ts
│   │   ├── rate-limit.middleware.ts
│   │   ├── error-handler.middleware.ts
│   │   └── audit-logger.middleware.ts
│   ├── validators/
│   │   ├── auth.validator.ts
│   │   ├── user.validator.ts
│   │   ├── prescription.validator.ts
│   │   └── dose.validator.ts
│   ├── utils/
│   │   ├── timezone.util.ts
│   │   ├── language.util.ts
│   │   ├── hash.util.ts
│   │   └── error.util.ts
│   └── types/
│       ├── api.types.ts
│       └── service.types.ts
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.ts
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── package.json
└── tsconfig.json
```

### Database Schema (Prisma)

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Enums
enum UserRole {
  PATIENT
  DOCTOR
  FAMILY_MEMBER
}

enum Gender {
  MALE
  FEMALE
  OTHER
}

enum Language {
  KHMER
  ENGLISH
}

enum Theme {
  LIGHT
  DARK
}

enum AccountStatus {
  ACTIVE
  PENDING_VERIFICATION
  VERIFIED
  REJECTED
  LOCKED
}

enum ConnectionStatus {
  PENDING
  ACCEPTED
  REVOKED
}

enum PermissionLevel {
  NOT_ALLOWED
  REQUEST
  SELECTED
  ALLOWED
}

enum PrescriptionStatus {
  DRAFT
  ACTIVE
  PAUSED
  INACTIVE
}

enum TimePeriod {
  DAYTIME
  NIGHT
}

enum DoseStatus {
  DUE
  TAKEN_ON_TIME
  TAKEN_LATE
  MISSED
  SKIPPED
}

enum SubscriptionTier {
  FREEMIUM
  PREMIUM
  FAMILY_PREMIUM
}

enum ActionType {
  CONNECTION_REQUEST
  CONNECTION_ACCEPT
  CONNECTION_REVOKE
  PERMISSION_CHANGE
  PRESCRIPTION_CREATE
  PRESCRIPTION_UPDATE
  PRESCRIPTION_CONFIRM
  PRESCRIPTION_RETAKE
  DOSE_TAKEN
  DOSE_SKIPPED
  DOSE_MISSED
  DATA_ACCESS
  NOTIFICATION_SENT
  SUBSCRIPTION_CHANGE
}

enum NotificationType {
  CONNECTION_REQUEST
  PRESCRIPTION_UPDATE
  MISSED_DOSE_ALERT
  URGENT_PRESCRIPTION_CHANGE
  FAMILY_ALERT
}

// Models
model User {
  id                   String         @id @default(uuid())
  role                 UserRole
  firstName            String?
  lastName             String?
  fullName             String?
  phoneNumber          String         @unique
  email                String?        @unique
  passwordHash         String
  pinCodeHash          String?
  gender               Gender?
  dateOfBirth          DateTime?
  idCardNumber         String?
  language             Language       @default(KHMER)
  theme                Theme          @default(LIGHT)
  hospitalClinic       String?
  specialty            String?
  licenseNumber        String?
  licensePhotoUrl      String?
  accountStatus        AccountStatus  @default(ACTIVE)
  failedLoginAttempts  Int            @default(0)
  lockedUntil          DateTime?
  createdAt            DateTime       @default(now()) @db.Timestamptz
  updatedAt            DateTime       @updatedAt @db.Timestamptz
  
  // Relations
  initiatedConnections Connection[]   @relation("Initiator")
  receivedConnections  Connection[]   @relation("Recipient")
  ownedPrescriptions   Prescription[] @relation("PatientPrescriptions")
  createdPrescriptions Prescription[] @relation("DoctorPrescriptions")
  doseEvents           DoseEvent[]
  auditLogs            AuditLog[]
  notifications        Notification[]
  subscription         Subscription?
  mealTimePreference   MealTimePreference?
  prescriptionVersions PrescriptionVersion[]
  
  @@index([phoneNumber])
  @@index([email])
  @@index([role])
}

model Connection {
  id              String           @id @default(uuid())
  initiatorId     String
  recipientId     String
  status          ConnectionStatus @default(PENDING)
  permissionLevel PermissionLevel  @default(ALLOWED)
  requestedAt     DateTime         @default(now()) @db.Timestamptz
  acceptedAt      DateTime?        @db.Timestamptz
  revokedAt       DateTime?        @db.Timestamptz
  createdAt       DateTime         @default(now()) @db.Timestamptz
  updatedAt       DateTime         @updatedAt @db.Timestamptz
  
  // Relations
  initiator User @relation("Initiator", fields: [initiatorId], references: [id], onDelete: Cascade)
  recipient User @relation("Recipient", fields: [recipientId], references: [id], onDelete: Cascade)
  
  @@unique([initiatorId, recipientId])
  @@index([initiatorId])
  @@index([recipientId])
  @@index([status])
}

model Prescription {
  id             String             @id @default(uuid())
  patientId      String
  doctorId       String
  patientName    String
  patientGender  String
  patientAge     Int
  symptoms       String             @db.Text
  status         PrescriptionStatus @default(DRAFT)
  currentVersion Int                @default(1)
  isUrgent       Boolean            @default(false)
  urgentReason   String?            @db.Text
  createdAt      DateTime           @default(now()) @db.Timestamptz
  updatedAt      DateTime           @updatedAt @db.Timestamptz
  
  // Relations
  patient     User                  @relation("PatientPrescriptions", fields: [patientId], references: [id], onDelete: Cascade)
  doctor      User                  @relation("DoctorPrescriptions", fields: [doctorId], references: [id], onDelete: SetNull)
  medications Medication[]
  doseEvents  DoseEvent[]
  versions    PrescriptionVersion[]
  
  @@index([patientId])
  @@index([doctorId])
  @@index([status])
}

model PrescriptionVersion {
  id                  String   @id @default(uuid())
  prescriptionId      String
  versionNumber       Int
  authorId            String
  changeReason        String   @db.Text
  medicationsSnapshot Json
  createdAt           DateTime @default(now()) @db.Timestamptz
  
  // Relations
  prescription Prescription @relation(fields: [prescriptionId], references: [id], onDelete: Cascade)
  author       User         @relation(fields: [authorId], references: [id], onDelete: SetNull)
  
  @@index([prescriptionId])
}

model Medication {
  id                String   @id @default(uuid())
  prescriptionId    String
  rowNumber         Int
  medicineName      String
  medicineNameKhmer String
  morningDosage     Json?
  daytimeDosage     Json?
  nightDosage       Json?
  imageUrl          String?
  frequency         String
  timing            String
  createdAt         DateTime @default(now()) @db.Timestamptz
  updatedAt         DateTime @updatedAt @db.Timestamptz
  
  // Relations
  prescription Prescription @relation(fields: [prescriptionId], references: [id], onDelete: Cascade)
  doseEvents   DoseEvent[]
  
  @@index([prescriptionId])
}

model DoseEvent {
  id             String     @id @default(uuid())
  prescriptionId String
  medicationId   String
  patientId      String
  scheduledTime  DateTime   @db.Timestamptz
  timePeriod     TimePeriod
  status         DoseStatus @default(DUE)
  takenAt        DateTime?  @db.Timestamptz
  skipReason     String?    @db.Text
  reminderTime   String
  wasOffline     Boolean    @default(false)
  createdAt      DateTime   @default(now()) @db.Timestamptz
  updatedAt      DateTime   @updatedAt @db.Timestamptz
  
  // Relations
  prescription Prescription @relation(fields: [prescriptionId], references: [id], onDelete: Cascade)
  medication   Medication   @relation(fields: [medicationId], references: [id], onDelete: Cascade)
  patient      User         @relation(fields: [patientId], references: [id], onDelete: Cascade)
  
  @@index([patientId, scheduledTime])
  @@index([status])
}

model MealTimePreference {
  id            String   @id @default(uuid())
  userId        String   @unique
  morningMeal   String
  afternoonMeal String
  nightMeal     String
  createdAt     DateTime @default(now()) @db.Timestamptz
  updatedAt     DateTime @updatedAt @db.Timestamptz
  
  // Relations
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model AuditLog {
  id           String     @id @default(uuid())
  actorId      String?
  actorRole    UserRole
  actionType   ActionType
  resourceType String
  resourceId   String
  details      Json
  ipAddress    String
  createdAt    DateTime   @default(now()) @db.Timestamptz
  
  // Relations
  actor User? @relation(fields: [actorId], references: [id], onDelete: SetNull)
  
  @@index([actorId])
  @@index([resourceId])
  @@index([createdAt])
}

model Notification {
  id          String           @id @default(uuid())
  recipientId String
  type        NotificationType
  title       String
  message     String           @db.Text
  data        Json
  isRead      Boolean          @default(false)
  createdAt   DateTime         @default(now()) @db.Timestamptz
  readAt      DateTime?        @db.Timestamptz
  
  // Relations
  recipient User @relation(fields: [recipientId], references: [id], onDelete: Cascade)
  
  @@index([recipientId, isRead])
  @@index([createdAt])
}

model Subscription {
  id           String           @id @default(uuid())
  userId       String           @unique
  tier         SubscriptionTier @default(FREEMIUM)
  storageQuota BigInt           @default(5368709120) // 5GB in bytes
  storageUsed  BigInt           @default(0)
  expiresAt    DateTime?        @db.Timestamptz
  createdAt    DateTime         @default(now()) @db.Timestamptz
  updatedAt    DateTime         @updatedAt @db.Timestamptz
  
  // Relations
  user          User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  familyMembers FamilyMember[]
  
  @@index([userId])
  @@index([tier])
}

model FamilyMember {
  id             String       @id @default(uuid())
  subscriptionId String
  memberId       String
  addedAt        DateTime     @default(now()) @db.Timestamptz
  
  // Relations
  subscription Subscription @relation(fields: [subscriptionId], references: [id], onDelete: Cascade)
  
  @@unique([subscriptionId, memberId])
  @@index([subscriptionId])
}
```


### API Route Handlers (Next.js App Router)

```typescript
// app/api/auth/register/patient/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { patientRegistrationSchema } from '@/lib/validators/auth.validator';
import { AuthService } from '@/lib/services/auth.service';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validated = patientRegistrationSchema.parse(body);
    
    const authService = new AuthService();
    const result = await authService.registerPatient(validated);
    
    return NextResponse.json(result, { status: 201 });
  } catch (error) {
    return handleError(error);
  }
}

// app/api/prescriptions/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { prescriptionCreateSchema } from '@/lib/validators/prescription.validator';
import { PrescriptionService } from '@/lib/services/prescription.service';

export async function POST(request: NextRequest) {
  try {
    const session = await auth();
    if (!session || session.user.role !== 'DOCTOR') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }
    
    const body = await request.json();
    const validated = prescriptionCreateSchema.parse(body);
    
    const prescriptionService = new PrescriptionService();
    const prescription = await prescriptionService.createPrescription(
      session.user.id,
      validated
    );
    
    return NextResponse.json({ prescription }, { status: 201 });
  } catch (error) {
    return handleError(error);
  }
}

export async function GET(request: NextRequest) {
  try {
    const session = await auth();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    
    const { searchParams } = new URL(request.url);
    const filters = {
      patientId: searchParams.get('patientId'),
      status: searchParams.get('status'),
      page: parseInt(searchParams.get('page') || '1'),
      limit: parseInt(searchParams.get('limit') || '50')
    };
    
    const prescriptionService = new PrescriptionService();
    const result = await prescriptionService.getPrescriptions(
      session.user.id,
      filters
    );
    
    return NextResponse.json(result);
  } catch (error) {
    return handleError(error);
  }
}
```

### Service Layer Interfaces

```typescript
// lib/services/user.service.ts
import { PrismaClient, User, UserRole } from '@prisma/client';
import { RedisClient } from '@/lib/redis';
import { hashPassword, comparePassword } from '@/lib/utils/hash.util';

export class UserService {
  private prisma: PrismaClient;
  private redis: RedisClient;
  
  constructor() {
    this.prisma = new PrismaClient();
    this.redis = new RedisClient();
  }
  
  async getProfile(userId: string): Promise<UserProfile> {
    // Check cache first
    const cached = await this.redis.get(`user:profile:${userId}`);
    if (cached) {
      return JSON.parse(cached);
    }
    
    // Fetch from database
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        subscription: true,
        mealTimePreference: true
      }
    });
    
    if (!user) {
      throw new Error('User not found');
    }
    
    const profile = this.mapToUserProfile(user);
    
    // Cache for 5 minutes
    await this.redis.setex(
      `user:profile:${userId}`,
      300,
      JSON.stringify(profile)
    );
    
    return profile;
  }
  
  async updateProfile(
    userId: string,
    updates: Partial<User>
  ): Promise<User> {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: updates
    });
    
    // Invalidate cache
    await this.redis.del(`user:profile:${userId}`);
    
    return user;
  }
  
  async calculateStorageUsage(userId: string): Promise<StorageInfo> {
    const subscription = await this.prisma.subscription.findUnique({
      where: { userId }
    });
    
    if (!subscription) {
      throw new Error('Subscription not found');
    }
    
    return {
      used: Number(subscription.storageUsed),
      quota: Number(subscription.storageQuota),
      percentage: (Number(subscription.storageUsed) / Number(subscription.storageQuota)) * 100
    };
  }
  
  private mapToUserProfile(user: any): UserProfile {
    // Map database user to API response format
    return {
      id: user.id,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      email: user.email,
      language: user.language,
      theme: user.theme,
      subscriptionTier: user.subscription?.tier,
      storageUsed: Number(user.subscription?.storageUsed || 0),
      storageQuota: Number(user.subscription?.storageQuota || 0),
      storagePercentage: this.calculateStoragePercentage(user.subscription)
    };
  }
  
  private calculateStoragePercentage(subscription: any): number {
    if (!subscription) return 0;
    return (Number(subscription.storageUsed) / Number(subscription.storageQuota)) * 100;
  }
}

// lib/services/auth.service.ts
import { PrismaClient } from '@prisma/client';
import { RedisClient } from '@/lib/redis';
import { hashPassword, comparePassword } from '@/lib/utils/hash.util';
import { generateOTP, sendSMS } from '@/lib/utils/sms.util';
import { signJWT, verifyJWT } from '@/lib/utils/jwt.util';

export class AuthService {
  private prisma: PrismaClient;
  private redis: RedisClient;
  
  constructor() {
    this.prisma = new PrismaClient();
    this.redis = new RedisClient();
  }
  
  async registerPatient(data: PatientRegistrationData): Promise<RegistrationResult> {
    // Validate age
    const age = this.calculateAge(data.dateOfBirth);
    if (age < 13) {
      throw new Error('User must be at least 13 years old');
    }
    
    // Check if phone number exists
    const existing = await this.prisma.user.findUnique({
      where: { phoneNumber: data.phoneNumber }
    });
    
    if (existing) {
      throw new Error('Phone number already registered');
    }
    
    // Hash password and PIN
    const passwordHash = await hashPassword(data.password);
    const pinCodeHash = await hashPassword(data.pinCode);
    
    // Create user
    const user = await this.prisma.user.create({
      data: {
        role: 'PATIENT',
        firstName: data.firstName,
        lastName: data.lastName,
        phoneNumber: data.phoneNumber,
        passwordHash,
        pinCodeHash,
        gender: data.gender,
        dateOfBirth: new Date(data.dateOfBirth),
        idCardNumber: data.idCardNumber,
        language: 'KHMER',
        theme: 'LIGHT',
        accountStatus: 'ACTIVE'
      }
    });
    
    // Create default subscription
    await this.prisma.subscription.create({
      data: {
        userId: user.id,
        tier: 'FREEMIUM',
        storageQuota: 5368709120, // 5GB
        storageUsed: 0
      }
    });
    
    // Generate and send OTP
    const otp = generateOTP();
    await this.redis.setex(`otp:${data.phoneNumber}`, 300, otp); // 5 min expiry
    await sendSMS(data.phoneNumber, `Your Das Tern verification code is: ${otp}`);
    
    return {
      message: 'Registration successful. Please verify your phone number.',
      requiresOTP: true
    };
  }
  
  async verifyOTP(phoneNumber: string, otp: string): Promise<AuthTokens> {
    const storedOTP = await this.redis.get(`otp:${phoneNumber}`);
    
    if (!storedOTP || storedOTP !== otp) {
      throw new Error('Invalid or expired OTP');
    }
    
    // Delete OTP
    await this.redis.del(`otp:${phoneNumber}`);
    
    // Get user
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber },
      include: { subscription: true }
    });
    
    if (!user) {
      throw new Error('User not found');
    }
    
    // Generate tokens
    const accessToken = signJWT(
      {
        userId: user.id,
        role: user.role,
        subscriptionTier: user.subscription?.tier,
        language: user.language
      },
      '15m'
    );
    
    const refreshToken = signJWT(
      { userId: user.id },
      '7d'
    );
    
    // Store refresh token in Redis
    await this.redis.setex(
      `refresh:${user.id}`,
      604800, // 7 days
      refreshToken
    );
    
    return { accessToken, refreshToken, user };
  }
  
  async login(identifier: string, password: string): Promise<AuthTokens> {
    // Find user by phone or email
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { phoneNumber: identifier },
          { email: identifier }
        ]
      },
      include: { subscription: true }
    });
    
    if (!user) {
      throw new Error('Invalid credentials');
    }
    
    // Check if account is locked
    if (user.accountStatus === 'LOCKED' && user.lockedUntil) {
      if (new Date() < user.lockedUntil) {
        throw new Error('Account is locked. Please try again later.');
      } else {
        // Unlock account
        await this.prisma.user.update({
          where: { id: user.id },
          data: {
            accountStatus: 'ACTIVE',
            failedLoginAttempts: 0,
            lockedUntil: null
          }
        });
      }
    }
    
    // Verify password
    const isValid = await comparePassword(password, user.passwordHash);
    
    if (!isValid) {
      // Increment failed attempts
      const failedAttempts = user.failedLoginAttempts + 1;
      
      if (failedAttempts >= 5) {
        // Lock account for 15 minutes
        await this.prisma.user.update({
          where: { id: user.id },
          data: {
            accountStatus: 'LOCKED',
            failedLoginAttempts: failedAttempts,
            lockedUntil: new Date(Date.now() + 15 * 60 * 1000)
          }
        });
        throw new Error('Account locked due to too many failed attempts');
      }
      
      await this.prisma.user.update({
        where: { id: user.id },
        data: { failedLoginAttempts: failedAttempts }
      });
      
      throw new Error('Invalid credentials');
    }
    
    // Reset failed attempts
    await this.prisma.user.update({
      where: { id: user.id },
      data: { failedLoginAttempts: 0 }
    });
    
    // Generate tokens
    const accessToken = signJWT(
      {
        userId: user.id,
        role: user.role,
        subscriptionTier: user.subscription?.tier,
        language: user.language
      },
      '15m'
    );
    
    const refreshToken = signJWT(
      { userId: user.id },
      '7d'
    );
    
    // Store refresh token in Redis
    await this.redis.setex(
      `refresh:${user.id}`,
      604800, // 7 days
      refreshToken
    );
    
    return { accessToken, refreshToken, user };
  }
  
  private calculateAge(dateOfBirth: string): number {
    const today = new Date();
    const birthDate = new Date(dateOfBirth);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  }
}

// lib/services/prescription.service.ts
import { PrismaClient, Prescription, PrescriptionStatus } from '@prisma/client';
import { ConnectionService } from './connection.service';
import { DoseService } from './dose.service';
import { AuditService } from './audit.service';

export class PrescriptionService {
  private prisma: PrismaClient;
  private connectionService: ConnectionService;
  private doseService: DoseService;
  private auditService: AuditService;
  
  constructor() {
    this.prisma = new PrismaClient();
    this.connectionService = new ConnectionService();
    this.doseService = new DoseService();
    this.auditService = new AuditService();
  }
  
  async createPrescription(
    doctorId: string,
    data: PrescriptionCreateData
  ): Promise<Prescription> {
    // Validate connection and permission
    const hasPermission = await this.connectionService.validateAccess(
      doctorId,
      data.patientId,
      'ALLOWED'
    );
    
    if (!hasPermission) {
      throw new Error('Insufficient permissions to create prescription');
    }
    
    // Create prescription with medications in transaction
    const prescription = await this.prisma.$transaction(async (tx) => {
      const prescription = await tx.prescription.create({
        data: {
          patientId: data.patientId,
          doctorId,
          patientName: data.patientName,
          patientGender: data.patientGender,
          patientAge: data.patientAge,
          symptoms: data.symptoms,
          status: data.status || 'DRAFT',
          isUrgent: data.isUrgent || false,
          urgentReason: data.urgentReason,
          currentVersion: 1
        }
      });
      
      // Create medications
      await tx.medication.createMany({
        data: data.medications.map((med, index) => ({
          prescriptionId: prescription.id,
          rowNumber: index + 1,
          medicineName: med.medicineName,
          medicineNameKhmer: med.medicineNameKhmer || med.medicineName,
          morningDosage: med.morningDosage,
          daytimeDosage: med.daytimeDosage,
          nightDosage: med.nightDosage,
          imageUrl: med.imageUrl,
          frequency: med.frequency || 'DAILY',
          timing: med.timing || 'AFTER_MEAL'
        }))
      });
      
      // Create initial version
      await tx.prescriptionVersion.create({
        data: {
          prescriptionId: prescription.id,
          versionNumber: 1,
          authorId: doctorId,
          changeReason: 'Initial prescription',
          medicationsSnapshot: data.medications
        }
      });
      
      return prescription;
    });
    
    // If urgent or active, generate dose events
    if (prescription.status === 'ACTIVE' || prescription.isUrgent) {
      await this.doseService.generateDoseEvents(prescription.id);
    }
    
    // Audit log
    await this.auditService.logPrescriptionAction(
      doctorId,
      'PRESCRIPTION_CREATE',
      prescription.id,
      { isUrgent: prescription.isUrgent }
    );
    
    return prescription;
  }
  
  async updatePrescription(
    prescriptionId: string,
    doctorId: string,
    updates: PrescriptionUpdateData
  ): Promise<{ prescription: Prescription; newVersion: number }> {
    const prescription = await this.prisma.prescription.findUnique({
      where: { id: prescriptionId },
      include: { medications: true }
    });
    
    if (!prescription) {
      throw new Error('Prescription not found');
    }
    
    // Validate permission
    const hasPermission = await this.connectionService.validateAccess(
      doctorId,
      prescription.patientId,
      'ALLOWED'
    );
    
    if (!hasPermission) {
      throw new Error('Insufficient permissions');
    }
    
    // Create new version
    const newVersion = prescription.currentVersion + 1;
    
    const updated = await this.prisma.$transaction(async (tx) => {
      // Update prescription
      const updated = await tx.prescription.update({
        where: { id: prescriptionId },
        data: {
          ...updates,
          currentVersion: newVersion
        }
      });
      
      // Create version record
      await tx.prescriptionVersion.create({
        data: {
          prescriptionId,
          versionNumber: newVersion,
          authorId: doctorId,
          changeReason: updates.changeReason || 'Prescription updated',
          medicationsSnapshot: updates.medications || prescription.medications
        }
      });
      
      // If medications changed, update them
      if (updates.medications) {
        // Delete old medications
        await tx.medication.deleteMany({
          where: { prescriptionId }
        });
        
        // Create new medications
        await tx.medication.createMany({
          data: updates.medications.map((med, index) => ({
            prescriptionId,
            rowNumber: index + 1,
            medicineName: med.medicineName,
            medicineNameKhmer: med.medicineNameKhmer || med.medicineName,
            morningDosage: med.morningDosage,
            daytimeDosage: med.daytimeDosage,
            nightDosage: med.nightDosage,
            imageUrl: med.imageUrl,
            frequency: med.frequency || 'DAILY',
            timing: med.timing || 'AFTER_MEAL'
          }))
        });
      }
      
      return updated;
    });
    
    // If urgent, regenerate dose events
    if (updates.isUrgent) {
      await this.doseService.regenerateDoseEvents(prescriptionId);
    }
    
    // Audit log
    await this.auditService.logPrescriptionAction(
      doctorId,
      'PRESCRIPTION_UPDATE',
      prescriptionId,
      { newVersion, isUrgent: updates.isUrgent }
    );
    
    return { prescription: updated, newVersion };
  }
}
```


### Middleware Stack

```typescript
// lib/middleware/auth.middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { verifyJWT } from '@/lib/utils/jwt.util';

export async function authMiddleware(request: NextRequest) {
  const authHeader = request.headers.get('authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return NextResponse.json(
      { error: { code: 'UNAUTHORIZED', message: 'Missing or invalid authorization header' } },
      { status: 401 }
    );
  }
  
  const token = authHeader.substring(7);
  
  try {
    const payload = verifyJWT(token);
    
    // Attach user info to request
    request.headers.set('x-user-id', payload.userId);
    request.headers.set('x-user-role', payload.role);
    request.headers.set('x-user-language', payload.language);
    
    return NextResponse.next();
  } catch (error) {
    return NextResponse.json(
      { error: { code: 'INVALID_TOKEN', message: 'Invalid or expired token' } },
      { status: 401 }
    );
  }
}

// lib/middleware/rate-limit.middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { RedisClient } from '@/lib/redis';

export async function rateLimitMiddleware(
  request: NextRequest,
  limit: number,
  window: number // seconds
) {
  const redis = new RedisClient();
  const userId = request.headers.get('x-user-id');
  const ip = request.ip || 'unknown';
  const key = `rate-limit:${userId || ip}:${request.nextUrl.pathname}`;
  
  const current = await redis.incr(key);
  
  if (current === 1) {
    await redis.expire(key, window);
  }
  
  if (current > limit) {
    const ttl = await redis.ttl(key);
    
    return NextResponse.json(
      { error: { code: 'RATE_LIMIT_EXCEEDED', message: 'Too many requests' } },
      {
        status: 429,
        headers: {
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': (Date.now() + ttl * 1000).toString(),
          'Retry-After': ttl.toString()
        }
      }
    );
  }
  
  const response = NextResponse.next();
  response.headers.set('X-RateLimit-Limit', limit.toString());
  response.headers.set('X-RateLimit-Remaining', (limit - current).toString());
  
  return response;
}

// lib/middleware/validation.middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { ZodSchema } from 'zod';

export function validationMiddleware(schema: ZodSchema) {
  return async (request: NextRequest) => {
    try {
      const body = await request.json();
      const validated = schema.parse(body);
      
      // Attach validated data to request
      request.headers.set('x-validated-body', JSON.stringify(validated));
      
      return NextResponse.next();
    } catch (error) {
      if (error instanceof ZodError) {
        return NextResponse.json(
          {
            error: {
              code: 'VALIDATION_ERROR',
              message: 'Invalid request data',
              details: error.errors
            }
          },
          { status: 400 }
        );
      }
      
      throw error;
    }
  };
}

// lib/middleware/error-handler.middleware.ts
import { NextResponse } from 'next/server';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';

export function handleError(error: unknown) {
  console.error('API Error:', error);
  
  // Prisma errors
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      return NextResponse.json(
        {
          error: {
            code: 'UNIQUE_CONSTRAINT_VIOLATION',
            message: 'A record with this value already exists',
            details: error.meta
          }
        },
        { status: 409 }
      );
    }
    
    if (error.code === 'P2025') {
      return NextResponse.json(
        {
          error: {
            code: 'NOT_FOUND',
            message: 'Record not found',
            details: error.meta
          }
        },
        { status: 404 }
      );
    }
  }
  
  // Zod validation errors
  if (error instanceof ZodError) {
    return NextResponse.json(
      {
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request data',
          details: error.errors
        }
      },
      { status: 400 }
    );
  }
  
  // Custom application errors
  if (error instanceof Error) {
    if (error.message.includes('Unauthorized') || error.message.includes('permissions')) {
      return NextResponse.json(
        {
          error: {
            code: 'FORBIDDEN',
            message: error.message
          }
        },
        { status: 403 }
      );
    }
    
    if (error.message.includes('not found')) {
      return NextResponse.json(
        {
          error: {
            code: 'NOT_FOUND',
            message: error.message
          }
        },
        { status: 404 }
      );
    }
  }
  
  // Generic server error
  return NextResponse.json(
    {
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred'
      }
    },
    { status: 500 }
  );
}

// lib/middleware/audit-logger.middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { AuditService } from '@/lib/services/audit.service';

export async function auditLoggerMiddleware(request: NextRequest) {
  const userId = request.headers.get('x-user-id');
  const userRole = request.headers.get('x-user-role');
  const method = request.method;
  const path = request.nextUrl.pathname;
  
  // Only log mutations (POST, PUT, PATCH, DELETE)
  if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
    const auditService = new AuditService();
    
    // Extract resource info from path
    const resourceMatch = path.match(/\/api\/([^\/]+)\/([^\/]+)?/);
    const resourceType = resourceMatch?.[1] || 'unknown';
    const resourceId = resourceMatch?.[2] || 'unknown';
    
    await auditService.log({
      actorId: userId || null,
      actorRole: userRole as any || 'SYSTEM',
      actionType: `${resourceType.toUpperCase()}_${method}` as any,
      resourceType,
      resourceId,
      details: {
        path,
        method,
        timestamp: new Date().toISOString()
      },
      ipAddress: request.ip || 'unknown'
    });
  }
  
  return NextResponse.next();
}
```

### Validation Schemas (Zod)

```typescript
// lib/validators/auth.validator.ts
import { z } from 'zod';

export const patientRegistrationSchema = z.object({
  lastName: z.string().min(1, 'Last name is required'),
  firstName: z.string().min(1, 'First name is required'),
  gender: z.enum(['MALE', 'FEMALE', 'OTHER']),
  dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Invalid date format'),
  idCardNumber: z.string().min(1, 'ID card number is required'),
  phoneNumber: z.string().regex(/^\+855\d{8,9}$/, 'Invalid Cambodia phone number'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  pinCode: z.string().regex(/^\d{4}$/, 'PIN code must be exactly 4 digits')
}).refine((data) => {
  const age = calculateAge(data.dateOfBirth);
  return age >= 13;
}, {
  message: 'User must be at least 13 years old',
  path: ['dateOfBirth']
});

export const doctorRegistrationSchema = z.object({
  fullName: z.string().min(1, 'Full name is required'),
  phoneNumber: z.string().regex(/^\+855\d{8,9}$/, 'Invalid Cambodia phone number'),
  hospitalClinic: z.string().min(1, 'Hospital/clinic name is required'),
  specialty: z.enum([
    'GENERAL_PRACTICE',
    'INTERNAL_MEDICINE',
    'CARDIOLOGY',
    'ENDOCRINOLOGY',
    'OTHER'
  ]),
  licenseNumber: z.string().min(1, 'License number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters')
});

export const loginSchema = z.object({
  identifier: z.string().min(1, 'Phone number or email is required'),
  password: z.string().min(1, 'Password is required')
});

export const otpVerifySchema = z.object({
  phoneNumber: z.string().regex(/^\+855\d{8,9}$/, 'Invalid Cambodia phone number'),
  otp: z.string().regex(/^\d{4}$/, 'OTP must be 4 digits')
});

// lib/validators/prescription.validator.ts
import { z } from 'zod';

const dosageSchema = z.object({
  amount: z.string(),
  beforeMeal: z.boolean()
}).optional();

const medicationSchema = z.object({
  medicineName: z.string().min(1, 'Medicine name is required'),
  medicineNameKhmer: z.string().optional(),
  morningDosage: dosageSchema,
  daytimeDosage: dosageSchema,
  nightDosage: dosageSchema,
  imageUrl: z.string().url().optional(),
  frequency: z.string().default('DAILY'),
  timing: z.string().default('AFTER_MEAL')
});

export const prescriptionCreateSchema = z.object({
  patientId: z.string().uuid('Invalid patient ID'),
  patientName: z.string().min(1, 'Patient name is required'),
  patientGender: z.string(),
  patientAge: z.number().int().positive(),
  symptoms: z.string().min(1, 'Symptoms are required'),
  medications: z.array(medicationSchema).min(1, 'At least one medication is required'),
  status: z.enum(['DRAFT', 'ACTIVE']).default('DRAFT'),
  isUrgent: z.boolean().default(false),
  urgentReason: z.string().optional()
});

export const prescriptionUpdateSchema = z.object({
  symptoms: z.string().optional(),
  medications: z.array(medicationSchema).optional(),
  status: z.enum(['DRAFT', 'ACTIVE', 'PAUSED', 'INACTIVE']).optional(),
  isUrgent: z.boolean().optional(),
  urgentReason: z.string().optional(),
  changeReason: z.string().optional()
});

// lib/validators/dose.validator.ts
import { z } from 'zod';

export const markDoseTakenSchema = z.object({
  takenAt: z.string().datetime().optional(),
  offline: z.boolean().default(false)
});

export const skipDoseSchema = z.object({
  reason: z.string().min(1, 'Reason is required')
});

export const updateReminderTimeSchema = z.object({
  reminderTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:mm)')
});
```


## Data Models

### TypeScript Type Definitions

```typescript
// lib/types/api.types.ts

export interface UserProfile {
  id: string;
  role: 'PATIENT' | 'DOCTOR' | 'FAMILY_MEMBER';
  firstName?: string;
  lastName?: string;
  fullName?: string;
  phoneNumber: string;
  email?: string;
  language: 'KHMER' | 'ENGLISH';
  theme: 'LIGHT' | 'DARK';
  subscriptionTier?: 'FREEMIUM' | 'PREMIUM' | 'FAMILY_PREMIUM';
  storageUsed: number;
  storageQuota: number;
  storagePercentage: number;
  dailyProgress?: number;
  hospitalClinic?: string;
  specialty?: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: UserProfile;
}

export interface StorageInfo {
  used: number;
  quota: number;
  percentage: number;
  breakdown?: {
    prescriptions: number;
    doseEvents: number;
    auditLogs: number;
    files: number;
  };
}

export interface PrescriptionCreateData {
  patientId: string;
  patientName: string;
  patientGender: string;
  patientAge: number;
  symptoms: string;
  medications: MedicationData[];
  status?: 'DRAFT' | 'ACTIVE';
  isUrgent?: boolean;
  urgentReason?: string;
}

export interface MedicationData {
  medicineName: string;
  medicineNameKhmer?: string;
  morningDosage?: { amount: string; beforeMeal: boolean };
  daytimeDosage?: { amount: string; beforeMeal: boolean };
  nightDosage?: { amount: string; beforeMeal: boolean };
  imageUrl?: string;
  frequency?: string;
  timing?: string;
}

export interface MedicationSchedule {
  date: string;
  dailyProgress: number;
  groups: {
    period: 'DAYTIME' | 'NIGHT';
    color: string;
    doses: DoseInfo[];
  }[];
}

export interface DoseInfo {
  id: string;
  medicationName: string;
  medicationNameKhmer: string;
  dosage: string;
  quantity: string;
  imageUrl?: string;
  scheduledTime: string;
  status: 'DUE' | 'TAKEN_ON_TIME' | 'TAKEN_LATE' | 'MISSED' | 'SKIPPED';
  frequency: string;
  timing: string;
  reminderTime: string;
}

export interface SyncAction {
  type: 'DOSE_TAKEN' | 'DOSE_SKIPPED' | 'PRESCRIPTION_UPDATED';
  entityId: string;
  timestamp: string;
  data: Record<string, any>;
}

export interface SyncResult {
  applied: number;
  conflicts: {
    actionIndex: number;
    reason: string;
    serverState: any;
  }[];
  summary: {
    dosesTaken: number;
    dosesSkipped: number;
    missedDosesDetected: number;
  };
}

export interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: any;
  };
}
```

### Database Connection Configuration

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
    datasources: {
      db: {
        url: process.env.DATABASE_URL
      }
    }
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

// Middleware for automatic audit logging
prisma.$use(async (params, next) => {
  const result = await next(params);
  
  // Log all mutations
  if (['create', 'update', 'delete', 'createMany', 'updateMany', 'deleteMany'].includes(params.action)) {
    // Audit logging logic here
    console.log(`[Prisma Audit] ${params.model}.${params.action}`, params.args);
  }
  
  return result;
});

export default prisma;

// lib/redis.ts
import { createClient } from 'redis';

const globalForRedis = global as unknown as { redis: ReturnType<typeof createClient> };

export const redis =
  globalForRedis.redis ||
  createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379',
    socket: {
      reconnectStrategy: (retries) => {
        if (retries > 10) {
          return new Error('Redis connection failed after 10 retries');
        }
        return retries * 100;
      }
    }
  });

redis.on('error', (err) => console.error('Redis Client Error', err));
redis.on('connect', () => console.log('Redis Client Connected'));

if (!redis.isOpen) {
  redis.connect();
}

if (process.env.NODE_ENV !== 'production') globalForRedis.redis = redis;

export class RedisClient {
  async get(key: string): Promise<string | null> {
    return await redis.get(key);
  }
  
  async set(key: string, value: string): Promise<void> {
    await redis.set(key, value);
  }
  
  async setex(key: string, seconds: number, value: string): Promise<void> {
    await redis.setEx(key, seconds, value);
  }
  
  async del(key: string): Promise<void> {
    await redis.del(key);
  }
  
  async incr(key: string): Promise<number> {
    return await redis.incr(key);
  }
  
  async expire(key: string, seconds: number): Promise<void> {
    await redis.expire(key, seconds);
  }
  
  async ttl(key: string): Promise<number> {
    return await redis.ttl(key);
  }
}

export default redis;
```

### NextAuth Configuration

```typescript
// lib/auth.ts
import NextAuth from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import GoogleProvider from 'next-auth/providers/google';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { prisma } from '@/lib/prisma';
import { comparePassword } from '@/lib/utils/hash.util';

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  session: {
    strategy: 'jwt',
    maxAge: 7 * 24 * 60 * 60 // 7 days
  },
  jwt: {
    maxAge: 15 * 60 // 15 minutes for access token
  },
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        identifier: { label: 'Phone or Email', type: 'text' },
        password: { label: 'Password', type: 'password' }
      },
      async authorize(credentials) {
        if (!credentials?.identifier || !credentials?.password) {
          return null;
        }
        
        const user = await prisma.user.findFirst({
          where: {
            OR: [
              { phoneNumber: credentials.identifier as string },
              { email: credentials.identifier as string }
            ]
          },
          include: { subscription: true }
        });
        
        if (!user) {
          return null;
        }
        
        const isValid = await comparePassword(
          credentials.password as string,
          user.passwordHash
        );
        
        if (!isValid) {
          return null;
        }
        
        return {
          id: user.id,
          role: user.role,
          name: user.fullName || `${user.firstName} ${user.lastName}`,
          email: user.email,
          phoneNumber: user.phoneNumber,
          language: user.language,
          subscriptionTier: user.subscription?.tier
        };
      }
    }),
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      authorization: {
        params: {
          prompt: 'consent',
          access_type: 'offline',
          response_type: 'code'
        }
      }
    })
  ],
  callbacks: {
    async jwt({ token, user, account }) {
      if (user) {
        token.userId = user.id;
        token.role = user.role;
        token.language = user.language;
        token.subscriptionTier = user.subscriptionTier;
      }
      
      return token;
    },
    async session({ session, token }) {
      if (token) {
        session.user.id = token.userId as string;
        session.user.role = token.role as string;
        session.user.language = token.language as string;
        session.user.subscriptionTier = token.subscriptionTier as string;
      }
      
      return session;
    },
    async signIn({ user, account, profile }) {
      // Handle Google OAuth sign-in
      if (account?.provider === 'google') {
        const existingUser = await prisma.user.findUnique({
          where: { email: user.email! }
        });
        
        if (!existingUser) {
          // Create new user from Google profile
          const newUser = await prisma.user.create({
            data: {
              email: user.email!,
              fullName: user.name!,
              role: 'PATIENT',
              language: 'ENGLISH',
              theme: 'LIGHT',
              accountStatus: 'ACTIVE',
              passwordHash: '', // No password for OAuth users
              phoneNumber: '' // Will be set later
            }
          });
          
          // Create default subscription
          await prisma.subscription.create({
            data: {
              userId: newUser.id,
              tier: 'FREEMIUM',
              storageQuota: 5368709120,
              storageUsed: 0
            }
          });
        }
      }
      
      return true;
    }
  },
  pages: {
    signIn: '/auth/login',
    error: '/auth/error'
  }
});
```

### Utility Functions

```typescript
// lib/utils/hash.util.ts
import bcrypt from 'bcryptjs';

export async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, 10);
}

export async function comparePassword(
  password: string,
  hash: string
): Promise<boolean> {
  return await bcrypt.compare(password, hash);
}

// lib/utils/jwt.util.ts
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.NEXTAUTH_SECRET || 'your-secret-key';

export function signJWT(payload: any, expiresIn: string): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

export function verifyJWT(token: string): any {
  return jwt.verify(token, JWT_SECRET);
}

// lib/utils/timezone.util.ts
import { zonedTimeToUtc, utcToZonedTime, format } from 'date-fns-tz';

const CAMBODIA_TIMEZONE = 'Asia/Phnom_Penh';

export function toCambodiaTime(date: Date): Date {
  return utcToZonedTime(date, CAMBODIA_TIMEZONE);
}

export function fromCambodiaTime(date: Date): Date {
  return zonedTimeToUtc(date, CAMBODIA_TIMEZONE);
}

export function formatCambodiaTime(date: Date, formatStr: string): string {
  return format(toCambodiaTime(date), formatStr, { timeZone: CAMBODIA_TIMEZONE });
}

// lib/utils/language.util.ts
export function getErrorMessage(
  code: string,
  language: 'KHMER' | 'ENGLISH'
): string {
  const messages: Record<string, Record<string, string>> = {
    UNAUTHORIZED: {
      KHMER: 'អ្នកមិនមានសិទ្ធិចូលប្រើប្រាស់',
      ENGLISH: 'Unauthorized access'
    },
    VALIDATION_ERROR: {
      KHMER: 'ទិន្នន័យមិនត្រឹមត្រូវ',
      ENGLISH: 'Invalid data'
    },
    NOT_FOUND: {
      KHMER: 'រកមិនឃើញ',
      ENGLISH: 'Not found'
    }
    // Add more translations
  };
  
  return messages[code]?.[language] || messages[code]?.['ENGLISH'] || 'Unknown error';
}
```


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Database Persistence Across Restarts

*For any* data written to the PostgreSQL database, restarting the Docker container should preserve all data without loss.

**Validates: Requirements 1.2**

### Property 2: Redis TTL Expiration

*For any* key stored in Redis with a TTL (refresh tokens, OTP codes, cache entries), the key should automatically expire and become inaccessible after the specified time period.

**Validates: Requirements 2.2, 15.6, 34.3**

### Property 3: Prisma Transaction Atomicity

*For any* multi-step database operation wrapped in a Prisma transaction, if any step fails, all previous steps should be rolled back, leaving the database in its original state.

**Validates: Requirements 3.8**

### Property 4: Database Unique Constraints

*For any* attempt to insert duplicate values into unique-constrained columns (phoneNumber, email), the database should reject the insertion and return a unique constraint violation error.

**Validates: Requirements 4.3, 4.4, 27.2**

### Property 5: Token Rotation on Refresh

*For any* valid refresh token used to obtain a new access token, the system should issue both a new access token and a new refresh token, invalidating the old refresh token.

**Validates: Requirements 15.11**

### Property 6: Token Invalidation on Password Change

*For any* user who changes their password, all existing JWT tokens (access and refresh) for that user should be immediately invalidated and rejected on subsequent requests.

**Validates: Requirements 15.12**

### Property 7: Google OAuth User Creation

*For any* Google sign-in with an email that doesn't exist in the system, the backend should create a new user account with role PATIENT, language ENGLISH, and subscription tier FREEMIUM.

**Validates: Requirements 16.3**

### Property 8: Google OAuth Account Linking

*For any* Google sign-in with an email that already exists in the system, the backend should link the Google account to the existing user without creating a duplicate.

**Validates: Requirements 16.4**

### Property 9: Input Validation Rules

*For any* API request with input data, the Zod validators should enforce all validation rules (phone format +855, password min 6 chars, PIN exactly 4 digits, age >= 13) and reject invalid inputs with field-level error details.

**Validates: Requirements 17.2, 17.4, 17.5, 17.11**

### Property 10: Protected Route Authentication

*For any* request to a protected API endpoint without a valid JWT token, the authentication middleware should reject the request with HTTP 401 Unauthorized.

**Validates: Requirements 18.1**

### Property 11: Rate Limiting Enforcement

*For any* user or IP address exceeding the configured rate limit (5 req/min for auth, 100 req/min for API), the system should return HTTP 429 with retry-after header and block further requests until the window resets.

**Validates: Requirements 18.7, 20.2, 20.4, 20.6**

### Property 12: Error Code Mapping

*For any* Prisma error (NotFound, UniqueConstraint) or Zod validation error, the error handler should map it to the appropriate HTTP status code (404, 409, 400) with consistent error response format.

**Validates: Requirements 19.3, 19.4**

### Property 13: Cache Invalidation on Mutation

*For any* data mutation (create, update, delete) on a cached resource, the system should immediately invalidate the corresponding cache entry in Redis.

**Validates: Requirements 21.5**

### Property 14: Foreign Key Cascade Behavior

*For any* parent record deletion with CASCADE foreign key constraints, all child records should be automatically deleted, maintaining referential integrity.

**Validates: Requirements 27.3**

### Property 15: Unicode Text Preservation

*For any* Khmer text stored in VARCHAR or TEXT columns, retrieving the text should return exactly the same Unicode characters without corruption or data loss.

**Validates: Requirements 28.2**

### Property 16: Timezone Conversion Consistency

*For any* timestamp received by the API, the system should convert it to Cambodia timezone (Asia/Phnom_Penh UTC+7) before storage and return it in ISO 8601 format with timezone offset.

**Validates: Requirements 29.3**

### Property 17: Password and PIN Hashing

*For any* user registration or password/PIN change, the system should hash the password and PIN using bcrypt with 10 salt rounds, never storing plaintext credentials.

**Validates: Requirements 32.1, 32.2**

### Property 18: Account Lockout After Failed Attempts

*For any* user with 5 consecutive failed login attempts, the system should lock the account for 15 minutes and reject all login attempts during the lockout period.

**Validates: Requirements 32.11**

### Property 19: File Upload Validation

*For any* file upload request, the system should validate file type (JPEG, PNG, PDF) and size (max 5MB for images, 10MB for PDFs), rejecting files that don't meet the criteria.

**Validates: Requirements 33.4, 33.5**

### Property 20: OTP Resend Cooldown

*For any* OTP resend request within 60 seconds of the previous request for the same phone number, the system should reject the request and enforce the cooldown period.

**Validates: Requirements 34.4**

### Property 21: N+1 Query Prevention

*For any* API endpoint that returns related data (e.g., prescriptions with medications), the system should use Prisma's include or eager loading to fetch all data in a single query or minimal queries, avoiding N+1 patterns.

**Validates: Requirements 38.3**

### Property 22: Subscription Upgrade Storage Quota

*For any* user upgrading from FREEMIUM to PREMIUM or FAMILY_PREMIUM, the system should immediately increase the storage quota from 5GB to 20GB.

**Validates: Requirements 40.2, 40.3**

## Error Handling

### Error Response Format

All API errors follow a consistent JSON format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      // Optional additional context
    }
  }
}
```

### Error Categories

1. **Authentication Errors (401)**
   - Missing or invalid JWT token
   - Expired token
   - Invalid credentials

2. **Authorization Errors (403)**
   - Insufficient permissions
   - Account not verified
   - Feature not available in subscription tier

3. **Validation Errors (400)**
   - Invalid input format
   - Missing required fields
   - Business rule violations

4. **Not Found Errors (404)**
   - Resource doesn't exist
   - User not found
   - Prescription not found

5. **Conflict Errors (409)**
   - Unique constraint violation
   - Duplicate phone number or email
   - Connection already exists

6. **Rate Limit Errors (429)**
   - Too many requests
   - Includes retry-after header

7. **Server Errors (500)**
   - Unexpected database errors
   - External service failures
   - Unhandled exceptions

### Multi-Language Error Messages

All error messages are translated based on the user's language preference (Khmer or English). The `getErrorMessage` utility function provides translations for common error codes.

## Testing Strategy

### Dual Testing Approach

The backend requires both unit tests and property-based tests for comprehensive coverage:

**Unit Tests:**
- Test specific API endpoints with known inputs and expected outputs
- Test middleware functions (auth, validation, rate limiting)
- Test service layer methods with mocked dependencies
- Test error handling for specific error cases
- Test database migrations and seeding
- Test utility functions (hashing, timezone conversion, JWT)

**Property-Based Tests:**
- Test universal properties across all inputs (see Correctness Properties section)
- Generate random valid and invalid inputs to test validation
- Test database constraints with random data
- Test rate limiting with varying request patterns
- Test caching behavior with random cache operations
- Test timezone conversion with random timestamps
- Minimum 100 iterations per property test

### Testing Tools

- **Test Framework**: Jest or Vitest
- **Property-Based Testing**: fast-check (JavaScript/TypeScript)
- **Database Testing**: Separate test database with Prisma migrations
- **API Testing**: Supertest for HTTP endpoint testing
- **Mocking**: Jest mocks for external services (SMS, S3)

### Test Configuration

Each property-based test must:
1. Run minimum 100 iterations
2. Reference the design document property number
3. Use tag format: `Feature: das-tern-backend-database, Property {number}: {property_text}`

Example:
```typescript
// Feature: das-tern-backend-database, Property 4: Database Unique Constraints
test('unique constraints prevent duplicate phone numbers', async () => {
  await fc.assert(
    fc.asyncProperty(fc.string(), async (phoneNumber) => {
      // Test implementation
    }),
    { numRuns: 100 }
  );
});
```

### Test Coverage Goals

- Service layer: 80% minimum coverage
- API routes: 80% minimum coverage
- Middleware: 90% minimum coverage
- Utility functions: 90% minimum coverage
- Overall: 80% minimum coverage

## Deployment

### Docker Compose (Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: das-tern-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      TZ: Asia/Phnom_Penh
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: das-tern-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

### Environment Variables

```bash
# .env.example

# Database
DATABASE_URL="postgresql://user:password@localhost:5432/das_tern"

# Redis
REDIS_URL="redis://localhost:6379"

# NextAuth
NEXTAUTH_SECRET="your-secret-key-here"
NEXTAUTH_URL="http://localhost:3000"

# Google OAuth
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"

# SMS Provider (Twilio)
TWILIO_ACCOUNT_SID="your-twilio-sid"
TWILIO_AUTH_TOKEN="your-twilio-token"
TWILIO_PHONE_NUMBER="+1234567890"

# AWS S3
AWS_S3_BUCKET="das-tern-uploads"
AWS_ACCESS_KEY_ID="your-aws-key"
AWS_SECRET_ACCESS_KEY="your-aws-secret"
AWS_REGION="ap-southeast-1"

# Application
NODE_ENV="development"
PORT=3000
```

### Production Deployment

The backend can be deployed to:
- **Vercel**: Recommended for Next.js applications
- **AWS ECS/Fargate**: For containerized deployment
- **Docker**: Self-hosted with Docker Compose

**Production Checklist:**
1. Set `NODE_ENV=production`
2. Use strong `NEXTAUTH_SECRET`
3. Configure production database URL
4. Enable HTTPS only
5. Set up database backups
6. Configure monitoring and logging
7. Set up CI/CD pipeline
8. Run database migrations before deployment
9. Configure CORS for production frontend domain
10. Set up health checks and auto-scaling

### Database Migrations

```bash
# Generate migration
npx prisma migrate dev --name migration_name

# Apply migrations (production)
npx prisma migrate deploy

# Reset database (development only)
npx prisma migrate reset

# Seed database
npx prisma db seed
```

### Backup and Restore

```bash
# Backup database
pg_dump -h localhost -U user -d das_tern -F c -f backup_$(date +%Y%m%d_%H%M%S).dump

# Restore database
pg_restore -h localhost -U user -d das_tern -c backup_file.dump
```
