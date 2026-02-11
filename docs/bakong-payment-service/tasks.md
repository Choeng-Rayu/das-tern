# Implementation Plan: Bakong Payment Integration Backend Service( i arealdy set up project /home/rayu/das-tern/bakong_payment)

## Overview

This implementation plan breaks down the Bakong payment integration backend service into discrete, incremental tasks. The service will be built as a standalone Nest.js application with TypeScript, Prisma ORM, and PostgreSQL, integrating with Cambodia's Bakong payment system using the KHQR specification.

## Tasks

- [ ] 1. Project Setup and Infrastructure
  - Initialize Nest.js 11+ project with TypeScript and App Router
  - Configure Prisma ORM with PostgreSQL connection
  - Set up Redis client for caching and rate limiting
  - Configure environment variables and validation
  - Set up logging infrastructure with Winston
  - Create Docker Compose configuration for local development (PostgreSQL + Redis)
  - _Requirements: All requirements (infrastructure foundation)_

- [ ] 2. Database Schema and Migrations
  - [ ] 2.1 Create Prisma schema for payment transactions
    - Define PaymentTransaction model with all fields (id, userId, billNumber, md5Hash, amount, currency, status, qrCode, qrImagePath, deepLink, bakongData, timestamps)
    - Define PaymentStatus enum (PENDING, PAID, FAILED, TIMEOUT, EXPIRED, CANCELLED)
    - Define PlanType enum (PREMIUM, FAMILY_PREMIUM)
    - Add indexes for userId, billNumber, md5Hash, status, createdAt
    - _Requirements: 8.1_
  
  - [ ] 2.2 Create Prisma schema for subscriptions
    - Define Subscription model with billing cycle fields
    - Define SubscriptionStatus enum (PENDING, ACTIVE, EXPIRED, CANCELLED)
    - Add relation to PaymentTransaction
    - Add indexes for userId, status, NestBillingDate
    - _Requirements: 8.3_
  
  - [ ] 2.3 Create Prisma schema for audit and history tracking
    - Define PaymentStatusHistory model for payment status changes
    - Define SubscriptionStatusHistory model for subscription changes
    - Define WebhookNotification model for outgoing webhooks
    - Define AuditLog model for comprehensive logging
    - Add appropriate indexes and relations
    - _Requirements: 8.2, 8.4, 10.1, 10.2_
  
  - [ ] 2.4 Generate and run initial migration
    - Run `npx prisma migrate dev --name init`
    - Verify schema in database
    - Generate Prisma Client
    - _Requirements: 8.1, 8.3_

- [ ] 3. Bakong KHQR SDK Integration
  - [ ] 3.1 Implement KHQR client
    - Create BakongKHQR class with createQR method
    - Implement MD5 hash generation from QR string
    - Implement QR code image generation (PNG format)
    - Implement deep link generation for Bakong app
    - Add EMV QR code specification compliance
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [ ]* 3.2 Write property test for KHQR generation
    - **Property 1: Payment Reference Uniqueness**
    - **Property 2: QR Code Generation Flow**
    - Test that generated QR codes are valid KHQR format
    - Test that MD5 hashes are unique and correctly generated
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  
  - [ ] 3.3 Implement Bakong API client
    - Create BakongClient class for API communication
    - Implement checkPayment method using MD5 hash
    - Implement bulk payment checking (up to 50 transactions)
    - Add developer token authentication
    - Add retry logic with exponential backoff
    - Handle Bakong API error codes (400, 401, 403, 404, 429, 500, 504)
    - _Requirements: 2.1, 2.2, 2.3_
  
  - [ ]* 3.4 Write property test for payment status checking
    - **Property 5: Payment Status Transitions with History**
    - Test that payment status updates are correctly tracked
    - Test that status history records are created
    - _Requirements: 2.2, 2.3, 2.5_

