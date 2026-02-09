# Implementation Tasks: Das Tern Backend and Database

## Overview

This task list covers the implementation of the Das Tern Backend and Database system based on the requirements and design documents. Tasks are organized by functional area and prioritized for incremental development.

---

## Phase 1: Infrastructure Setup

### 1. Docker Infrastructure
- [x] 1.1 Create docker-compose.yml with PostgreSQL 16 service
- [x] 1.2 Create docker-compose.yml with Redis 7 service
- [x] 1.3 Configure persistent volumes for PostgreSQL data
- [x] 1.4 Configure persistent volumes for Redis data
- [x] 1.5 Set up health checks for PostgreSQL and Redis
- [x] 1.6 Configure environment variables for database credentials
- [x] 1.7 Set timezone to Asia/Phnom_Penh for PostgreSQL
- [x] 1.8 Test Docker services startup and connectivity

### 2. Database Schema & Migrations
- [x] 2.1 Verify Prisma schema matches all requirements (already exists)
- [x] 2.2 Generate initial Prisma migration
- [x] 2.3 Apply migration to development database
- [x] 2.4 Verify all indexes are created correctly
- [x] 2.5 Verify all foreign key constraints are in place
- [x] 2.6 Test database connection pooling configuration
- [x] 2.7 Create database seed script for development data
- [x] 2.8 Test seed script execution

### 3. Redis Configuration
- [x] 3.1 Configure Redis client with connection pooling
- [x] 3.2 Implement cache helper functions (get, set, del, exists, incr)
- [x] 3.3 Configure Redis maxmemory policy (allkeys-lru)
- [x] 3.4 Test Redis connection and reconnection logic
- [x] 3.5 Implement cache key namespacing strategy
- [x] 3.6 Test cache TTL expiration
- [ ] 2.3 Apply migration to development database
- [ ] 2.4 Verify all indexes are created correctly
- [ ] 2.5 Verify all foreign key constraints are in place
- [ ] 2.6 Test database connection pooling configuration
- [ ] 2.7 Create database seed script for development data
- [ ] 2.8 Test seed script execution

### 3. Redis Configuration
- [ ] 3.1 Configure Redis client with connection pooling
- [ ] 3.2 Implement cache helper functions (get, set, del, exists, incr)
- [ ] 3.3 Configure Redis maxmemory policy (allkeys-lru)
- [ ] 3.4 Test Redis connection and reconnection logic
- [ ] 3.5 Implement cache key namespacing strategy
- [ ] 3.6 Test cache TTL expiration

---

## Phase 2: Core Authentication & Authorization

### 4. NextAuth.js Setup
- [ ] 4.1 Configure NextAuth.js v5 with JWT strategy
- [ ] 4.2 Implement Credentials provider for phone/email login
- [ ] 4.3 Configure Google OAuth provider
- [ ] 4.4 Implement JWT callbacks for custom claims
- [ ] 4.5 Implement session callbacks for user data
- [ ] 4.6 Configure JWT expiration (15 min access, 7 day refresh)
- [ ] 4.7 Implement token rotation for refresh tokens
- [ ] 4.8 Store refresh tokens in Redis with expiration

### 5. Authentication Endpoints
- [ ] 5.1 Create POST /api/auth/register/patient endpoint
- [ ] 5.2 Create POST /api/auth/register/doctor endpoint
- [ ] 5.3 Create POST /api/auth/login endpoint
- [ ] 5.4 Create POST /api/auth/otp/send endpoint
- [ ] 5.5 Create POST /api/auth/otp/verify endpoint
- [ ] 5.6 Create POST /api/auth/refresh endpoint
- [ ] 5.7 Create POST /api/auth/logout endpoint
- [ ] 5.8 Implement password hashing with bcrypt (10 rounds)
- [ ] 5.9 Implement PIN code hashing with bcrypt (10 rounds)

### 6. Zod Validation Schemas
- [ ] 6.1 Create patientRegistrationSchema with age validation (>= 13)
- [ ] 6.2 Create doctorRegistrationSchema with license validation
- [ ] 6.3 Create loginSchema for phone/email and password
- [ ] 6.4 Create otpVerifySchema for 4-digit OTP
- [ ] 6.5 Create prescriptionCreateSchema with medication validation
- [ ] 6.6 Create prescriptionUpdateSchema
- [ ] 6.7 Create doseEventSchemas (markTaken, skip, updateReminderTime)
- [ ] 6.8 Add custom error messages in Khmer and English

