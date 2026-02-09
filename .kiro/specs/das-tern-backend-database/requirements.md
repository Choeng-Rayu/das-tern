# Requirements Document: Das Tern Backend and Database

## Introduction

The Das Tern Backend and Database system provides the complete server-side infrastructure for a patient-centered medication management platform. The system consists of a Next.js 14+ TypeScript backend API with PostgreSQL 16 database, Prisma ORM for type-safe database access, Redis for caching and session management, NextAuth.js for authentication, and Zod for runtime validation. The system supports three user roles (Patient, Doctor, Family), manages prescriptions with version control, handles offline-first synchronization, enforces subscription-based storage quotas, and maintains comprehensive audit trails with multi-language support (Khmer and English).

## Glossary

- **Backend**: The Next.js 14+ TypeScript server application providing REST API endpoints
- **Database**: PostgreSQL 16 relational database storing all persistent application data
- **Prisma**: TypeScript ORM providing type-safe database access and migrations
- **Redis**: In-memory data store used for caching, session management, and rate limiting
- **NextAuth**: Authentication library for Next.js handling OAuth and JWT tokens
- **Zod**: TypeScript schema validation library for runtime type checking
- **Docker**: Containerization platform for running PostgreSQL and Redis
- **Patient**: Primary user and owner of all medical data
- **Doctor**: Healthcare provider who can create and modify prescriptions with patient permission
- **Family_Member**: Caregiver who receives alerts and can view patient data with permission
- **Prescription**: Medication schedule with lifecycle states (Draft, Active, Paused, Inactive)
- **DoseEvent**: Individual scheduled medication dose with tracking status
- **Connection**: Bidirectional relationship between users requiring mutual acceptance
- **Permission_Level**: Access control enum (NOT_ALLOWED, REQUEST, SELECTED, ALLOWED)
- **Subscription_Tier**: Plan level (FREEMIUM, PREMIUM, FAMILY_PREMIUM)
- **Audit_Log**: Immutable record of all system actions for transparency
- **Storage_Quota**: Maximum data storage per subscription tier (5GB or 20GB)
- **Cambodia_Time**: Asia/Phnom_Penh timezone (UTC+7), system default
- **JWT**: JSON Web Token for stateless authentication
- **OAuth**: Open Authorization protocol for third-party authentication (Google)
- **Migration**: Database schema version control managed by Prisma
- **Seed_Data**: Initial database records for development and testing

## Requirements

### Requirement 1: Database Infrastructure Setup

**User Story:** As a system administrator, I want a containerized PostgreSQL database with proper configuration, so that the application has reliable and reproducible data storage.

#### Acceptance Criteria

1. THE Database SHALL run PostgreSQL version 16 or higher in a Docker container
2. THE Database SHALL use a persistent volume for data storage to survive container restarts
3. THE Database SHALL be configured with environment variables for database name, username, and password
4. THE Database SHALL expose port 5432 for local development access
5. THE Database SHALL use UTF-8 encoding to support Khmer and English characters
6. THE Database SHALL set timezone to Asia/Phnom_Penh (UTC+7) as default
7. THE Database SHALL enable connection pooling with a maximum of 20 concurrent connections
8. THE Database SHALL log slow queries exceeding 1000ms for performance monitoring

### Requirement 2: Redis Cache Infrastructure

**User Story:** As a system administrator, I want a Redis cache for session management and performance optimization, so that the application responds quickly and scales efficiently.

#### Acceptance Criteria

1. THE Backend SHALL run Redis version 7 or higher in a Docker container
2. THE Backend SHALL use Redis for storing JWT refresh tokens with automatic expiration
3. THE Backend SHALL use Redis for caching frequently accessed data with TTL (Time To Live) of 5 minutes
4. THE Backend SHALL use Redis for rate limiting with sliding window algorithm
5. THE Backend SHALL use Redis for storing OTP codes with 5-minute expiration
6. THE Backend SHALL use Redis for session storage with 7-day expiration for "remember me" functionality
7. THE Backend SHALL configure Redis with maxmemory policy "allkeys-lru" for automatic eviction
8. THE Backend SHALL expose Redis on port 6379 for local development access

### Requirement 3: Prisma ORM Integration

**User Story:** As a backend developer, I want type-safe database access through Prisma ORM, so that database operations are reliable and maintainable.

#### Acceptance Criteria

1. THE Backend SHALL use Prisma Client for all database operations with full TypeScript type safety
2. THE Backend SHALL define the complete database schema in schema.prisma file
3. THE Backend SHALL use Prisma Migrate for database schema version control and migrations
4. THE Backend SHALL generate Prisma Client types automatically after schema changes
5. THE Backend SHALL use Prisma's connection pooling with pool size of 10 connections
6. THE Backend SHALL use Prisma's query logging in development mode for debugging
7. THE Backend SHALL use Prisma's middleware for automatic audit logging of all mutations
8. THE Backend SHALL use Prisma's transaction API for operations requiring atomicity
9. THE Backend SHALL define all enums in Prisma schema matching TypeScript type definitions
10. THE Backend SHALL use Prisma's cascading deletes for parent-child relationships

### Requirement 4: Database Schema - User Table

**User Story:** As a system architect, I want a comprehensive user table supporting all three roles, so that authentication and profile management work correctly.

#### Acceptance Criteria

1. THE Database SHALL have a User table with UUID primary key
2. THE User table SHALL have columns: id, role, firstName, lastName, fullName, phoneNumber, email, passwordHash, pinCodeHash, gender, dateOfBirth, idCardNumber, language, theme, hospitalClinic, specialty, licenseNumber, licensePhotoUrl, accountStatus, failedLoginAttempts, lockedUntil, createdAt, updatedAt
3. THE User table SHALL enforce unique constraint on phoneNumber
4. THE User table SHALL enforce unique constraint on email when not null
5. THE User table SHALL use enum type for role: PATIENT, DOCTOR, FAMILY_MEMBER
6. THE User table SHALL use enum type for gender: MALE, FEMALE, OTHER
7. THE User table SHALL use enum type for language: KHMER, ENGLISH with default KHMER
8. THE User table SHALL use enum type for theme: LIGHT, DARK with default LIGHT
9. THE User table SHALL use enum type for accountStatus: ACTIVE, PENDING_VERIFICATION, VERIFIED, REJECTED, LOCKED
10. THE User table SHALL index phoneNumber and email columns for fast lookup
11. THE User table SHALL use TIMESTAMP WITH TIME ZONE for createdAt and updatedAt

