# Requirements Document

## Introduction

This document specifies the requirements for the Bakong Payment Integration backend service for the Das-tern medication management platform. Bakong is Cambodia's national payment system operated by the National Bank of Cambodia. This standalone Nest.js service will handle all payment operations for Das-tern subscriptions, running independently on a separate VPS.

The service enables patients to subscribe to PREMIUM ($0.50/month) and FAMILY_PREMIUM ($1/month) plans through Bakong's QR code payment system, manages subscription lifecycles, and communicates payment status to the main Das-tern backend.

## Glossary

- **Bakong_Service**: The standalone Nest.js backend service that handles Bakong payment integration
- **Bakong_API**: The National Bank of Cambodia's payment API for generating QR codes and processing payments
- **KHQR**: Cambodia's standardized QR code format for payments
- **Main_Backend**: The primary Das-tern backend service that manages user accounts and application features
- **Payment_Transaction**: A record of a payment attempt or completion
- **Subscription_Record**: A record tracking a user's subscription status, plan type, and billing cycle
- **Payment_Reference**: A unique identifier for tracking individual payment transactions
- **Webhook**: An HTTP callback from Bakong_API to Bakong_Service notifying of payment status changes
- **API_Key**: A secret token used for authentication between Bakong_Service and Main_Backend
- **Prorated_Amount**: A calculated payment amount when a user upgrades or downgrades their subscription mid-cycle

## Requirements

### Requirement 1: Payment QR Code Generation

**User Story:** As a patient, I want to receive a Bakong QR code when I initiate a subscription payment, so that I can scan and pay using my Bakong-enabled banking app.

#### Acceptance Criteria

1. WHEN a payment request is received from Main_Backend, THE Bakong_Service SHALL generate a unique Payment_Reference
2. WHEN generating a payment QR code, THE Bakong_Service SHALL call Bakong_API with the payment amount and Payment_Reference
3. WHEN Bakong_API returns a KHQR code, THE Bakong_Service SHALL store the Payment_Transaction with status "pending"
4. WHEN QR code generation succeeds, THE Bakong_Service SHALL return the KHQR code and Payment_Reference to the requester
5. IF Bakong_API fails to generate a QR code, THEN THE Bakong_Service SHALL return a descriptive error message and log the failure

### Requirement 2: Payment Verification and Callback Handling

**User Story:** As the system, I want to receive and verify payment confirmations from Bakong, so that I can activate subscriptions only for legitimate payments.

#### Acceptance Criteria

1. WHEN Bakong_API sends a webhook notification, THE Bakong_Service SHALL verify the webhook signature for authenticity
2. WHEN a webhook contains payment confirmation, THE Bakong_Service SHALL update the Payment_Transaction status to "completed"
3. WHEN a webhook contains payment failure, THE Bakong_Service SHALL update the Payment_Transaction status to "failed"
4. IF webhook signature verification fails, THEN THE Bakong_Service SHALL reject the webhook and log a security alert
5. WHEN a Payment_Transaction is updated, THE Bakong_Service SHALL record the timestamp and status change in the database

### Requirement 3: Subscription Creation and Management

**User Story:** As a patient, I want my subscription to activate immediately after successful payment, so that I can access premium features without delay.

#### Acceptance Criteria

1. WHEN a payment is confirmed for a new subscription, THE Bakong_Service SHALL create a Subscription_Record with status "active"
2. WHEN creating a Subscription_Record, THE Bakong_Service SHALL set the billing cycle start date to the payment confirmation timestamp
3. WHEN creating a Subscription_Record, THE Bakong_Service SHALL calculate the next billing date as 30 days from the start date
4. WHEN a subscription renewal payment is confirmed, THE Bakong_Service SHALL extend the Subscription_Record billing cycle by 30 days
5. WHEN a subscription payment fails, THE Bakong_Service SHALL update the Subscription_Record status to "expired"
6. WHEN a user cancels a subscription, THE Bakong_Service SHALL update the Subscription_Record status to "cancelled" and record the cancellation timestamp

### Requirement 4: Plan Upgrades and Downgrades

**User Story:** As a patient, I want to upgrade from PREMIUM to FAMILY_PREMIUM mid-cycle, so that my family members can immediately access premium features.

#### Acceptance Criteria

1. WHEN a user upgrades from PREMIUM to FAMILY_PREMIUM, THE Bakong_Service SHALL calculate the Prorated_Amount based on remaining days in the billing cycle
2. WHEN a user downgrades from FAMILY_PREMIUM to PREMIUM, THE Bakong_Service SHALL calculate the Prorated_Amount as a credit for the next billing cycle
3. WHEN a plan change is requested, THE Bakong_Service SHALL generate a new Payment_Transaction for the Prorated_Amount
4. WHEN a plan upgrade payment is confirmed, THE Bakong_Service SHALL update the Subscription_Record plan type immediately
5. WHEN a plan downgrade is requested, THE Bakong_Service SHALL schedule the plan change for the next billing cycle