---

## Phase 3: User Management

### 7. User Service
- [ ] 7.1 Implement getProfile() with Redis caching (5 min TTL)
- [ ] 7.2 Implement updateProfile() with cache invalidation
- [ ] 7.3 Implement calculateStorageUsage()
- [ ] 7.4 Implement getUsersByRole() for searching doctors
- [ ] 7.5 Implement account lockout logic (5 failed attempts, 15 min lock)
- [ ] 7.6 Implement password change with token invalidation
- [ ] 7.7 Test user profile caching and invalidation

### 8. User Endpoints
- [ ] 8.1 Create GET /api/users/profile endpoint
- [ ] 8.2 Create PUT /api/users/profile endpoint
- [ ] 8.3 Create GET /api/users/storage endpoint
- [ ] 8.4 Create GET /api/users/search endpoint (for finding doctors)
- [ ] 8.5 Implement authentication middleware for protected routes
- [ ] 8.6 Implement role-based authorization middleware

---

## Phase 4: Connection Management

### 9. Connection Service
- [ ] 9.1 Implement createConnectionRequest() for doctor-initiated
- [ ] 9.2 Implement createConnectionRequest() for patient-initiated
- [ ] 9.3 Implement acceptConnection() with permission setting
- [ ] 9.4 Implement declineConnection()
- [ ] 9.5 Implement revokeConnection() with immediate access removal
- [ ] 9.6 Implement updatePermissionLevel() for patients
- [ ] 9.7 Implement validateAccess() for permission enforcement
- [ ] 9.8 Implement getConnections() with filtering
- [ ] 9.9 Test mutual acceptance flow
- [ ] 9.10 Test permission level enforcement

### 10. Connection Endpoints
- [ ] 10.1 Create POST /api/connections endpoint (initiate request)
- [ ] 10.2 Create GET /api/connections endpoint (list connections)
- [ ] 10.3 Create POST /api/connections/:id/accept endpoint
- [ ] 10.4 Create POST /api/connections/:id/decline endpoint
- [ ] 10.5 Create POST /api/connections/:id/revoke endpoint
- [ ] 10.6 Create PUT /api/connections/:id/permission endpoint
- [ ] 10.7 Implement connection request notifications
- [ ] 10.8 Test duplicate connection prevention

---

## Phase 5: Prescription Management

### 11. Prescription Service
- [ ] 11.1 Implement createPrescription() with permission validation
- [ ] 11.2 Implement updatePrescription() with version creation
- [ ] 11.3 Implement urgentUpdatePrescription() with auto-apply
- [ ] 11.4 Implement getPrescriptions() with filtering and pagination
- [ ] 11.5 Implement getPrescriptionHistory() with versions
- [ ] 11.6 Implement confirmPrescription() for patient acceptance
- [ ] 11.7 Implement retakePrescription() for patient rejection
- [ ] 11.8 Implement prescription status transitions (Draft → Active → Paused → Inactive)
- [ ] 11.9 Test version control and history tracking
- [ ] 11.10 Test urgent auto-apply with audit logging

### 12. Prescription Endpoints
- [ ] 12.1 Create POST /api/prescriptions endpoint
- [ ] 12.2 Create GET /api/prescriptions endpoint with filters
- [ ] 12.3 Create GET /api/prescriptions/:id endpoint
- [ ] 12.4 Create PUT /api/prescriptions/:id endpoint
- [ ] 12.5 Create POST /api/prescriptions/:id/confirm endpoint
- [ ] 12.6 Create POST /api/prescriptions/:id/retake endpoint
- [ ] 12.7 Create GET /api/prescriptions/:id/history endpoint
- [ ] 12.8 Implement urgent prescription notifications

---

## Phase 6: Dose Tracking & Reminders