### Requirement 5: Database Schema - Connection Table

**User Story:** As a system architect, I want a connection table managing relationships between users, so that doctor-patient and family-patient connections work correctly.

#### Acceptance Criteria

1. THE Database SHALL have a Connection table with UUID primary key
2. THE Connection table SHALL have columns: id, initiatorId, recipientId, status, permissionLevel, requestedAt, acceptedAt, revokedAt, createdAt, updatedAt
3. THE Connection table SHALL have foreign key initiatorId referencing User(id) with CASCADE delete
4. THE Connection table SHALL have foreign key recipientId referencing User(id) with CASCADE delete
5. THE Connection table SHALL use enum type for status: PENDING, ACCEPTED, REVOKED
6. THE Connection table SHALL use enum type for permissionLevel: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED with default ALLOWED
7. THE Connection table SHALL enforce unique constraint on (initiatorId, recipientId) pair to prevent duplicates
8. THE Connection table SHALL index initiatorId and recipientId for fast relationship queries
9. THE Connection table SHALL index status for filtering active connections
10. THE Connection table SHALL use TIMESTAMP WITH TIME ZONE for all timestamp columns

### Requirement 6: Database Schema - Prescription and Medication Tables

**User Story:** As a system architect, I want prescription and medication tables with version control, so that prescription management and history tracking work correctly.

#### Acceptance Criteria

1. THE Database SHALL have a Prescription table with UUID primary key
2. THE Prescription table SHALL have columns: id, patientId, doctorId, patientName, patientGender, patientAge, symptoms, status, currentVersion, isUrgent, urgentReason, createdAt, updatedAt
3. THE Prescription table SHALL have foreign key patientId referencing User(id) with CASCADE delete
4. THE Prescription table SHALL have foreign key doctorId referencing User(id) with SET NULL on delete (to preserve prescription history if doctor account is deleted)
5. THE Prescription table SHALL use enum type for status: DRAFT, ACTIVE, PAUSED, INACTIVE
6. THE Prescription table SHALL use enum type for patientGender: MALE, FEMALE, OTHER (snapshot at creation)
7. THE Prescription table SHALL index patientId and doctorId for fast queries
8. THE Prescription table SHALL index status for filtering active prescriptions
9. THE Prescription table SHALL index (patientId, status) as composite index for patient-specific prescription queries
10. THE Database SHALL have a PrescriptionVersion table with UUID primary key
11. THE PrescriptionVersion table SHALL have columns: id, prescriptionId, versionNumber, authorId, changeReason, medicationsSnapshot, createdAt
12. THE PrescriptionVersion table SHALL have foreign key prescriptionId referencing Prescription(id) with CASCADE delete
13. THE PrescriptionVersion table SHALL have foreign key authorId referencing User(id) with SET NULL on delete
14. THE PrescriptionVersion table SHALL use JSONB type for medicationsSnapshot to store complete version history
15. THE PrescriptionVersion table SHALL enforce unique constraint on (prescriptionId, versionNumber) to prevent duplicate versions
16. THE Database SHALL have a Medication table with UUID primary key
17. THE Medication table SHALL have columns: id, prescriptionId, rowNumber, medicineName, medicineNameKhmer, morningDosage, daytimeDosage, nightDosage, imageUrl, frequency, timing, createdAt, updatedAt
18. THE Medication table SHALL have foreign key prescriptionId referencing Prescription(id) with CASCADE delete
19. THE Medication table SHALL use JSONB type for dosage columns (morningDosage, daytimeDosage, nightDosage) to store flexible dosage information including amount and beforeMeal flag
20. THE Medication table SHALL index prescriptionId for fast prescription medication queries
21. THE Medication table SHALL support PRN (as needed) medications with flexible timing configuration

### Requirement 7: Database Schema - DoseEvent Table

**User Story:** As a system architect, I want a dose event table tracking medication adherence, so that dose tracking and reporting work correctly.

#### Acceptance Criteria

1. THE Database SHALL have a DoseEvent table with UUID primary key
2. THE DoseEvent table SHALL have columns: id, prescriptionId, medicationId, patientId, scheduledTime, timePeriod, status, takenAt, skipReason, reminderTime, wasOffline, createdAt, updatedAt
3. THE DoseEvent table SHALL have foreign key prescriptionId referencing Prescription(id) with CASCADE delete
4. THE DoseEvent table SHALL have foreign key medicationId referencing Medication(id) with CASCADE delete
5. THE DoseEvent table SHALL have foreign key patientId referencing User(id) with CASCADE delete
6. THE DoseEvent table SHALL use enum type for timePeriod: DAYTIME, NIGHT
7. THE DoseEvent table SHALL use enum type for status: DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED
8. THE DoseEvent table SHALL index patientId and scheduledTime for fast schedule queries
9. THE DoseEvent table SHALL index status for filtering dose events by status
10. THE DoseEvent table SHALL index (patientId, scheduledTime) as composite index for daily schedule queries
11. THE DoseEvent table SHALL use TIMESTAMP WITH TIME ZONE for scheduledTime and takenAt
12. THE DoseEvent table SHALL use TIME type for reminderTime (HH:mm format)

### Requirement 8: Database Schema - Audit Log Table

**User Story:** As a system architect, I want an immutable audit log table, so that all system actions are tracked for transparency and compliance.

#### Acceptance Criteria

1. THE Database SHALL have an AuditLog table with UUID primary key
2. THE AuditLog table SHALL have columns: id, actorId, actorRole, actionType, resourceType, resourceId, details, ipAddress, createdAt
3. THE AuditLog table SHALL have foreign key actorId referencing User(id) with SET NULL on delete (to preserve audit trail even if user is deleted)
4. THE AuditLog table SHALL use enum type for actorRole: PATIENT, DOCTOR, FAMILY_MEMBER (nullable to support system actions)
5. THE AuditLog table SHALL use enum type for actionType: CONNECTION_REQUEST, CONNECTION_ACCEPT, CONNECTION_REVOKE, PERMISSION_CHANGE, PRESCRIPTION_CREATE, PRESCRIPTION_UPDATE, PRESCRIPTION_CONFIRM, PRESCRIPTION_RETAKE, DOSE_TAKEN, DOSE_SKIPPED, DOSE_MISSED, DATA_ACCESS, NOTIFICATION_SENT, SUBSCRIPTION_CHANGE
6. THE AuditLog table SHALL use JSONB type for details column to store flexible action metadata including urgent flags, version numbers, and change reasons
7. THE AuditLog table SHALL index actorId for user-specific audit queries
8. THE AuditLog table SHALL index resourceId for resource-specific audit queries
9. THE AuditLog table SHALL index createdAt for time-based audit queries
10. THE AuditLog table SHALL index actionType for filtering by action type
11. THE AuditLog table SHALL NOT allow UPDATE or DELETE operations (insert-only for immutability)
12. THE AuditLog table SHALL use TIMESTAMP WITH TIME ZONE for createdAt
13. THE AuditLog table SHALL record all urgent prescription changes with full context (doctor ID, timestamp, reason, version link)
14. THE AuditLog table SHALL record all offline sync events with sync timestamp and late notification indicators