### Requirement 5: Inter-Service Communication API

**User Story:** As the Main_Backend, I want to securely communicate with the Bakong_Service, so that I can initiate payments and verify subscription status for users.

#### Acceptance Criteria

1. WHEN Main_Backend calls an API endpoint, THE Bakong_Service SHALL verify the API_Key in the request header
2. IF the API_Key is invalid or missing, THEN THE Bakong_Service SHALL return a 401 Unauthorized error
3. WHEN Main_Backend requests payment initiation, THE Bakong_Service SHALL accept user ID, plan type, and amount as parameters
4. WHEN Main_Backend requests payment status, THE Bakong_Service SHALL return the current status of the specified Payment_Reference
5. WHEN Main_Backend requests subscription status, THE Bakong_Service SHALL return the active Subscription_Record for the specified user ID
6. WHEN Main_Backend requests subscription update, THE Bakong_Service SHALL process plan changes and return the updated Subscription_Record

### Requirement 6: Webhook Notifications to Main Backend

**User Story:** As the Main_Backend, I want to receive notifications when payment events occur, so that I can update user permissions and features in real-time.

#### Acceptance Criteria

1. WHEN a payment is confirmed, THE Bakong_Service SHALL send a webhook notification to Main_Backend with payment details
2. WHEN a subscription is activated, THE Bakong_Service SHALL send a webhook notification to Main_Backend with subscription details
3. WHEN a subscription expires, THE Bakong_Service SHALL send a webhook notification to Main_Backend with expiration details
4. IF webhook delivery to Main_Backend fails, THEN THE Bakong_Service SHALL retry up to 3 times with exponential backoff
5. WHEN webhook delivery fails after all retries, THE Bakong_Service SHALL log the failure and mark the notification as "failed"

### Requirement 7: Security and Fraud Prevention

**User Story:** As the system administrator, I want all payment data to be securely handled and validated, so that fraudulent transactions are prevented.

#### Acceptance Criteria

1. WHEN storing payment data, THE Bakong_Service SHALL encrypt sensitive information at rest
2. WHEN transmitting payment data, THE Bakong_Service SHALL use HTTPS with TLS 1.2 or higher
3. WHEN receiving a webhook, THE Bakong_Service SHALL validate the Payment_Reference exists before processing
4. WHEN detecting duplicate payment confirmations, THE Bakong_Service SHALL process only the first confirmation and log subsequent duplicates
5. WHEN API_Key authentication fails multiple times from the same IP, THE Bakong_Service SHALL implement rate limiting

### Requirement 8: Transaction and Subscription Persistence

**User Story:** As the system, I want all payment transactions and subscription records to be permanently stored, so that I can provide payment history and audit trails.

#### Acceptance Criteria

1. WHEN a Payment_Transaction is created, THE Bakong_Service SHALL store user ID, amount, currency, Payment_Reference, and timestamp
2. WHEN a Payment_Transaction status changes, THE Bakong_Service SHALL store the status, timestamp, and reason for the change
3. WHEN a Subscription_Record is created, THE Bakong_Service SHALL store user ID, plan type, status, start date, and next billing date
4. WHEN a Subscription_Record is updated, THE Bakong_Service SHALL maintain a history of all status changes with timestamps
5. WHEN querying payment history, THE Bakong_Service SHALL return all Payment_Transactions for the specified user ID ordered by timestamp

### Requirement 9: Error Handling and Recovery

**User Story:** As a developer, I want clear error messages and automatic recovery mechanisms, so that I can quickly diagnose and resolve payment issues.

#### Acceptance Criteria

1. WHEN Bakong_API is unavailable, THE Bakong_Service SHALL return a 503 Service Unavailable error with retry-after header
2. WHEN a payment times out, THE Bakong_Service SHALL update the Payment_Transaction status to "timeout" after 15 minutes
3. WHEN database connection fails, THE Bakong_Service SHALL retry the operation up to 3 times before returning an error
4. WHEN an unexpected error occurs, THE Bakong_Service SHALL log the full error stack trace and return a generic error message to the client
5. WHEN webhook delivery fails, THE Bakong_Service SHALL queue the notification for retry with exponential backoff

### Requirement 10: Monitoring and Audit Logging

**User Story:** As a system administrator, I want comprehensive logging of all payment operations, so that I can monitor system health and investigate issues.

#### Acceptance Criteria

1. WHEN a payment is initiated, THE Bakong_Service SHALL log the user ID, amount, and Payment_Reference
2. WHEN a payment status changes, THE Bakong_Service SHALL log the old status, new status, and reason for change
3. WHEN a webhook is received, THE Bakong_Service SHALL log the webhook payload, signature verification result, and processing outcome
4. WHEN an API call is made between services, THE Bakong_Service SHALL log the endpoint, request parameters, and response status
5. WHEN a security event occurs, THE Bakong_Service SHALL log the event type, source IP, and timestamp with "SECURITY" level
6. WHEN subscription renewal fails, THE Bakong_Service SHALL log the failure reason and trigger an alert
