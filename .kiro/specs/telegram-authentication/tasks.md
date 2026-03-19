# Implementation Plan: Telegram Authentication

## Overview

This implementation plan breaks down the Telegram authentication feature into atomic tasks following the DasTern architecture. The sequence follows: database schema → backend implementation → frontend implementation → integration → testing. Each task is designed to be executed by a sub-agent with clear objectives and requirements references.

## Tasks

- [x] 1. Database schema migration for Telegram fields
  - Add nullable Telegram fields to User model in Prisma schema
  - Create migration file with telegramId, telegramUsername, telegramFirstName, telegramLastName, telegramPhotoUrl
  - Add unique constraint and index on telegramId
  - Run migration to update PostgreSQL database
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [x] 2. Backend: Telegram hash verification service
  - [x] 2.1 Create TelegramHashVerifier service
    - Implement HMAC SHA256 hash verification logic
    - Implement auth_date validation (24-hour expiry check)
    - Implement data check string construction (alphabetical sorting)
    - Add constant-time hash comparison for security
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ]* 2.2 Write unit tests for TelegramHashVerifier
    - Test valid hash verification
    - Test invalid hash rejection
    - Test auth_date validation with current, expired, and future timestamps
    - Test data check string construction
    - _Requirements: 12.1, 12.2_

- [x] 3. Backend: Telegram authentication DTOs
  - Create TelegramAuthDto with validation decorators
  - Create TelegramCallbackDto extending TelegramAuthDto
  - Add class-validator rules for all fields (id, first_name, last_name, username, photo_url, auth_date, hash)
  - Export DTOs from dto/index.ts
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 4. Backend: Telegram authentication service
  - [x] 4.1 Create TelegramAuthService
    - Implement validateTelegramAuth method with hash and auth_date verification
    - Implement findOrCreateUser method with account linking logic
    - Implement linkTelegramToExistingUser method for email-based linking
    - Add comprehensive error logging for security monitoring
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 9.7_
  
  - [ ]* 4.2 Write unit tests for TelegramAuthService
    - Test user creation for new Telegram users
    - Test account linking for existing users with matching email
    - Test user lookup by telegram_id
    - Test error handling for invalid data
    - _Requirements: 12.3, 12.6_

- [x] 5. Backend: Telegram authentication module
  - Create TelegramAuthModule with providers and exports
  - Import JwtModule and ConfigModule
  - Register TelegramAuthService and TelegramHashVerifier as providers
  - Export TelegramAuthService for use in AuthModule
  - _Requirements: 2.1, 2.2_