### Requirement 9: Database Schema - Notification Table

**User Story:** As a system architect, I want a notification table for storing user notifications, so that notification delivery and history work correctly.

#### Acceptance Criteria

1. THE Database SHALL have a Notification table with UUID primary key
2. THE Notification table SHALL have columns: id, recipientId, type, title, message, data, isRead, createdAt, readAt
3. THE Notification table SHALL have foreign key recipientId referencing User(id) with CASCADE delete
4. THE Notification table SHALL use enum type for type: CONNECTION_REQUEST, PRESCRIPTION_UPDATE, MISSED_DOSE_ALERT, URGENT_PRESCRIPTION_CHANGE, FAMILY_ALERT
5. THE Notification table SHALL use JSONB type for data column to store notification payload
6. THE Notification table SHALL index recipientId for user notification queries
7. THE Notification table SHALL index (recipientId, isRead) as composite index for unread notification queries
8. THE Notification table SHALL index createdAt for time-ordered notification queries
9. THE Notification table SHALL use TIMESTAMP WITH TIME ZONE for createdAt and readAt

### Requirement 10: Database Schema - Subscription and Storage Tables

**User Story:** As a system architect, I want subscription and storage tracking tables, so that subscription management and quota enforcement work correctly.

#### Acceptance Criteria

1. THE Database SHALL have a Subscription table with UUID primary key
2. THE Subscription table SHALL have columns: id, userId, tier, storageQuota, storageUsed, expiresAt, createdAt, updatedAt
3. THE Subscription table SHALL have foreign key userId referencing User(id) with CASCADE delete
4. THE Subscription table SHALL use enum type for tier: FREEMIUM, PREMIUM, FAMILY_PREMIUM
5. THE Subscription table SHALL use BIGINT type for storageQuota and storageUsed (bytes)
6. THE Subscription table SHALL set default storageQuota to 5368709120 (5GB) for FREEMIUM tier
7. THE Subscription table SHALL set default storageUsed to 0
8. THE Subscription table SHALL index userId for fast subscription lookup
9. THE Subscription table SHALL index tier for subscription tier queries
10. THE Database SHALL have a FamilyMember table with UUID primary key
11. THE FamilyMember table SHALL have columns: id, subscriptionId, memberId, addedAt
12. THE FamilyMember table SHALL have foreign key subscriptionId referencing Subscription(id) with CASCADE delete
13. THE FamilyMember table SHALL have foreign key memberId referencing User(id) with CASCADE delete
14. THE FamilyMember table SHALL enforce unique constraint on (subscriptionId, memberId) to prevent duplicate family members
15. THE FamilyMember table SHALL index subscriptionId for family member queries

### Requirement 11: Database Schema - Meal Time Preference Table

**User Story:** As a system architect, I want a meal time preference table, so that personalized medication reminder times work correctly and PRN medications can use default Cambodia timezone presets.

#### Acceptance Criteria

1. THE Database SHALL have a MealTimePreference table with UUID primary key
2. THE MealTimePreference table SHALL have columns: id, userId, morningMeal, afternoonMeal, nightMeal, createdAt, updatedAt
3. THE MealTimePreference table SHALL have foreign key userId referencing User(id) with CASCADE delete
4. THE MealTimePreference table SHALL enforce unique constraint on userId (one preference per user)
5. THE MealTimePreference table SHALL use VARCHAR type for meal time ranges (e.g., "6-7AM", "12-1PM", "6-7PM")
6. THE MealTimePreference table SHALL index userId for fast preference lookup
7. THE MealTimePreference table SHALL support default Cambodia timezone presets: Morning (07:00 AM), Noon (12:00 PM), Evening (06:00 PM), Night (09:00 PM)
8. THE Backend SHALL use meal time preferences to calculate reminder times for medications
9. THE Backend SHALL apply default presets when user has not configured custom meal times
10. THE Backend SHALL use meal time preferences for PRN (as needed) medications when no specific times are provided

### Requirement 12: Prisma Schema Definition

**User Story:** As a backend developer, I want a complete Prisma schema file, so that database models are type-safe and migrations are automated.

#### Acceptance Criteria

1. THE Backend SHALL define all database models in schema.prisma file with PostgreSQL datasource
2. THE Backend SHALL define all enum types in Prisma schema matching database enums
3. THE Backend SHALL use @id and @default(uuid()) for all primary keys
4. THE Backend SHALL use @relation for all foreign key relationships with onDelete behavior
5. THE Backend SHALL use @unique for unique constraints
6. THE Backend SHALL use @@unique for composite unique constraints
7. THE Backend SHALL use @@index for single and composite indexes
8. THE Backend SHALL use @db.Text for long text fields (symptoms, changeReason, skipReason)
9. THE Backend SHALL use @db.Timestamptz for timestamp fields with timezone
10. THE Backend SHALL use @updatedAt for automatic timestamp updates
11. THE Backend SHALL use Json type for JSONB columns (dosage, details, data, medicationsSnapshot)

### Requirement 13: Database Migrations

**User Story:** As a backend developer, I want automated database migrations, so that schema changes are version-controlled and reproducible.

#### Acceptance Criteria

1. THE Backend SHALL use Prisma Migrate for creating and applying database migrations
2. WHEN the Prisma schema changes, THE Backend SHALL generate a new migration file with timestamp and description
3. THE Backend SHALL apply pending migrations automatically on application startup in development mode
4. THE Backend SHALL require manual migration approval in production mode
5. THE Backend SHALL store migration history in _prisma_migrations table
6. THE Backend SHALL support migration rollback for development environments
7. THE Backend SHALL validate schema consistency before applying migrations
8. THE Backend SHALL generate SQL migration files that can be reviewed before application