### 13. Dose Service
- [ ] 13.1 Implement generateDoseEvents() for active prescriptions
- [ ] 13.2 Implement regenerateDoseEvents() for prescription updates
- [ ] 13.3 Implement markDoseTaken() with time window validation
- [ ] 13.4 Implement skipDose() with reason
- [ ] 13.5 Implement detectMissedDoses() with cutoff logic
- [ ] 13.6 Implement updateReminderTime() for individual doses
- [ ] 13.7 Implement getDoseSchedule() with date filtering
- [ ] 13.8 Implement getDoseHistory() with pagination
- [ ] 13.9 Calculate dose status (DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED)
- [ ] 13.10 Test time window logic for on-time vs late

### 14. Dose Endpoints
- [ ] 14.1 Create GET /api/doses/schedule endpoint
- [ ] 14.2 Create GET /api/doses/history endpoint
- [ ] 14.3 Create POST /api/doses/:id/mark-taken endpoint
- [ ] 14.4 Create POST /api/doses/:id/skip endpoint
- [ ] 14.5 Create PUT /api/doses/:id/reminder-time endpoint
- [ ] 14.6 Implement dose event caching (1 min TTL)

---

## Phase 7: Offline Sync

### 15. Sync Service
- [ ] 15.1 Implement processBatchSync() for offline actions
- [ ] 15.2 Implement validateSyncAction() for timestamp and ownership
- [ ] 15.3 Implement detectConflicts() for server state comparison
- [ ] 15.4 Implement resolveConflict() with server-wins strategy
- [ ] 15.5 Implement applySyncAction() for DOSE_TAKEN
- [ ] 15.6 Implement applySyncAction() for DOSE_SKIPPED
- [ ] 15.7 Implement applySyncAction() for PRESCRIPTION_UPDATED
- [ ] 15.8 Mark synced dose events with wasOffline flag
- [ ] 15.9 Trigger family notifications after offline sync
- [ ] 15.10 Implement idempotency for duplicate sync requests
- [ ] 15.11 Test batch sync with up to 100 actions
- [ ] 15.12 Test conflict detection and resolution

### 16. Sync Endpoints
- [ ] 16.1 Create POST /api/sync/batch endpoint
- [ ] 16.2 Create GET /api/sync/status endpoint
- [ ] 16.3 Return sync summary with applied/conflict counts
- [ ] 16.4 Implement sync action validation
- [ ] 16.5 Test offline sync with late notifications

---

## Phase 8: Notifications

### 17. Notification Service
- [ ] 17.1 Implement createNotification() for all notification types
- [ ] 17.2 Implement sendConnectionRequest() notification
- [ ] 17.3 Implement sendPrescriptionUpdate() notification
- [ ] 17.4 Implement sendMissedDoseAlert() to family
- [ ] 17.5 Implement sendUrgentPrescriptionChange() notification
- [ ] 17.6 Implement sendFamilyAlert() with late indicator
- [ ] 17.7 Implement getNotifications() with filtering
- [ ] 17.8 Implement markNotificationRead()
- [ ] 17.9 Add "sent after reconnect" indicator for late notifications
- [ ] 17.10 Test notification delivery for online and offline scenarios

### 18. Notification Endpoints
- [ ] 18.1 Create GET /api/notifications endpoint
- [ ] 18.2 Create POST /api/notifications/:id/read endpoint
- [ ] 18.3 Create GET /api/notifications/stream endpoint (SSE or WebSocket)
- [ ] 18.4 Implement real-time notification delivery
- [ ] 18.5 Test notification filtering by type and read status

---

## Phase 9: Audit Logging

### 19. Audit Service
- [ ] 19.1 Implement logAction() for all audit events
- [ ] 19.2 Implement logConnectionAction()
- [ ] 19.3 Implement logPrescriptionAction() with urgent flag
- [ ] 19.4 Implement logDoseAction() with offline indicator
- [ ] 19.5 Implement logPermissionChange()
- [ ] 19.6 Implement logDataAccess()
- [ ] 19.7 Implement logNotificationSent()
- [ ] 19.8 Implement logSubscriptionChange()
- [ ] 19.9 Capture IP address from request headers
- [ ] 19.10 Test audit log immutability