- [ ] 4. Payment Service Implementation
  - [ ] 4.1 Implement payment initiation
    - Create PaymentService class
    - Implement initiatePayment method
    - Generate unique bill numbers
    - Create QR code using KHQR client
    - Store PaymentTransaction in database
    - Return QR code, MD5 hash, and deep link
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 8.1_
  
  - [ ]* 4.2 Write property test for payment initiation
    - **Property 1: Payment Reference Uniqueness**
    - **Property 2: QR Code Generation Flow**
    - **Property 22: Transaction Data Completeness**
    - Test that all required fields are stored
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 8.1_
  
  - [ ] 4.3 Implement payment status checking
    - Implement checkPaymentStatus method using MD5 hash
    - Query Bakong API for payment status
    - Update PaymentTransaction status if changed
    - Create PaymentStatusHistory record on status change
    - Handle PAID, FAILED, EXPIRED statuses
    - _Requirements: 2.2, 2.3, 2.5, 8.2_
  
  - [ ] 4.4 Implement payment monitoring service
    - Create AutoPaymentMonitor class
    - Implement background monitoring with configurable intervals
    - Support priority-based checking (high priority for upgrades)
    - Implement automatic timeout handling (15 minutes)
    - Add exponential backoff for retries
    - Implement automatic cleanup of expired transactions
    - _Requirements: 9.2, 9.3_
  
  - [ ]* 4.5 Write property test for payment monitoring
    - **Property 26: Payment Timeout Handling**
    - **Property 27: Operation Retry Logic**
    - Test that pending payments timeout after 15 minutes
    - Test that monitoring retries with exponential backoff
    - _Requirements: 9.2, 9.3_

- [ ] 5. Checkpoint - Ensure payment flow works
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Subscription Service Implementation
  - [ ] 6.1 Implement subscription creation
    - Create SubscriptionService class
    - Implement createSubscription method
    - Set startDate to payment completion timestamp
    - Calculate nextBillingDate as startDate + 30 days
    - Set status to ACTIVE
    - Create SubscriptionStatusHistory record
    - _Requirements: 3.1, 3.2, 3.3, 8.3, 8.4_
  
  - [ ]* 6.2 Write property test for subscription creation
    - **Property 6: Subscription Creation Consistency**
    - Test that startDate equals payment completedAt
    - Test that nextBillingDate = startDate + 30 days
    - Test that status is ACTIVE
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [ ] 6.3 Implement subscription renewal
    - Implement renewSubscription method
    - Extend nextBillingDate by 30 days
    - Update lastBillingDate
    - Handle renewal payment failures (set status to EXPIRED)
    - _Requirements: 3.4, 3.5_
  
  - [ ]* 6.4 Write property test for subscription renewal
    - **Property 7: Subscription Renewal Extension**
    - **Property 8: Subscription Termination**
    - Test that nextBillingDate extends by exactly 30 days
    - Test that failed renewals set status to EXPIRED
    - _Requirements: 3.4, 3.5_
  
  - [ ] 6.5 Implement subscription cancellation
    - Implement cancelSubscription method
    - Set status to CANCELLED
    - Record cancelledAt timestamp
    - Record cancellation reason
    - Create SubscriptionStatusHistory record
    - _Requirements: 3.6, 8.4_
  
  - [ ] 6.6 Implement plan upgrades and downgrades
    - Implement upgradeSubscription method with prorated calculation
    - Implement downgradeSubscription method with deferred application
    - Calculate prorated amounts: (newPrice - oldPrice) * (remainingDays / 30)
    - For upgrades: apply immediately after payment
    - For downgrades: schedule for next billing cycle
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ]* 6.7 Write property test for plan changes
    - **Property 9: Prorated Amount Calculation**
    - **Property 10: Plan Change Timing**
    - Test prorated calculation formula
    - Test immediate upgrade vs deferred downgrade
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 7. API Endpoints Implementation
  - [ ] 7.1 Implement payment creation endpoint
    - Create POST /api/payments/create route
    - Validate request parameters (userId, planType, amount, currency)
    - Call PaymentService.initiatePayment
    - Return QR code, MD5 hash, deep link, and transaction details
    - Handle errors and return appropriate status codes
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.3_
  
  - [ ] 7.2 Implement payment status endpoint
    - Create GET /api/payments/status/[md5] route
    - Call PaymentService.checkPaymentStatus
    - Return current payment status and details
    - _Requirements: 2.2, 2.3, 5.4_
  
  - [ ] 7.3 Implement payment monitoring endpoint
    - Create POST /api/payments/monitor route
    - Accept MD5 hash and monitoring options (timeout, interval, priority)
    - Start AutoPaymentMonitor for the transaction
    - Return monitoring status
    - _Requirements: 9.2, 9.3_
  
  - [ ] 7.4 Implement bulk payment check endpoint
    - Create POST /api/payments/bulk-check route
    - Accept array of MD5 hashes (max 50)
    - Call Bakong API bulk check
    - Update all transaction statuses
    - Return updated statuses
    - _Requirements: 2.2, 2.3_
  
  - [ ] 7.5 Implement payment history endpoint
    - Create GET /api/payments/history route
    - Accept userId and optional filters (status, date range)
    - Query PaymentTransaction with ordering by createdAt DESC
    - Return paginated results
    - _Requirements: 8.5_
  
  - [ ]* 7.6 Write property test for payment history query
    - **Property 24: Payment History Query Ordering**
    - Test that results are ordered by createdAt descending
    - Test that all user transactions are returned
    - _Requirements: 8.5_
  
  - [ ] 7.7 Implement subscription status endpoint
    - Create GET /api/subscriptions/status/[userId] route
    - Call SubscriptionService.getSubscriptionStatus
    - Return active subscription details
    - _Requirements: 5.5_
  
  - [ ] 7.8 Implement subscription upgrade endpoint
    - Create POST /api/subscriptions/upgrade route
    - Validate upgrade request (current plan, new plan)
    - Calculate prorated amount
    - Create payment transaction for prorated amount
    - Return payment details for QR generation
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 7.9 Implement subscription downgrade endpoint
    - Create POST /api/subscriptions/downgrade route
    - Validate downgrade request
    - Schedule plan change for next billing cycle
    - Return updated subscription details
    - _Requirements: 4.5_