### Requirement 14: Database Seeding

**User Story:** As a backend developer, I want database seeding for development and testing, so that I can work with realistic data.

#### Acceptance Criteria

1. THE Backend SHALL provide a seed script for populating initial development data
2. THE seed script SHALL create test users for all three roles (Patient, Doctor, Family_Member)
3. THE seed script SHALL create test connections between users
4. THE seed script SHALL create test prescriptions with medications
5. THE seed script SHALL create test dose events with various statuses
6. THE seed script SHALL create test audit logs
7. THE seed script SHALL create test subscriptions for all tiers
8. THE seed script SHALL use bcrypt for hashing test user passwords
9. THE seed script SHALL be idempotent (can run multiple times without errors)
10. THE seed script SHALL clear existing data before seeding in development mode

### Requirement 15: NextAuth.js Authentication Setup

**User Story:** As a backend developer, I want NextAuth.js configured for authentication, so that JWT and OAuth authentication work correctly.

#### Acceptance Criteria

1. THE Backend SHALL use NextAuth.js version 5 (Auth.js) for authentication
2. THE Backend SHALL configure Credentials provider for phone/email and password login
3. THE Backend SHALL configure Google OAuth provider for social login
4. THE Backend SHALL use JWT strategy for session management
5. THE Backend SHALL store JWT secret in environment variable
6. THE Backend SHALL set JWT expiration to 15 minutes for access tokens
7. THE Backend SHALL set JWT expiration to 7 days for refresh tokens
8. THE Backend SHALL include user ID, role, subscription tier, and language in JWT payload
9. THE Backend SHALL use callbacks to customize JWT and session data
10. THE Backend SHALL use Redis for storing refresh tokens with automatic expiration
11. THE Backend SHALL implement token rotation for refresh tokens
12. THE Backend SHALL invalidate all user tokens on password change

### Requirement 16: Google OAuth Integration

**User Story:** As a user, I want to sign in with my Google account, so that I can access the platform without creating a new password.

#### Acceptance Criteria

1. THE Backend SHALL register a Google OAuth application with client ID and secret
2. THE Backend SHALL configure Google OAuth provider in NextAuth with appropriate scopes (email, profile)
3. WHEN a user signs in with Google, THE Backend SHALL create a new user account if email doesn't exist
4. WHEN a user signs in with Google, THE Backend SHALL link the Google account to existing user if email matches
5. THE Backend SHALL extract firstName, lastName, and email from Google profile
6. THE Backend SHALL set default role to PATIENT for new Google sign-ups
7. THE Backend SHALL set default language to ENGLISH for Google sign-ups
8. THE Backend SHALL set default subscription tier to FREEMIUM for new Google sign-ups
9. THE Backend SHALL store Google account ID for future authentication
10. THE Backend SHALL handle Google OAuth errors gracefully with user-friendly messages

### Requirement 17: Zod Validation Schemas

**User Story:** As a backend developer, I want Zod schemas for request validation, so that API inputs are type-safe and validated at runtime.

#### Acceptance Criteria

1. THE Backend SHALL define Zod schemas for all API request bodies
2. THE Backend SHALL validate phone numbers with regex pattern for Cambodia format (+855)
3. THE Backend SHALL validate email addresses with email() validator
4. THE Backend SHALL validate passwords with minimum length of 6 characters
5. THE Backend SHALL validate PIN codes with regex pattern for exactly 4 digits
6. THE Backend SHALL validate dates with ISO 8601 format
7. THE Backend SHALL validate enums with Zod enum validator matching Prisma enums
8. THE Backend SHALL validate UUIDs with uuid() validator
9. THE Backend SHALL provide custom error messages in Khmer and English for validation failures
10. THE Backend SHALL use Zod's transform() for data normalization (e.g., trimming strings)
11. THE Backend SHALL use Zod's refine() for complex validation rules (e.g., age >= 13)

### Requirement 18: API Middleware Stack

**User Story:** As a backend developer, I want a comprehensive middleware stack, so that cross-cutting concerns are handled consistently.

#### Acceptance Criteria

1. THE Backend SHALL use middleware for authentication verification on protected routes
2. THE Backend SHALL use middleware for role-based authorization
3. THE Backend SHALL use middleware for request logging with timestamp, method, path, and user ID
4. THE Backend SHALL use middleware for error handling with consistent error response format
5. THE Backend SHALL use middleware for CORS configuration allowing Flutter app origin
6. THE Backend SHALL use middleware for request body parsing (JSON)
7. THE Backend SHALL use middleware for rate limiting using Redis
8. THE Backend SHALL use middleware for request validation using Zod schemas
9. THE Backend SHALL use middleware for audit logging of all mutations
10. THE Backend SHALL use middleware for language detection from Accept-Language header
11. THE Backend SHALL apply middleware in correct order: CORS → logging → auth → validation → route handler → error handling

### Requirement 19: Error Handling and Logging

**User Story:** As a backend developer, I want comprehensive error handling and logging, so that issues are tracked and debugged efficiently.

#### Acceptance Criteria

1. THE Backend SHALL use a centralized error handler for all API routes
2. THE Backend SHALL return consistent error response format: { error: { code: string, message: string, details?: object } }
3. THE Backend SHALL map Prisma errors to appropriate HTTP status codes (404 for NotFound, 409 for UniqueConstraint)
4. THE Backend SHALL map Zod validation errors to HTTP 400 with field-level error details
5. THE Backend SHALL return HTTP 401 for authentication errors
6. THE Backend SHALL return HTTP 403 for authorization errors
7. THE Backend SHALL return HTTP 429 for rate limit errors with retry-after header
8. THE Backend SHALL return HTTP 500 for unexpected server errors
9. THE Backend SHALL log all errors to console in development mode
10. THE Backend SHALL log all errors to file in production mode with rotation
11. THE Backend SHALL include error stack traces in development mode only
12. THE Backend SHALL translate error messages to user's preferred language (Khmer or English)
13. THE Backend SHALL sanitize error messages to prevent information leakage

### Requirement 20: Rate Limiting

**User Story:** As a system administrator, I want rate limiting to prevent abuse, so that the API remains available for legitimate users.

#### Acceptance Criteria