### 20. Audit Endpoints
- [ ] 20.1 Create GET /api/audit-logs endpoint with authentication
- [ ] 20.2 Implement filtering by date range
- [ ] 20.3 Implement filtering by action type
- [ ] 20.4 Implement filtering by actor
- [ ] 20.5 Implement filtering by resource type
- [ ] 20.6 Return audit logs in reverse chronological order
- [ ] 20.7 Implement pagination (default 50 per page)
- [ ] 20.8 Include actor details in response
- [ ] 20.9 Enforce authorization (users view own logs only)

---

## Phase 10: Subscription Management

### 21. Subscription Service
- [ ] 21.1 Implement createSubscription() with default FREEMIUM tier
- [ ] 21.2 Implement upgradeSubscription() to PREMIUM
- [ ] 21.3 Implement upgradeSubscription() to FAMILY_PREMIUM
- [ ] 21.4 Implement addFamilyMember() with 3-member limit
- [ ] 21.5 Implement removeFamilyMember()
- [ ] 21.6 Implement updateStorageQuota() on tier change
- [ ] 21.7 Implement calculateStorageUsed()
- [ ] 21.8 Implement enforceStorageQuota() on uploads
- [ ] 21.9 Test subscription upgrade flow
- [ ] 21.10 Test family member limit enforcement

### 22. Subscription Endpoints
- [ ] 22.1 Create POST /api/subscriptions/upgrade endpoint
- [ ] 22.2 Create GET /api/subscriptions/current endpoint
- [ ] 22.3 Create POST /api/subscriptions/family/add-member endpoint
- [ ] 22.4 Create DELETE /api/subscriptions/family/remove-member endpoint
- [ ] 22.5 Implement payment validation (mock for MVP)
- [ ] 22.6 Send confirmation notification after upgrade

---

## Phase 11: Meal Time Preferences

### 23. Meal Time Service
- [ ] 23.1 Implement saveMealTimePreference()
- [ ] 23.2 Implement getMealTimePreference()
- [ ] 23.3 Implement getDefaultMealTimes() for Cambodia timezone
- [ ] 23.4 Implement calculateReminderTime() using preferences
- [ ] 23.5 Apply defaults for PRN medications without custom times
- [ ] 23.6 Test meal time preference usage in dose generation

### 24. Meal Time Endpoints
- [ ] 24.1 Create POST /api/onboarding/meal-times endpoint
- [ ] 24.2 Create GET /api/onboarding/meal-times endpoint
- [ ] 24.3 Create PUT /api/onboarding/meal-times endpoint
- [ ] 24.4 Return default presets when no preferences exist

---

## Phase 12: Middleware & Error Handling

### 25. Middleware Stack
- [ ] 25.1 Implement authMiddleware for JWT verification
- [ ] 25.2 Implement roleAuthorizationMiddleware
- [ ] 25.3 Implement validationMiddleware using Zod schemas
- [ ] 25.4 Implement rateLimitMiddleware using Redis
- [ ] 25.5 Implement errorHandlerMiddleware with consistent format
- [ ] 25.6 Implement auditLoggerMiddleware for mutations
- [ ] 25.7 Implement corsMiddleware for Flutter app
- [ ] 25.8 Implement requestLoggingMiddleware
- [ ] 25.9 Test middleware execution order

### 26. Error Handling
- [ ] 26.1 Map Prisma errors to HTTP status codes
- [ ] 26.2 Map Zod validation errors to HTTP 400
- [ ] 26.3 Implement multi-language error messages
- [ ] 26.4 Sanitize error messages for production
- [ ] 26.5 Include error stack traces in development only
- [ ] 26.6 Test error response format consistency

---

## Phase 13: Rate Limiting

### 27. Rate Limiting
- [ ] 27.1 Implement rate limiting for auth endpoints (5 req/min)
- [ ] 27.2 Implement rate limiting for OTP endpoint (3 req/hour)
- [ ] 27.3 Implement rate limiting for API endpoints (100 req/min)
- [ ] 27.4 Implement rate limiting for file uploads (10 req/hour)
- [ ] 27.5 Return rate limit headers (X-RateLimit-*)
- [ ] 27.6 Return HTTP 429 with retry-after header
- [ ] 27.7 Log rate limit violations
- [ ] 27.8 Test rate limit enforcement

