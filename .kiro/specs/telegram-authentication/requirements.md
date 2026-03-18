# Requirements Document

## Introduction

This document specifies the requirements for integrating Telegram as an additional authentication method in the DasTern medication reminder system. The feature will allow users to authenticate using their Telegram account alongside existing Google and email/password authentication methods. The implementation must maintain backward compatibility with existing authentication flows and follow OAuth 2.0 security best practices with Telegram-specific hash verification.

## Glossary

- **Auth_Service**: The NestJS authentication service responsible for user authentication and JWT token generation
- **Telegram_Auth_Module**: The new authentication module that handles Telegram Login Widget flow and hash verification
- **Flutter_App**: The mobile application (das_tern_mcp) that initiates authentication requests
- **User_Entity**: The PostgreSQL database entity representing user accounts
- **JWT_Token**: JSON Web Token used for authenticated session management
- **Deep_Link**: Application-specific URI scheme (myapp://login-success) used to return control to the Flutter app
- **Hash_Verification**: HMAC SHA256-based validation of Telegram authentication response integrity using bot token
- **Auth_Date**: Unix timestamp from Telegram indicating when authentication occurred (must be within 24 hours)
- **Telegram_ID**: Unique identifier assigned by Telegram to each user account
- **Bot_Token**: Secret token provided by @BotFather used for HMAC verification (format: NUMBER:LETTERS_AND_NUMBERS)
- **Bot_ID**: Numeric part of Bot_Token (before the colon) used in window.Telegram.Login.auth
- **Telegram_Login_Widget**: JavaScript widget loaded from https://telegram.org/js/telegram-widget.js that provides window.Telegram.Login.auth function

## Requirements

### Requirement 1: Telegram Login Widget Integration

**User Story:** As a user, I want to click "Continue with Telegram" in the mobile app, so that I can authenticate using my Telegram account

#### Acceptance Criteria

1. THE Flutter_App SHALL display a "Continue with Telegram" button on the login screen
2. WHEN the user taps the "Continue with Telegram" button, THE Flutter_App SHALL load the Telegram Login Widget script (https://telegram.org/js/telegram-widget.js) in a WebView
3. THE Flutter_App SHALL call window.Telegram.Login.auth() with bot_id and request_access parameters
4. THE Flutter_App SHALL handle the authentication callback with user data (id, first_name, last_name, username, photo_url, auth_date, hash)
5. THE Flutter_App SHALL support both English and Khmer localization for the button text
6. THE Flutter_App SHALL register a deep link handler for the myapp://login-success scheme

### Requirement 2: Backend Telegram Authentication Endpoints

**User Story:** As a backend system, I want to provide Telegram authentication endpoints, so that I can process authentication data and generate JWT tokens

#### Acceptance Criteria

1. THE Auth_Service SHALL expose a POST endpoint at /auth/telegram for receiving Telegram authentication data from Flutter app
2. WHEN the /auth/telegram endpoint receives authentication data, THE Auth_Service SHALL extract all Telegram response parameters (id, first_name, last_name, username, photo_url, auth_date, hash)
3. THE Auth_Service SHALL verify the HMAC SHA256 hash using the bot token
4. THE Auth_Service SHALL validate the auth_date is within 24 hours
5. THE Auth_Service SHALL apply rate limiting of 10 requests per minute to the /auth/telegram endpoint

### Requirement 3: Telegram Response Hash Verification

**User Story:** As a security system, I want to verify Telegram authentication responses using HMAC SHA256, so that I can prevent authentication forgery

#### Acceptance Criteria

1. WHEN the Auth_Service receives Telegram authentication data, THE Telegram_Auth_Module SHALL create a secret key by computing SHA256 hash of the bot token
2. THE Telegram_Auth_Module SHALL construct the data check string by sorting all received parameters except 'hash' alphabetically and concatenating as key=value pairs separated by newlines
3. THE Telegram_Auth_Module SHALL compute HMAC SHA256 of the data check string using the secret key
4. THE Telegram_Auth_Module SHALL compare the computed hash with the hash provided by Telegram using constant-time comparison
5. IF the computed hash does not match the provided hash, THEN THE Telegram_Auth_Module SHALL reject the authentication request with a 401 Unauthorized error
6. THE Telegram_Auth_Module SHALL log all hash verification failures for security monitoring

### Requirement 4: Authentication Date Validation

**User Story:** As a security system, I want to reject outdated authentication attempts, so that I can prevent replay attacks

#### Acceptance Criteria

1. WHEN the Auth_Service receives Telegram authentication data, THE Telegram_Auth_Module SHALL extract the auth_date parameter
2. THE Telegram_Auth_Module SHALL calculate the time difference between the current server time and the auth_date
3. IF the auth_date is older than 86400 seconds (24 hours), THEN THE Telegram_Auth_Module SHALL reject the authentication request with a 401 Unauthorized error
4. THE Telegram_Auth_Module SHALL return a descriptive error message indicating the authentication data has expired
5. THE Telegram_Auth_Module SHALL log rejected authentication attempts with expired auth_date values

### Requirement 5: User Account Linking and Creation

**User Story:** As a user, I want my Telegram account to be linked to my DasTern account, so that I can log in seamlessly

#### Acceptance Criteria

1. WHEN a valid Telegram authentication is received, THE Auth_Service SHALL query the User_Entity by telegram_id
2. IF a User_Entity with the matching telegram_id exists, THEN THE Auth_Service SHALL authenticate the existing user
3. IF no User_Entity with the matching telegram_id exists, THEN THE Auth_Service SHALL create a new User_Entity with Telegram profile data
4. WHEN creating a new user, THE Auth_Service SHALL set the accountStatus to ACTIVE
5. WHEN creating a new user, THE Auth_Service SHALL set the role to PATIENT by default
6. WHEN creating a new user, THE Auth_Service SHALL generate a random password hash for security compliance
7. WHEN creating a new user, THE Auth_Service SHALL create a default subscription with 1-month Premium trial
8. THE Auth_Service SHALL update existing User_Entity records with Telegram profile data if telegram_id is not set but email matches

### Requirement 6: User Entity Schema Extension

**User Story:** As a database system, I want to store Telegram user information, so that I can support Telegram authentication

#### Acceptance Criteria

1. THE User_Entity SHALL include a telegram_id field of type string that is nullable and unique
2. THE User_Entity SHALL include a telegram_username field of type string that is nullable
3. THE User_Entity SHALL include a telegram_first_name field of type string that is nullable
4. THE User_Entity SHALL include a telegram_last_name field of type string that is nullable
5. THE User_Entity SHALL include a telegram_photo_url field of type string that is nullable
6. THE User_Entity SHALL maintain backward compatibility with existing user records where Telegram fields are null
7. THE User_Entity SHALL enforce uniqueness constraint on telegram_id to prevent duplicate Telegram account linking

### Requirement 7: JWT Token Generation and Response

**User Story:** As a backend system, I want to generate JWT tokens and return them to the mobile app, so that users can complete authentication

#### Acceptance Criteria

1. WHEN Telegram authentication succeeds, THE Auth_Service SHALL generate a JWT_Token using the existing token generation method
2. THE JWT_Token SHALL include the user ID, role, and Telegram_ID in the payload
3. THE Auth_Service SHALL return a JSON response with the JWT token and user data
4. THE Flutter_App SHALL receive the JWT token from the API response
5. THE Flutter_App SHALL store the JWT_Token using secure storage (flutter_secure_storage)
6. WHEN the JWT_Token is stored, THE Flutter_App SHALL navigate the user to the home screen
7. THE Auth_Service SHALL use the same JWT expiration settings as existing authentication methods

### Requirement 8: Security Parameter Validation

**User Story:** As a security system, I want to validate all Telegram response parameters, so that I can prevent malicious authentication attempts

#### Acceptance Criteria

1. THE Telegram_Auth_Module SHALL validate that all required Telegram parameters (id, first_name, auth_date, hash) are present
2. IF any required parameter is missing, THEN THE Telegram_Auth_Module SHALL reject the request with a 400 Bad Request error
3. THE Telegram_Auth_Module SHALL validate that the Telegram ID is a positive integer
4. THE Telegram_Auth_Module SHALL validate that the auth_date is a valid Unix timestamp
5. THE Telegram_Auth_Module SHALL reject requests with invalid parameter types or formats
6. THE Telegram_Auth_Module SHALL sanitize all string parameters to prevent injection attacks
7. THE Telegram_Auth_Module SHALL enforce HTTPS for all authentication endpoints in production

### Requirement 9: Authentication Flow Error Handling

**User Story:** As a user, I want to receive clear error messages when authentication fails, so that I can understand what went wrong

#### Acceptance Criteria

1. WHEN hash verification fails, THE Auth_Service SHALL return an error message "Invalid authentication data"
2. WHEN auth_date validation fails, THE Auth_Service SHALL return an error message "Authentication data has expired"
3. WHEN Telegram API is unavailable, THE Auth_Service SHALL return an error message "Authentication service temporarily unavailable"
4. WHEN user creation fails, THE Auth_Service SHALL return an error message "Failed to create user account"
5. THE Flutter_App SHALL display error messages to the user in a user-friendly dialog
6. THE Flutter_App SHALL provide a "Try Again" button when authentication fails
7. THE Auth_Service SHALL log all authentication errors with sufficient detail for debugging

### Requirement 10: Backward Compatibility with Existing Authentication

**User Story:** As a system administrator, I want Telegram authentication to coexist with existing methods, so that current users are not affected

#### Acceptance Criteria

1. THE Auth_Service SHALL maintain all existing authentication endpoints without modification
2. THE Auth_Service SHALL continue to support Google OAuth authentication
3. THE Auth_Service SHALL continue to support email/password authentication
4. THE Auth_Service SHALL continue to support OTP-based authentication
5. THE User_Entity SHALL allow users to have multiple authentication methods linked to the same account
6. WHEN a user with existing Google authentication links a Telegram account, THE Auth_Service SHALL update the User_Entity without creating a duplicate
7. THE JWT_Token generation logic SHALL remain consistent across all authentication methods

### Requirement 11: WebView Integration and Token Storage

**User Story:** As a mobile app, I want to integrate Telegram Login Widget in a WebView and store JWT tokens securely, so that users can complete authentication

#### Acceptance Criteria

1. THE Flutter_App SHALL load the Telegram Login Widget script in a WebView or use flutter_inappwebview
2. THE Flutter_App SHALL inject JavaScript to call window.Telegram.Login.auth() with bot_id parameter
3. THE Flutter_App SHALL capture the authentication callback data from JavaScript
4. THE Flutter_App SHALL send the authentication data to the backend POST /auth/telegram endpoint
5. THE Flutter_App SHALL store the JWT_Token using secure storage (flutter_secure_storage)
6. THE Flutter_App SHALL verify the JWT_Token is valid before navigating to the home screen
7. IF authentication fails, THEN THE Flutter_App SHALL display an error message and remain on the login screen

### Requirement 12: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive tests for Telegram authentication, so that I can ensure the feature works correctly

#### Acceptance Criteria

1. THE Telegram_Auth_Module SHALL include unit tests for HMAC SHA256 hash verification with valid and invalid hashes
2. THE Telegram_Auth_Module SHALL include unit tests for auth_date validation with current, expired, and future timestamps
3. THE Auth_Service SHALL include integration tests for the complete Telegram authentication flow
4. THE Flutter_App SHALL include widget tests for the "Continue with Telegram" button and deep link handling
5. THE Auth_Service SHALL include security tests for invalid Telegram responses and parameter tampering
6. THE Auth_Service SHALL include tests for user creation and account linking scenarios
7. THE Flutter_App SHALL include end-to-end tests for the complete authentication flow from button tap to home screen navigation