1. THE Backend SHALL implement rate limiting using Redis with sliding window algorithm
2. THE Backend SHALL limit authentication endpoints to 5 requests per minute per IP address
3. THE Backend SHALL limit OTP send endpoint to 3 requests per hour per phone number
4. THE Backend SHALL limit general API endpoints to 100 requests per minute per authenticated user
5. THE Backend SHALL limit file upload endpoints to 10 requests per hour per user
6. WHEN rate limit is exceeded, THE Backend SHALL return HTTP 429 with retry-after header
7. THE Backend SHALL use Redis keys with automatic expiration for rate limit counters
8. THE Backend SHALL provide rate limit headers in responses: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
9. THE Backend SHALL exempt admin users from rate limiting
10. THE Backend SHALL log rate limit violations for security monitoring

### Requirement 21: Caching Strategy

**User Story:** As a backend developer, I want intelligent caching, so that API responses are fast and database load is reduced.

#### Acceptance Criteria

1. THE Backend SHALL cache user profile data in Redis with 5-minute TTL
2. THE Backend SHALL cache subscription data in Redis with 10-minute TTL
3. THE Backend SHALL cache medication schedules in Redis with 1-minute TTL
4. THE Backend SHALL cache connection lists in Redis with 5-minute TTL
5. THE Backend SHALL invalidate cache on data mutations (create, update, delete)
6. THE Backend SHALL use cache-aside pattern (check cache first, then database)
7. THE Backend SHALL use Redis keys with namespace prefixes (e.g., "user:profile:{userId}")
8. THE Backend SHALL serialize cached data as JSON
9. THE Backend SHALL handle cache misses gracefully by fetching from database
10. THE Backend SHALL log cache hit/miss rates for monitoring

### Requirement 22: Environment Configuration

**User Story:** As a backend developer, I want environment-based configuration, so that the application works correctly in development, staging, and production.

#### Acceptance Criteria

1. THE Backend SHALL use .env file for environment variables in development
2. THE Backend SHALL require environment variables: DATABASE_URL, REDIS_URL, NEXTAUTH_SECRET, NEXTAUTH_URL, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, SMS_API_KEY, AWS_S3_BUCKET, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
3. THE Backend SHALL validate required environment variables on startup
4. THE Backend SHALL use different database URLs for development, test, and production
5. THE Backend SHALL use different Redis URLs for development and production
6. THE Backend SHALL use different NextAuth URLs for development and production
7. THE Backend SHALL use NODE_ENV to determine environment (development, test, production)
8. THE Backend SHALL disable debug logging in production mode
9. THE Backend SHALL use secure cookies in production mode (secure: true, sameSite: 'strict')
10. THE Backend SHALL provide .env.example file with all required variables

### Requirement 23: Docker Compose Setup

**User Story:** As a backend developer, I want Docker Compose for local development, so that I can run the entire stack with one command.

#### Acceptance Criteria

1. THE Backend SHALL provide docker-compose.yml file for local development
2. THE docker-compose.yml SHALL define PostgreSQL service with persistent volume
3. THE docker-compose.yml SHALL define Redis service with persistent volume
4. THE docker-compose.yml SHALL define network for service communication
5. THE docker-compose.yml SHALL expose PostgreSQL on port 5432
6. THE docker-compose.yml SHALL expose Redis on port 6379
7. THE docker-compose.yml SHALL use environment variables from .env file
8. THE docker-compose.yml SHALL configure health checks for PostgreSQL and Redis
9. THE docker-compose.yml SHALL set restart policy to "unless-stopped"
10. THE Backend SHALL provide scripts for starting, stopping, and resetting Docker services

### Requirement 24: Database Backup and Restore

**User Story:** As a system administrator, I want database backup and restore capabilities, so that data is protected against loss.

#### Acceptance Criteria

1. THE Backend SHALL provide script for creating PostgreSQL database backups
2. THE backup script SHALL use pg_dump to create SQL dump files
3. THE backup script SHALL compress backup files with gzip
4. THE backup script SHALL include timestamp in backup filename
5. THE backup script SHALL store backups in designated backup directory
6. THE Backend SHALL provide script for restoring database from backup
7. THE restore script SHALL use pg_restore or psql to restore from dump files
8. THE restore script SHALL validate backup file before restoration
9. THE Backend SHALL document backup and restore procedures in README
10. THE Backend SHALL recommend daily automated backups for production

### Requirement 25: Database Connection Pooling

**User Story:** As a backend developer, I want efficient database connection pooling, so that the application handles concurrent requests efficiently.

#### Acceptance Criteria

1. THE Backend SHALL use Prisma's built-in connection pooling
2. THE Backend SHALL configure connection pool size to 10 connections for development
3. THE Backend SHALL configure connection pool size to 20 connections for production
4. THE Backend SHALL set connection timeout to 10 seconds
5. THE Backend SHALL set idle timeout to 60 seconds
6. THE Backend SHALL log connection pool metrics (active, idle, waiting)
7. THE Backend SHALL handle connection pool exhaustion gracefully with retry logic
8. THE Backend SHALL close database connections on application shutdown

### Requirement 26: Database Indexes and Performance

**User Story:** As a backend developer, I want optimized database indexes, so that queries are fast even with large datasets.

#### Acceptance Criteria

1. THE Database SHALL create indexes on all foreign key columns
2. THE Database SHALL create composite indexes for frequently queried column combinations
3. THE Database SHALL create indexes on columns used in WHERE clauses (status, scheduledTime, isRead)
4. THE Database SHALL use EXPLAIN ANALYZE to validate query performance
5. THE Database SHALL maintain index statistics for query optimizer
6. THE Database SHALL avoid over-indexing to balance read and write performance
7. THE Backend SHALL log slow queries exceeding 1000ms for optimization
8. THE Backend SHALL use Prisma's query optimization features (select, include)
9. THE Backend SHALL use pagination for large result sets
10. THE Backend SHALL use database transactions for multi-step operations

### Requirement 27: Data Integrity and Constraints

**User Story:** As a system architect, I want comprehensive data integrity constraints, so that the database maintains consistency.

#### Acceptance Criteria