---

## Phase 14: File Storage

### 28. Storage Service
- [ ] 28.1 Configure AWS S3 or compatible storage
- [ ] 28.2 Implement uploadFile() with type validation
- [ ] 28.3 Implement uploadFile() with size validation (5MB images, 10MB PDFs)
- [ ] 28.4 Generate unique filenames using UUID
- [ ] 28.5 Organize files in folders (licenses/, medications/)
- [ ] 28.6 Generate pre-signed URLs (1 hour expiration)
- [ ] 28.7 Implement deleteFile() on record deletion
- [ ] 28.8 Update storage quota on file operations
- [ ] 28.9 Compress images before upload
- [ ] 28.10 Test file upload and retrieval

---

## Phase 15: SMS Integration

### 29. SMS Service
- [ ] 29.1 Configure Twilio or AWS SNS
- [ ] 29.2 Implement sendOTP() for 4-digit codes
- [ ] 29.3 Store OTP in Redis with 5-minute expiration
- [ ] 29.4 Implement OTP resend with 60-second cooldown
- [ ] 29.5 Limit OTP attempts to 5 per hour per phone
- [ ] 29.6 Create SMS templates in Khmer and English
- [ ] 29.7 Log SMS delivery status
- [ ] 29.8 Implement fallback to email OTP
- [ ] 29.9 Test OTP delivery and verification

---

## Phase 16: Timezone & Localization

### 30. Timezone Utilities
- [ ] 30.1 Implement toCambodiaTime() conversion
- [ ] 30.2 Implement fromCambodiaTime() conversion
- [ ] 30.3 Implement formatCambodiaTime() with date-fns-tz
- [ ] 30.4 Use Cambodia timezone for all dose calculations
- [ ] 30.5 Return timestamps in ISO 8601 with timezone offset
- [ ] 30.6 Test timezone conversion accuracy

### 31. Language Utilities
- [ ] 31.1 Implement getErrorMessage() for Khmer/English
- [ ] 31.2 Create translation dictionary for common errors
- [ ] 31.3 Detect language from Accept-Language header
- [ ] 31.4 Return error messages in user's preferred language
- [ ] 31.5 Test multi-language error responses

---

## Phase 17: Doctor Dashboard

### 32. Doctor Service
- [ ] 32.1 Implement getPatients() for connected patients
- [ ] 32.2 Implement getPatientDetails() with permission check
- [ ] 32.3 Implement getPatientAdherence() statistics
- [ ] 32.4 Implement getPatientPrescriptions()
- [ ] 32.5 Test permission enforcement for patient data access

### 33. Doctor Endpoints
- [ ] 33.1 Create GET /api/doctor/patients endpoint
- [ ] 33.2 Create GET /api/doctor/patients/:id/details endpoint
- [ ] 33.3 Implement patient search and filtering
- [ ] 33.4 Return adherence statistics

---

## Phase 18: Health & Monitoring

### 34. Health & Metrics
- [ ] 34.1 Create GET /api/health endpoint
- [ ] 34.2 Create GET /api/metrics endpoint (protected)
- [ ] 34.3 Track request count, error rate, response time
- [ ] 34.4 Track database query time
- [ ] 34.5 Track business metrics (registrations, prescriptions, doses)
- [ ] 34.6 Track offline sync success rate
- [ ] 34.7 Track late notification delivery metrics
- [ ] 34.8 Implement structured logging (JSON format)
- [ ] 34.9 Configure log rotation (daily, 30-day retention)
- [ ] 34.10 Test health check endpoint

---

## Phase 19: Testing

### 35. Unit Tests
- [ ] 35.1 Write tests for User Service methods
- [ ] 35.2 Write tests for Auth Service methods
- [ ] 35.3 Write tests for Connection Service methods
- [ ] 35.4 Write tests for Prescription Service methods
- [ ] 35.5 Write tests for Dose Service methods
- [ ] 35.6 Write tests for Sync Service methods
- [ ] 35.7 Write tests for Notification Service methods
- [ ] 35.8 Write tests for Audit Service methods
- [ ] 35.9 Write tests for utility functions
- [ ] 35.10 Achieve 80% code coverage for service layer