- [ ] 8. Checkpoint - Ensure API endpoints work
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Authentication and Security
  - [ ] 9.1 Implement API key authentication middleware
    - Create auth middleware for API key validation
    - Extract API key from Authorization header (Bearer token)
    - Validate against MAIN_BACKEND_API_KEY environment variable
    - Return 401 Unauthorized for invalid/missing keys
    - Cache validated keys in Redis for performance
    - _Requirements: 5.1, 5.2, 7.5_
  
  - [ ]* 9.2 Write property test for authentication
    - **Property 11: API Key Authentication**
    - Test that invalid keys return 401
    - Test that missing keys return 401
    - Test that valid keys allow access
    - _Requirements: 5.1, 5.2_
  
  - [ ] 9.3 Implement rate limiting middleware
    - Create rate limit middleware using Redis
    - Configure limits: 100 requests/minute for authenticated requests
    - Implement IP-based blocking after 10 failed auth attempts in 5 minutes
    - Return 429 Too Many Requests when limit exceeded
    - _Requirements: 7.5_
  
  - [ ]* 9.4 Write property test for rate limiting
    - **Property 21: Authentication Rate Limiting**
    - Test that 10 failed attempts block IP
    - Test that rate limits are enforced
    - _Requirements: 7.5_
  
  - [ ] 9.5 Implement data encryption utilities
    - Create encryption utility using AES-256
    - Encrypt sensitive payment data at rest
    - Implement encryption for bakongData field
    - Add decryption methods for data retrieval
    - _Requirements: 7.1_
  
  - [ ]* 9.6 Write property test for encryption
    - **Property 18: Sensitive Data Encryption**
    - Test that sensitive fields are encrypted
    - Test that encryption/decryption is reversible
    - _Requirements: 7.1_

- [ ] 10. Notification Service Implementation
  - [ ] 10.1 Implement webhook notification service
    - Create NotificationService class
    - Implement notifyPaymentCompleted method
    - Implement notifySubscriptionActivated method
    - Implement notifySubscriptionExpired method
    - Generate HMAC-SHA256 signature for webhooks
    - Send POST request to MAIN_BACKEND_WEBHOOK_URL
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [ ]* 10.2 Write property test for webhook delivery
    - **Property 16: Webhook Notification Delivery**
    - Test that webhooks are created for payment/subscription events
    - Test that webhook payload includes all required data
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [ ] 10.3 Implement webhook retry logic
    - Implement retry mechanism with exponential backoff (1s, 2s, 4s)
    - Retry up to 3 times on failure
    - Store WebhookNotification records in database
    - Update status (PENDING, DELIVERED, FAILED)
    - Mark as FAILED after all retries exhausted
    - _Requirements: 6.4, 6.5, 9.5_
  
  - [ ]* 10.4 Write property test for webhook retries
    - **Property 17: Webhook Retry Logic**
    - Test that failed webhooks retry exactly 3 times
    - Test exponential backoff timing
    - Test that status is marked FAILED after retries
    - _Requirements: 6.4, 6.5_