1. THE Database SHALL enforce NOT NULL constraints on required fields
2. THE Database SHALL enforce UNIQUE constraints on phoneNumber and email
3. THE Database SHALL enforce FOREIGN KEY constraints with appropriate CASCADE behavior
4. THE Database SHALL enforce CHECK constraints for enum values
5. THE Database SHALL enforce CHECK constraints for positive values (storageQuota, storageUsed)
6. THE Database SHALL use database-level defaults for timestamps (NOW())
7. THE Database SHALL use database-level defaults for boolean fields
8. THE Database SHALL use database-level defaults for enum fields
9. THE Database SHALL validate data types at database level
10. THE Database SHALL reject invalid data with descriptive error messages

### Requirement 28: Multi-Language Support in Database

**User Story:** As a backend developer, I want multi-language support in the database, so that Khmer and English content is stored correctly.

#### Acceptance Criteria

1. THE Database SHALL use UTF-8 encoding for all text columns
2. THE Database SHALL store Khmer text in VARCHAR and TEXT columns without corruption
3. THE Database SHALL support Khmer characters in user names, medication names, and symptoms
4. THE Database SHALL store language preference in User table
5. THE Database SHALL store both Khmer and English medication names when available
6. THE Database SHALL use collation that supports Khmer sorting
7. THE Backend SHALL validate Khmer text input using Zod schemas
8. THE Backend SHALL return error messages in user's preferred language
9. THE Backend SHALL store audit log messages in both languages when applicable

### Requirement 29: Timezone Handling

**User Story:** As a backend developer, I want consistent timezone handling, so that all timestamps use Cambodia timezone correctly.

#### Acceptance Criteria