### 36. Integration Tests
- [ ] 36.1 Write tests for authentication flow
- [ ] 36.2 Write tests for connection mutual acceptance
- [ ] 36.3 Write tests for prescription creation and updates
- [ ] 36.4 Write tests for urgent prescription auto-apply
- [ ] 36.5 Write tests for dose tracking and status transitions
- [ ] 36.6 Write tests for offline sync batch processing
- [ ] 36.7 Write tests for family missed-dose alerts
- [ ] 36.8 Write tests for subscription upgrades
- [ ] 36.9 Write tests for rate limiting
- [ ] 36.10 Write tests for error handling

### 37. Property-Based Tests
- [ ] 37.1 Test database persistence across restarts (Property 1)
- [ ] 37.2 Test Redis TTL expiration (Property 2)
- [ ] 37.3 Test Prisma transaction atomicity (Property 3)
- [ ] 37.4 Test database unique constraints (Property 4)
- [ ] 37.5 Test token rotation on refresh (Property 5)
- [ ] 37.6 Test token invalidation on password change (Property 6)
- [ ] 37.7 Test Google OAuth user creation (Property 7)
- [ ] 37.8 Test Google OAuth account linking (Property 8)
- [ ] 37.9 Test input validation rules (Property 9)
- [ ] 37.10 Test protected route authentication (Property 10)
- [ ] 37.11 Test rate limiting enforcement (Property 11)
- [ ] 37.12 Test error code mapping (Property 12)
- [ ] 37.13 Test cache invalidation on mutation (Property 13)
- [ ] 37.14 Test foreign key cascade behavior (Property 14)
- [ ] 37.15 Test Unicode text preservation (Property 15)
- [ ] 37.16 Test timezone conversion consistency (Property 16)
- [ ] 37.17 Test password and PIN hashing (Property 17)
- [ ] 37.18 Test account lockout after failed attempts (Property 18)
- [ ] 37.19 Test file upload validation (Property 19)
- [ ] 37.20 Test OTP resend cooldown (Property 20)
- [ ] 37.21 Test N+1 query prevention (Property 21)
- [ ] 37.22 Test subscription upgrade storage quota (Property 22)

---

## Phase 20: Documentation & Deployment

### 38. Documentation
- [ ] 38.1 Generate OpenAPI 3.0 specification
- [ ] 38.2 Document all API endpoints with examples
- [ ] 38.3 Document authentication requirements
- [ ] 38.4 Document error responses
- [ ] 38.5 Document rate limiting rules
- [ ] 38.6 Create Postman collection
- [ ] 38.7 Write deployment guide
- [ ] 38.8 Write backup and restore procedures
- [ ] 38.9 Update README with setup instructions

### 39. Deployment Configuration
- [ ] 39.1 Create Dockerfile with multi-stage build
- [ ] 39.2 Configure production environment variables
- [ ] 39.3 Set up database migrations for production
- [ ] 39.4 Configure CORS for production frontend
- [ ] 39.5 Enable HTTPS and secure cookies
- [ ] 39.6 Set up database backups (daily)
- [ ] 39.7 Configure monitoring and alerting
- [ ] 39.8 Set up CI/CD pipeline
- [ ] 39.9 Test production deployment
- [ ] 39.10 Create rollback procedures

---

## Summary

**Total Tasks**: 39 major sections with 300+ individual tasks

**Estimated Timeline**:
- Phase 1-3 (Infrastructure & Auth): 2-3 weeks
- Phase 4-6 (Core Features): 3-4 weeks
- Phase 7-8 (Offline & Notifications): 2-3 weeks
- Phase 9-14 (Supporting Features): 3-4 weeks
- Phase 15-18 (Utilities & Monitoring): 1-2 weeks
- Phase 19 (Testing): 2-3 weeks
- Phase 20 (Documentation & Deployment): 1 week

**Total Estimated Time**: 14-20 weeks for complete implementation

**Priority Order**:
1. Infrastructure (Phase 1)
2. Authentication (Phase 2-3)
3. Core Features (Phase 4-6)
4. Offline Sync (Phase 7)
5. Everything else can be done in parallel or as needed