- [ ] 11. Error Handling and Logging
  - [ ] 11.1 Implement error handling utilities
    - Create standardized error response format
    - Implement error classes for different error types
    - Add error handling for Bakong API errors (400, 401, 403, 404, 429, 500, 504)
    - Return 503 Service Unavailable when Bakong API is down
    - Log full stack traces for unexpected errors
    - Return generic error messages to clients
    - _Requirements: 1.5, 9.1, 9.4_
  
  - [ ]* 11.2 Write property test for error handling
    - **Property 3: QR Generation Error Handling**
    - **Property 25: External Service Error Responses**
    - Test that errors are logged with stack traces
    - Test that generic messages are returned to clients
    - _Requirements: 1.5, 9.1, 9.4_
  
  - [ ] 11.3 Implement comprehensive audit logging
    - Configure Winston logger with file and console transports
    - Implement payment initiation logging (userId, amount, billNumber)
    - Implement status change logging (oldStatus, newStatus, reason)
    - Implement API call logging (endpoint, parameters, response status)
    - Implement security event logging (failed auth, rate limits) with SECURITY level
    - Implement subscription renewal failure logging with alerts
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_
  
  - [ ]* 11.4 Write property test for audit logging
    - **Property 28: Payment Initiation Audit Logging**
    - **Property 29: Status Change Audit Logging**
    - **Property 32: Security Event Logging**
    - Test that audit logs are created for all events
    - Test that security events have SECURITY level
    - _Requirements: 10.1, 10.2, 10.5_

- [ ] 12. Checkpoint - Ensure security and logging work
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 13. Health Check and Monitoring
  - [ ] 13.1 Implement health check endpoint
    - Create GET /api/health route
    - Check database connectivity
    - Check Redis connectivity
    - Check Bakong API availability (optional)
    - Return 200 OK if all healthy, 503 if any service down
    - Include detailed status for each service
    - _Requirements: 9.1_
  
  - [ ] 13.2 Implement payment timeout cleanup job
    - Create background job to check for timed-out payments
    - Query payments with status PENDING older than 15 minutes
    - Update status to TIMEOUT
    - Create PaymentStatusHistory records
    - Run job every 5 minutes
    - _Requirements: 9.2_
  
  - [ ]* 13.3 Write property test for timeout handling
    - **Property 26: Payment Timeout Handling**
    - Test that payments older than 15 minutes are marked TIMEOUT
    - _Requirements: 9.2_

- [ ] 14. Integration and Testing
  - [ ]* 14.1 Write integration tests for payment flow
    - Test complete payment creation flow
    - Test payment status checking flow
    - Test payment monitoring flow
    - Mock Bakong API responses
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.2, 2.3_
  
  - [ ]* 14.2 Write integration tests for subscription flow
    - Test subscription creation after payment
    - Test subscription renewal
    - Test plan upgrades and downgrades
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ]* 14.3 Write integration tests for webhook notifications
    - Test webhook delivery to main backend
    - Test webhook retry logic
    - Mock main backend webhook endpoint
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [ ]* 14.4 Write unit tests for edge cases
    - Test duplicate payment confirmations (idempotency)
    - Test invalid MD5 hashes
    - Test expired QR codes
    - Test concurrent payment status updates
    - _Requirements: 7.3, 7.4_

- [ ] 15. Documentation and Deployment
  - [ ] 15.1 Create API documentation
    - Document all API endpoints with request/response examples
    - Document authentication requirements
    - Document error codes and responses
    - Create Postman collection or OpenAPI spec
    - _Requirements: All requirements_
  
  - [ ] 15.2 Create deployment documentation
    - Document environment variable configuration
    - Document Docker deployment steps
    - Document database migration process
    - Document monitoring and alerting setup
    - Create troubleshooting guide
    - _Requirements: All requirements_
  
  - [ ] 15.3 Set up Docker deployment
    - Create Dockerfile for Nest.js application
    - Create docker-compose.yml for production
    - Configure PostgreSQL and Redis containers
    - Set up volume mounts for persistence
    - Configure health checks
    - _Requirements: All requirements_

- [ ] 16. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional property-based and integration tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using fast-check
- Unit tests validate specific examples and edge cases
- The implementation follows the design document closely
- All code should be written in TypeScript with strict type checking
- Use Prisma for all database operations
- Use Redis for caching and rate limiting
- Follow Nest.js 11+ App Router conventions
- Implement comprehensive error handling and logging
- Ensure all sensitive data is encrypted at rest
- Test with Bakong sandbox environment before production deployment