1. THE Backend SHALL use Asia/Phnom_Penh (UTC+7) as default timezone
2. THE Backend SHALL store all timestamps in database with timezone information (TIMESTAMPTZ)
3. THE Backend SHALL convert all incoming timestamps to Cambodia timezone
4. THE Backend SHALL return all timestamps in ISO 8601 format with timezone offset
5. THE Backend SHALL use date-fns-tz or luxon library for timezone operations
6. THE Backend SHALL calculate dose windows using Cambodia timezone
7. THE Backend SHALL handle daylight saving time transitions (though Cambodia doesn't observe DST)
8. THE Backend SHALL validate timestamp formats using Zod schemas
9. THE Backend SHALL use Cambodia timezone for scheduled reminders
10. THE Backend SHALL log all timestamps in Cambodia timezone

### Requirement 30: API Documentation

**User Story:** As a frontend developer, I want comprehensive API documentation, so that I can integrate with the backend correctly.

#### Acceptance Criteria

1. THE Backend SHALL provide OpenAPI 3.0 specification for all API endpoints
2. THE Backend SHALL document request and response schemas for all endpoints
3. THE Backend SHALL document authentication requirements for protected endpoints
4. THE Backend SHALL document error responses with status codes and error formats
5. THE Backend SHALL provide example requests and responses for all endpoints
6. THE Backend SHALL document rate limiting rules for each endpoint
7. THE Backend SHALL document pagination parameters for list endpoints
8. THE Backend SHALL host interactive API documentation using Swagger UI or similar
9. THE Backend SHALL keep API documentation synchronized with code changes
10. THE Backend SHALL provide Postman collection for API testing

### Requirement 31: Testing Infrastructure

**User Story:** As a backend developer, I want comprehensive testing infrastructure, so that code quality is maintained.

#### Acceptance Criteria

1. THE Backend SHALL use Jest or Vitest for unit and integration testing
2. THE Backend SHALL provide test database configuration separate from development database
3. THE Backend SHALL reset test database before each test suite
4. THE Backend SHALL use Prisma's testing utilities for database mocking
5. THE Backend SHALL achieve minimum 80% code coverage for service layer
6. THE Backend SHALL test all API endpoints with integration tests
7. THE Backend SHALL test authentication and authorization flows
8. THE Backend SHALL test error handling and validation
9. THE Backend SHALL test database transactions and rollbacks
10. THE Backend SHALL use test fixtures for consistent test data
11. THE Backend SHALL run tests in CI/CD pipeline before deployment

### Requirement 32: Security Best Practices

**User Story:** As a security engineer, I want security best practices implemented, so that the application is protected against common vulnerabilities.

#### Acceptance Criteria

1. THE Backend SHALL hash passwords using bcrypt with salt rounds of 10
2. THE Backend SHALL hash PIN codes using bcrypt with salt rounds of 10
3. THE Backend SHALL use parameterized queries to prevent SQL injection (Prisma handles this)
4. THE Backend SHALL validate and sanitize all user inputs
5. THE Backend SHALL use HTTPS only in production (enforce secure cookies)
6. THE Backend SHALL implement CORS with specific allowed origins
7. THE Backend SHALL use helmet.js for security headers
8. THE Backend SHALL implement rate limiting to prevent brute force attacks
9. THE Backend SHALL log security events (failed logins, permission denials)
10. THE Backend SHALL use environment variables for secrets (never hardcode)
11. THE Backend SHALL implement account lockout after 5 failed login attempts
12. THE Backend SHALL expire JWT tokens appropriately (15 min access, 7 day refresh)
13. THE Backend SHALL validate file uploads (type, size, content)
14. THE Backend SHALL prevent mass assignment vulnerabilities using Zod validation

### Requirement 33: File Storage Integration

**User Story:** As a backend developer, I want file storage for user uploads, so that license photos and medication images are stored securely.

#### Acceptance Criteria

1. THE Backend SHALL use AWS S3 or compatible object storage for file uploads
2. THE Backend SHALL configure S3 bucket with private access (not public)
3. THE Backend SHALL generate pre-signed URLs for file access with 1-hour expiration
4. THE Backend SHALL validate file types (JPEG, PNG, PDF) before upload
5. THE Backend SHALL validate file sizes (max 5MB for images, max 10MB for PDFs)
6. THE Backend SHALL generate unique file names using UUID to prevent collisions
7. THE Backend SHALL organize files in folders by type (licenses/, medications/)
8. THE Backend SHALL store file URLs in database (licensePhotoUrl, imageUrl)
9. THE Backend SHALL implement file deletion when associated records are deleted
10. THE Backend SHALL count file storage toward user's storage quota
11. THE Backend SHALL compress images before upload to reduce storage usage

### Requirement 34: SMS Integration for OTP

**User Story:** As a backend developer, I want SMS integration for OTP delivery, so that phone number verification works correctly.

#### Acceptance Criteria

1. THE Backend SHALL use Twilio or AWS SNS for SMS delivery
2. THE Backend SHALL send 4-digit OTP codes to Cambodia phone numbers (+855)
3. THE Backend SHALL store OTP codes in Redis with 5-minute expiration
4. THE Backend SHALL implement OTP resend with 60-second cooldown
5. THE Backend SHALL limit OTP attempts to 5 per phone number per hour
6. THE Backend SHALL use SMS templates for consistent messaging
7. THE Backend SHALL support both Khmer and English SMS messages
8. THE Backend SHALL log SMS delivery status for monitoring
9. THE Backend SHALL handle SMS delivery failures gracefully
10. THE Backend SHALL provide fallback mechanism if SMS fails (email OTP)

### Requirement 35: Offline Sync Support

**User Story:** As a backend developer, I want offline sync support, so that patients can use the app offline and sync actions when reconnected.

#### Acceptance Criteria

1. THE Backend SHALL provide endpoint POST /api/sync/batch for batch syncing offline actions
2. THE Backend SHALL accept sync actions with types: DOSE_TAKEN, DOSE_SKIPPED, PRESCRIPTION_UPDATED
3. THE Backend SHALL validate sync action timestamps to ensure they are in the past
4. THE Backend SHALL process sync actions in chronological order based on timestamp
5. THE Backend SHALL detect and resolve conflicts when server state differs from offline action
6. THE Backend SHALL return conflict details including server state for client resolution
7. THE Backend SHALL mark DoseEvents with wasOffline flag when synced from offline queue
8. THE Backend SHALL trigger family notifications for missed doses after offline sync
9. THE Backend SHALL include "sent after reconnect" indicator in late notifications
10. THE Backend SHALL update audit logs with sync timestamp and offline indicator
11. THE Backend SHALL provide endpoint GET /api/sync/status to check sync status
12. THE Backend SHALL return summary of applied actions and conflicts after batch sync
13. THE Backend SHALL ensure idempotency for sync operations (duplicate sync requests don't create duplicate records)
14. THE Backend SHALL validate that synced actions belong to the authenticated user
15. THE Backend SHALL support syncing up to 100 actions per batch request

### Requirement 35: Monitoring and Observability

**User Story:** As a system administrator, I want monitoring and observability, so that I can track system health and performance.

#### Acceptance Criteria

1. THE Backend SHALL log all API requests with timestamp, method, path, status, and duration
2. THE Backend SHALL log all errors with stack traces and context
3. THE Backend SHALL expose health check endpoint at /api/health
4. THE Backend SHALL expose metrics endpoint at /api/metrics (protected)
5. THE Backend SHALL track key metrics: request count, error rate, response time, database query time
6. THE Backend SHALL track business metrics: user registrations, prescriptions created, doses tracked, offline sync events
7. THE Backend SHALL use structured logging (JSON format) for easy parsing
8. THE Backend SHALL rotate log files daily with 30-day retention
9. THE Backend SHALL integrate with monitoring tools (Prometheus, Grafana, or similar)
10. THE Backend SHALL send alerts for critical errors and performance degradation
11. THE Backend SHALL monitor offline sync success rate and conflict resolution
12. THE Backend SHALL track late notification delivery metrics

### Requirement 36: Deployment Configuration

**User Story:** As a DevOps engineer, I want deployment configuration, so that the application can be deployed to production.

#### Acceptance Criteria

1. THE Backend SHALL provide Dockerfile for containerized deployment
2. THE Backend SHALL use multi-stage Docker build for optimized image size
3. THE Backend SHALL run database migrations automatically on deployment
4. THE Backend SHALL use environment variables for all configuration
5. THE Backend SHALL expose port 3000 for HTTP traffic
6. THE Backend SHALL implement graceful shutdown handling
7. THE Backend SHALL provide health check endpoint for load balancer
8. THE Backend SHALL use production-ready Next.js build (next build && next start)
9. THE Backend SHALL configure CORS for production frontend domain
10. THE Backend SHALL provide deployment documentation for Vercel, AWS, or Docker

### Requirement 37: API Versioning

**User Story:** As a backend developer, I want API versioning, so that breaking changes don't affect existing clients.

#### Acceptance Criteria

1. THE Backend SHALL use URL path versioning (e.g., /api/v1/users)
2. THE Backend SHALL maintain current API version (v1) as stable
3. THE Backend SHALL document breaking changes in changelog
4. THE Backend SHALL support at least one previous API version during transition
5. THE Backend SHALL deprecate old API versions with 6-month notice
6. THE Backend SHALL return API version in response headers
7. THE Backend SHALL validate API version in requests
8. THE Backend SHALL provide migration guide for version upgrades

### Requirement 38: Database Query Optimization

**User Story:** As a backend developer, I want optimized database queries, so that API responses are fast.

#### Acceptance Criteria

1. THE Backend SHALL use Prisma's select to fetch only required fields
2. THE Backend SHALL use Prisma's include for eager loading related data
3. THE Backend SHALL avoid N+1 query problems using include or findMany
4. THE Backend SHALL use database indexes for all WHERE clauses
5. THE Backend SHALL use pagination for large result sets (default 50, max 100)
6. THE Backend SHALL use cursor-based pagination for infinite scroll
7. THE Backend SHALL use database aggregations for counts and sums
8. THE Backend SHALL cache frequently accessed data in Redis
9. THE Backend SHALL use database transactions for atomic operations
10. THE Backend SHALL monitor query performance and optimize slow queries

### Requirement 39: Audit Log Querying

**User Story:** As a patient, I want to query my audit log with filters, so that I can review specific actions on my data.

#### Acceptance Criteria

1. THE Backend SHALL provide endpoint GET /api/audit-logs with authentication
2. THE Backend SHALL support filtering by date range (startDate, endDate)
3. THE Backend SHALL support filtering by action type (CONNECTION_REQUEST, PRESCRIPTION_UPDATE, etc.)
4. THE Backend SHALL support filtering by actor (doctorId, familyMemberId)
5. THE Backend SHALL support filtering by resource type (Prescription, DoseEvent, etc.)
6. THE Backend SHALL return audit logs in reverse chronological order (newest first)
7. THE Backend SHALL paginate audit log results (default 50 per page)
8. THE Backend SHALL include actor details (name, role) in audit log response
9. THE Backend SHALL enforce authorization (users can only view their own audit logs)
10. THE Backend SHALL format timestamps in user's preferred timezone

### Requirement 40: Subscription Upgrade Flow

**User Story:** As a patient, I want to upgrade my subscription, so that I can access premium features and increased storage.

#### Acceptance Criteria

1. THE Backend SHALL provide endpoint POST /api/subscriptions/upgrade
2. WHEN a user upgrades to PREMIUM, THE Backend SHALL increase storage quota to 20GB
3. WHEN a user upgrades to FAMILY_PREMIUM, THE Backend SHALL increase storage quota to 20GB and allow up to 3 family members
4. THE Backend SHALL validate payment information before upgrading
5. THE Backend SHALL update subscription tier immediately after successful payment
6. THE Backend SHALL set subscription expiration date based on billing cycle
7. THE Backend SHALL send confirmation notification after successful upgrade
8. THE Backend SHALL log subscription changes in audit log
9. THE Backend SHALL handle payment failures gracefully with retry mechanism
10. THE Backend SHALL support subscription downgrade with data retention policy

### Requirement 41: Urgent Prescription Auto-Apply

**User Story:** As a doctor, I want to mark prescription changes as urgent and auto-apply them, so that patients immediately follow safer treatment plans.

#### Acceptance Criteria

1. THE Backend SHALL support isUrgent flag on prescription updates
2. WHEN doctor marks update as urgent, THE Backend SHALL auto-apply the new version immediately without patient confirmation
3. THE Backend SHALL store urgent flag in Prescription table
4. THE Backend SHALL store urgentReason in Prescription table for doctor to explain urgency
5. THE Backend SHALL create new PrescriptionVersion with urgent flag in details
6. THE Backend SHALL send URGENT_PRESCRIPTION_CHANGE notification to patient immediately
7. THE Backend SHALL regenerate dose schedule immediately for urgent changes
8. THE Backend SHALL log urgent changes in audit log with full context: doctor ID, timestamp, reason, version number
9. THE Backend SHALL include urgent flag and reason in prescription history visible to patient
10. THE Backend SHALL allow patient to view complete history of urgent changes
11. THE Backend SHALL ensure urgent changes appear in audit trail for transparency
12. THE Backend SHALL validate that doctor has ALLOWED permission level before accepting urgent changes

### Requirement 42: Connection Mutual Acceptance Flow

**User Story:** As a patient or doctor, I want connection requests to require mutual acceptance, so that both parties consent to the relationship.

#### Acceptance Criteria

1. THE Backend SHALL support doctor-initiated connection requests to patients
2. THE Backend SHALL support patient-initiated connection requests to doctors
3. THE Backend SHALL create Connection record with status PENDING when request is initiated
4. THE Backend SHALL send notification to recipient when connection request is received
5. THE Backend SHALL provide endpoint POST /api/connections/:connectionId/accept for accepting requests
6. THE Backend SHALL provide endpoint POST /api/connections/:connectionId/decline for declining requests
7. WHEN connection is accepted, THE Backend SHALL update status to ACCEPTED and set acceptedAt timestamp
8. WHEN connection is accepted, THE Backend SHALL show permission popup to patient (regardless of who initiated)
9. THE Backend SHALL apply default permission level ALLOWED (history/report view) if patient clicks OK without selecting
10. THE Backend SHALL allow patient to set permission level: NOT_ALLOWED, REQUEST, SELECTED, or ALLOWED
11. THE Backend SHALL log all connection requests, acceptances, and declines in audit log
12. THE Backend SHALL prevent duplicate connection requests between same users
13. THE Backend SHALL allow patient to change doctor permission level at any time after connection
14. THE Backend SHALL enforce permission levels when doctor attempts to access patient data
15. THE Backend SHALL provide endpoint POST /api/connections/:connectionId/revoke for revoking connections

### Requirement 43: Family Connection and Missed Dose Alerts

**User Story:** As a patient, I want to connect family members who receive missed-dose alerts, so they can help me stay adherent.

#### Acceptance Criteria

1. THE Backend SHALL support patient-initiated family connection requests
2. THE Backend SHALL create Connection record between patient and family member with status PENDING
3. THE Backend SHALL send CONNECTION_REQUEST notification to family member
4. WHEN family member accepts, THE Backend SHALL update connection status to ACCEPTED
5. THE Backend SHALL allow patient to set permission level for family member access
6. THE Backend SHALL enable mutual view of history records after connection (controlled by permissions)
7. WHEN patient misses a dose (status becomes MISSED), THE Backend SHALL send MISSED_DOSE_ALERT to connected family members
8. WHEN patient is online and misses dose, THE Backend SHALL send alert to family immediately
9. WHEN patient is offline and misses dose, THE Backend SHALL store missed state locally and send alert after sync
10. THE Backend SHALL include "sent after reconnect" indicator in late family notifications
11. THE Backend SHALL log all family notifications in audit log
12. THE Backend SHALL allow patient to revoke family connection at any time
13. WHEN connection is revoked, THE Backend SHALL immediately remove family member's access
14. THE Backend SHALL update connection status to REVOKED and set revokedAt timestamp
15. THE Backend SHALL log connection revocation in audit log

**User Story:** As a patient or doctor, I want connection requests to require mutual acceptance, so that both parties consent to the relationship.

#### Acceptance Criteria

1. THE Backend SHALL support doctor-initiated connection requests to patients
2. THE Backend SHALL support patient-initiated connection requests to doctors
3. THE Backend SHALL create Connection record with status PENDING when request is initiated
4. THE Backend SHALL send notification to recipient when connection request is received
5. THE Backend SHALL provide endpoint POST /api/connections/:connectionId/accept for accepting requests
6. THE Backend SHALL provide endpoint POST /api/connections/:connectionId/decline for declining requests
7. WHEN connection is accepted, THE Backend SHALL update status to ACCEPTED and set acceptedAt timestamp
8. WHEN connection is accepted, THE Backend SHALL show permission popup to patient (regardless of who initiated)
9. THE Backend SHALL apply default permission level ALLOWED (history/report view) if patient clicks OK without selecting
10. THE Backend SHALL allow patient to set permission level: NOT_ALLOWED, REQUEST, SELECTED, or ALLOWED
11. THE Backend SHALL log all connection requests, acceptances, and declines in audit log
12. THE Backend SHALL prevent duplicate connection requests between same users
13. THE Backend SHALL allow patient to change doctor permission level at any time after connection
14. THE Backend SHALL enforce permission levels when doctor attempts to access patient data
15. THE Backend SHALL provide endpoint POST /api/connections/:connectionId/revoke for revoking connections