- [x] 6. Backend: Auth controller endpoints
  - [x] 6.1 Add POST /auth/telegram endpoint
    - Add rate limiting (5 requests per minute)
    - Implement telegramAuth handler method
    - Add DTO validation with TelegramAuthDto
    - _Requirements: 2.1, 2.4_
  
  - [x] 6.2 Add GET /auth/telegram/callback endpoint
    - Add rate limiting (10 requests per minute)
    - Implement telegramCallback handler method
    - Generate JWT token on successful authentication
    - Redirect to deep link with token (myapp://login-success?token=JWT)
    - _Requirements: 2.2, 2.3, 2.5, 7.1, 7.2, 7.3, 7.4_
  
  - [ ]* 6.3 Write integration tests for Telegram endpoints
    - Test complete authentication flow from callback to JWT generation
    - Test rate limiting enforcement
    - Test error responses for invalid data
    - _Requirements: 12.3, 12.5_

- [x] 7. Backend: Auth service extensions
  - [x] 7.1 Add telegramLogin method to AuthService
    - Integrate with TelegramAuthService
    - Return AuthResponse with JWT tokens
    - _Requirements: 2.1, 7.1, 7.7_
  
  - [x] 7.2 Add handleTelegramCallback method to AuthService
    - Validate Telegram data using TelegramAuthService
    - Find or create user with account linking
    - Generate JWT token with Telegram ID in payload
    - _Requirements: 2.2, 2.3, 5.1, 5.2, 5.3, 7.1, 7.2_
  
  - [x] 7.3 Update JWT payload to include telegramId
    - Extend JwtPayload interface with optional telegramId field
    - Include telegramId in token generation when available
    - _Requirements: 7.2, 7.7_

- [x] 8. Backend: Security middleware and error handling
  - [x] 8.1 Add HTTPS enforcement middleware for production
    - Create HttpsEnforcementMiddleware
    - Apply to auth routes in production environment only
    - _Requirements: 8.7_
  
  - [x] 8.2 Implement standardized error responses
    - Add error handlers for hash verification failures (401)
    - Add error handlers for auth_date expiry (401)
    - Add error handlers for missing parameters (400)
    - Add error handlers for user creation failures (500)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.7_

- [ ] 9. Checkpoint - Backend implementation complete
  - Ensure all backend tests pass
  - Verify database migrations applied successfully
  - Test endpoints manually with Postman or curl
  - Ask the user if questions arise

- [x] 10. Frontend: Deep link configuration
  - [x] 10.1 Configure deep link scheme in Android manifest
    - Add intent filter for myapp://login-success scheme
    - Configure launchMode and exported attributes
    - _Requirements: 1.5, 11.1_
  
  - [x] 10.2 Configure deep link scheme in iOS Info.plist
    - Add CFBundleURLTypes for myapp scheme
    - Configure URL handling
    - _Requirements: 1.5, 11.1_
  
  - [x] 10.3 Initialize deep link listener in main.dart
    - Add uni_links package initialization
    - Implement _initDeepLinkListener function
    - Implement _handleDeepLink function for login-success path
    - Handle both cold start and warm start deep links
    - _Requirements: 11.1, 11.2, 11.7_

- [x] 11. Frontend: Auth provider extensions
  - [x] 11.1 Add signInWithTelegram method to AuthProvider
    - Construct Telegram OAuth URL with bot credentials and callback URL
    - Launch external browser with url_launcher package
    - Handle browser launch failures with error messages
    - Add loading state management
    - _Requirements: 1.1, 1.2, 1.3, 9.5, 9.6_
  
  - [x] 11.2 Add handleTelegramCallback method to AuthProvider
    - Extract and validate token from deep link
    - Store JWT token in flutter_secure_storage
    - Fetch user profile with token
    - Update authentication state
    - Handle errors with user-friendly messages
    - _Requirements: 7.5, 7.6, 11.2, 11.3, 11.4, 11.5, 11.6_
  
  - [x] 11.3 Add _buildTelegramOAuthUrl helper method
    - Read TELEGRAM_BOT_USERNAME from environment
    - Read API_BASE_URL from environment
    - Construct OAuth URL with proper encoding
    - _Requirements: 1.3_
  
  - [ ]* 11.4 Write unit tests for AuthProvider Telegram methods
    - Test signInWithTelegram URL construction
    - Test handleTelegramCallback token extraction
    - Test error handling scenarios
    - _Requirements: 12.4_

- [x] 12. Frontend: Login screen UI
  - [x] 12.1 Add "Continue with Telegram" button to login screen
    - Add ElevatedButton.icon with Telegram icon
    - Style with Telegram brand color (#0088CC)
    - Wire to AuthProvider.signInWithTelegram
    - Position below Google sign-in button
    - _Requirements: 1.1, 1.4_
  
  - [x] 12.2 Add localization strings for Telegram button
    - Add "continueWithTelegram" to app_en.arb
    - Add "continueWithTelegram" to app_km.arb (Khmer translation)
    - Add error message strings for authentication failures
    - _Requirements: 1.4, 9.5_
  
  - [ ]* 12.3 Write widget tests for login screen
    - Test Telegram button renders correctly
    - Test button tap triggers signInWithTelegram
    - Test error dialog displays on failure
    - _Requirements: 12.4_

- [x] 13. Frontend: Error handling UI
  - Add _showErrorDialog method to display authentication errors
  - Implement "Try Again" button for retry functionality
  - Add localized error messages for all error scenarios
  - Test error display for hash verification, auth_date, and network failures
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 14. Integration: Environment configuration
  - Add TELEGRAM_BOT_TOKEN to backend .env file
  - Add TELEGRAM_BOT_USERNAME to backend .env file
  - Add TELEGRAM_BOT_USERNAME to Flutter .env file
  - Add API_BASE_URL to Flutter .env file (if not already present)
  - Document environment variables in README
  - _Requirements: 1.3, 2.1, 2.2_

- [ ] 15. Integration: End-to-end flow testing
  - [ ] 15.1 Test complete authentication flow
    - Test new user creation via Telegram
    - Test existing user login via Telegram
    - Test account linking for users with matching email
    - Verify JWT token generation and storage
    - Verify navigation to home screen after successful auth
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_
  
  - [ ] 15.2 Test backward compatibility
    - Verify Google OAuth still works
    - Verify email/password login still works
    - Verify OTP authentication still works
    - Verify existing users can link Telegram to their accounts
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_
  
  - [ ]* 15.3 Test security scenarios
    - Test hash verification with tampered data
    - Test auth_date validation with expired timestamps
    - Test rate limiting enforcement
    - Test HTTPS enforcement in production
    - _Requirements: 3.4, 4.3, 8.7, 12.5_

- [ ] 16. Code quality and linting
  - Run flutter analyze on das_tern_mcp and fix all issues (must have 0 issues)
  - Run ESLint on backend_nestjs and fix all issues
  - Ensure all TypeScript types are properly defined
  - Ensure all Dart code follows Flutter style guide
  - _Requirements: All (code quality affects all requirements)_

- [ ] 17. Final checkpoint - Complete feature validation
  - Ensure all tests pass (backend and frontend)
  - Verify flutter analyze shows 0 issues
  - Test complete flow on both Android and iOS devices
  - Verify all error scenarios display appropriate messages
  - Confirm backward compatibility with existing auth methods
  - Ask the user if questions arise or if ready for deployment

## Notes

- Tasks marked with `*` are optional testing tasks that can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- The sequence ensures dependencies are met (database → backend → frontend → integration)
- Checkpoints at tasks 9 and 17 ensure incremental validation
- All code must follow existing patterns from Google OAuth implementation
- Flutter analyze must show 0 issues before proceeding to testing phase
- Backend follows NestJS best practices with DTOs, services, and modules
- Frontend follows Flutter provider pattern with secure storage
