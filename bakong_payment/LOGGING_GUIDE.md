# 📊 Bakong Payment Service - Logging & Monitoring Guide

## Overview

The Bakong Payment Service implements comprehensive logging across **7 separate log files** to facilitate easy bug identification, security monitoring, and performance tracking.

---

## 📁 Log Files Structure

```
bakong_payment/logs/
├── combined.log        # All logs (INFO and above)
├── error.log          # Errors only (ERROR level)
├── activity.log       # HTTP requests/responses
├── payment.log        # Payment operations
├── subscription.log   # Subscription operations
├── security.log       # Security events
├── performance.log    # Performance issues
└── audit.log          # Critical operations
```

---

## 🔍 Log File Details

### 1. `combined.log` - General Application Logs

**Purpose**: All application logs aggregated  
**Level**: INFO and above  
**Rotation**: 10MB, keeps 5 files  

**Use Cases**:
- General application health
- Debug application flow
- Overview of all activities

**Example Entry**:
```json
{
  "timestamp": "2026-02-11 09:35:00",
  "level": "info",
  "message": "Payment created successfully",
  "service": "bakong-payment-service",
  "userId": "user-123",
  "transactionId": "uuid",
  "planType": "PREMIUM"
}
```

---

### 2. `error.log` - Error Tracking

**Purpose**: All errors and exceptions  
**Level**: ERROR only  
**Rotation**: 10MB, keeps 5 files  

**Use Cases**:
- Identify application errors
- Debug failures
- Monitor system health

**Example Entry**:
```json
{
  "timestamp": "2026-02-11 09:36:00",
  "level": "error",
  "message": "Payment status check failed",
  "service": "bakong-payment-service",
  "error": "Bakong API timeout",
  "md5Hash": "abcd1234...",
  "stack": "Error: Timeout\n  at BakongClient.checkPayment..."
}
```

---

### 3. `activity.log` - HTTP Activity Tracking 🆕

**Purpose**: All HTTP requests and responses  
**Level**: INFO and above  
**Rotation**: 10MB, keeps 5 files  

**Use Cases**:
- Track API usage
- Identify slow requests
- Debug client issues
- Monitor traffic patterns

**Example Entries**:
```json
// Incoming Request
{
  "timestamp": "2026-02-11 09:35:00",
  "level": "info",
  "message": "Incoming request",
  "requestId": "a1b2c3d4e5f6",
  "method": "POST",
  "path": "/api/payments/create",
  "url": "/api/payments/create",
  "query": {},
  "ip": "192.168.1.100",
  "userAgent": "Dart/3.0 (dio)",
  "body": {
    "userId": "user-123",
    "planType": "PREMIUM",
    "amount": 0.5,
    "currency": "USD"
  }
}

// Successful Response
{
  "timestamp": "2026-02-11 09:35:01",
  "level": "info",
  "message": "Successful response",
  "requestId": "a1b2c3d4e5f6",
  "method": "POST",
  "path": "/api/payments/create",
  "statusCode": 200,
  "duration": "250ms",
  "ip": "192.168.1.100"
}

// Slow Request Warning
{
  "timestamp": "2026-02-11 09:35:05",
  "level": "warn",
  "message": "Slow request detected",
  "level": "PERFORMANCE",
  "requestId": "b2c3d4e5f6g7",
  "method": "POST",
  "path": "/api/payments/monitor",
  "statusCode": 200,
  "duration": "3500ms"
}
```

---

### 4. `payment.log` - Payment Operations 🆕

**Purpose**: All payment-related operations  
**Level**: INFO and above  
**Rotation**: 10MB, keeps 10 files (more history)  

**Use Cases**:
- Track payment lifecycle
- Debug payment issues
- Monitor payment success rate
- Audit payment operations

**Example Entries**:
```json
{
  "timestamp": "2026-02-11 09:35:00",
  "level": "info",
  "message": "Creating payment",
  "logType": "PAYMENT",
  "userId": "user-123",
  "planType": "PREMIUM",
  "amount": 0.5,
  "transactionId": "uuid"
}

{
  "timestamp": "2026-02-11 09:35:05",
  "level": "info",
  "message": "Payment status checked",
  "logType": "PAYMENT",
  "md5Hash": "abcd1234...",
  "oldStatus": "PENDING",
  "newStatus": "PAID"
}
```

---

### 5. `subscription.log` - Subscription Operations 🆕

**Purpose**: All subscription-related operations  
**Level**: INFO and above  
**Rotation**: 10MB, keeps 10 files  

**Use Cases**:
- Track subscription lifecycle
- Debug subscription issues
- Monitor billing operations
- Audit plan changes

**Example Entries**:
```json
{
  "timestamp": "2026-02-11 09:35:10",
  "level": "info",
  "message": "Creating subscription",
  "logType": "SUBSCRIPTION",
  "userId": "user-123",
  "planType": "PREMIUM",
  "paymentTransactionId": "uuid"
}

{
  "timestamp": "2026-02-11 10:00:00",
  "level": "info",
  "message": "Subscription upgraded",
  "logType": "SUBSCRIPTION",
  "userId": "user-123",
  "oldPlanType": "PREMIUM",
  "newPlanType": "FAMILY_PREMIUM",
  "proratedAmount": 0.25
}
```

---

### 6. `security.log` - Security Events

**Purpose**: Security-related events and alerts  
**Level**: WARN and above  
**Rotation**: 10MB, keeps 10 files  

**Use Cases**:
- Monitor unauthorized access
- Detect brute force attempts
- Track IP blocks
- Security audit

**Example Entries**:
```json
{
  "timestamp": "2026-02-11 09:40:00",
  "level": "warn",
  "message": "Failed authentication attempt",
  "level": "SECURITY",
  "ip": "192.168.1.200",
  "attempts": 3,
  "path": "/api/subscriptions/status/user-123"
}

{
  "timestamp": "2026-02-11 09:42:00",
  "level": "warn",
  "message": "Blocked IP attempt",
  "level": "SECURITY",
  "ip": "192.168.1.200",
  "path": "/api/payments/create",
  "reason": "10+ failed authentication attempts"
}
```

---

### 7. `performance.log` - Performance Issues 🆕

**Purpose**: Performance-related warnings  
**Level**: WARN and above  
**Rotation**: 5MB, keeps 3 files  

**Use Cases**:
- Identify slow operations
- Monitor timeouts
- Optimize performance bottlenecks

**Example Entry**:
```json
{
  "timestamp": "2026-02-11 09:45:00",
  "level": "warn",
  "message": "Slow request detected",
  "level": "PERFORMANCE",
  "requestId": "c3d4e5f6g7h8",
  "method": "POST",
  "path": "/api/payments/bulk-check",
  "statusCode": 200,
  "duration": "2500ms"
}
```

---

### 8. `audit.log` - Critical Operations Audit 🆕

**Purpose**: Critical operations requiring audit trail  
**Level**: INFO and above  
**Rotation**: 10MB, keeps 20 files (long retention)  

**Use Cases**:
- Compliance requirements
- Security audits
- Forensic analysis
- Regulatory reporting

**Example Entries**:
```json
{
  "timestamp": "2026-02-11 09:35:10",
  "level": "info",
  "message": "Subscription created",
  "level": "AUDIT",
  "userId": "user-123",
  "action": "SUBSCRIPTION_CREATED",
  "resourceType": "subscription",
  "resourceId": "sub-uuid",
  "details": {
    "planType": "PREMIUM",
    "startDate": "2026-02-11",
    "nextBillingDate": "2026-03-13"
  }
}

{
  "timestamp": "2026-02-11 10:00:00",
  "level": "info",
  "message": "Payment status changed",
  "level": "AUDIT",
  "userId": "user-123",
  "action": "PAYMENT_STATUS_CHANGED",
  "resourceType": "payment",
  "resourceId": "payment-uuid",
  "details": {
    "oldStatus": "PENDING",
    "newStatus": "PAID",
    "amount": 0.50,
    "currency": "USD"
  }
}
```

---

## 🛠️ Using Logs for Debugging

### Common Debugging Scenarios

#### 1. Payment Not Working

```bash
# Check payment.log for payment operations
tail -f logs/payment.log | jq

# Check activity.log for API requests
grep "payments/create" logs/activity.log | jq

# Check error.log for errors
grep -A 10 "payment" logs/error.log | jq
```

#### 2. Subscription Not Created

```bash
# Check subscription.log
grep "Creating subscription" logs/subscription.log | jq

# Check payment.log to see if payment was successful
grep "status.*PAID" logs/payment.log | jq

# Check audit.log for subscription creation
grep "SUBSCRIPTION_CREATED" logs/audit.log | jq
```

#### 3. Authentication Issues

```bash
# Check security.log
tail -n 50 logs/security.log | jq

# Look for specific IP
grep "192.168.1.100" logs/security.log | jq

# Check failed attempts
grep "Failed authentication" logs/security.log | jq
```

#### 4. Performance Problems

```bash
# Check performance.log
tail -f logs/performance.log | jq

# Find slow requests
grep "Slow request" logs/activity.log | jq

# List requests by duration
grep "duration" logs/activity.log | jq -r '"\(.duration) - \(.path)"' | sort
```

#### 5. Track Specific User Activity

```bash
# All logs for a user
grep "user-123" logs/combined.log | jq

# User's payments
grep "user-123" logs/payment.log | jq

# User's subscriptions
grep "user-123" logs/subscription.log | jq

# User's API requests
grep "user-123" logs/activity.log | jq
```

#### 6. Track Specific Request

```bash
# Using requestId (from activity.log)
grep "a1b2c3d4e5f6" logs/activity.log | jq

# This shows the entire request/response flow
```

---

## 📈 Log Analysis

### Useful Log Analysis Commands

```bash
# Count HTTP methods
grep "method" logs/activity.log | jq -r '.method' | sort | uniq -c

# Count status codes
grep "statusCode" logs/activity.log | jq -r '.statusCode' | sort | uniq -c

# Average request duration
grep "duration" logs/activity.log | jq -r '.duration' | sed 's/ms//' | awk '{sum+=$1; count++} END {print sum/count}'

# Top 10 slowest requests
grep "duration" logs/activity.log | jq -r '"\(.duration) - \(.method) \(.path)"' | sort -rn | head -10

# Payment success rate
total_payments=$(grep "Payment created" logs/payment.log | wc -l)
successful_payments=$(grep "status.*PAID" logs/payment.log | wc -l)
echo "Success Rate: $(echo "scale=2; $successful_payments/$total_payments*100" | bc)%"

# Security events per hour
grep "SECURITY" logs/security.log | jq -r '.timestamp' | cut -d' ' -f2 | cut -d':' -f1 | sort | uniq -c

# Top IP addresses
grep "ip" logs/activity.log | jq -r '.ip' | sort | uniq -c | sort -rn | head -10
```

---

## 🚨 Real-Time Monitoring

### Monitor All Logs

```bash
# Watch all logs
tail -f logs/*.log

# Watch specific logs
tail -f logs/payment.log logs/subscription.log

# Watch with color and formatting
tail -f logs/activity.log | jq -C
```

### Monitor Errors

```bash
# Watch errors in real-time
tail -f logs/error.log | jq -C

# Alert on errors
tail -f logs/error.log | grep --line-buffered "error" | while read line; do
  echo "🚨 ERROR DETECTED: $line"
  # Send alert (email, slack, etc.)
done
```

### Monitor Security Events

```bash
# Watch security events
tail -f logs/security.log | jq -C

# Alert on IP blocks
tail -f logs/security.log | grep --line-buffered "Blocked IP" | while read line; do
  echo "⚠️  IP BLOCKED: $line"
done
```

---

## 🔧 Log Configuration

### Log Levels

- `error` - Errors only
- `warn` - Warnings and errors
- `info` - Info, warnings, and errors (default)
- `debug` - Detailed debugging information
- `verbose` - Very detailed information

### Change Log Level

```bash
# In .env file
LOG_LEVEL=debug

# Or environment variable
export LOG_LEVEL=debug
npm run start:dev
```

### Log Rotation

All logs automatically rotate when they reach their size limit:

- **combined.log**: 10MB, 5 files
- **error.log**: 10MB, 5 files
- **activity.log**: 10MB, 5 files
- **payment.log**: 10MB, 10 files (longer retention)
- **subscription.log**: 10MB, 10 files
- **security.log**: 10MB, 10 files
- **performance.log**: 5MB, 3 files
- **audit.log**: 10MB, 20 files (longest retention)

---

## ✅ Summary

The Bakong Payment Service provides **comprehensive logging** across 8 log files:

1. ✅ **combined.log** - All application logs
2. ✅ **error.log** - Errors for quick debugging
3. ✅ **activity.log** - All HTTP requests/responses with request IDs
4. ✅ **payment.log** - Payment operations tracking
5. ✅ **subscription.log** - Subscription lifecycle
6. ✅ **security.log** - Security events and alerts
7. ✅ **performance.log** - Performance issues
8. ✅ **audit.log** - Critical operations for compliance

This makes it **very easy to**:
- ✅ Identify bugs (check error.log + relevant operation log)
- ✅ Track security issues (security.log)
- ✅ Monitor performance (performance.log + activity.log)
- ✅ Debug specific requests (use requestId in activity.log)
- ✅ Audit operations (audit.log)
- ✅ Analyze payment/subscription behaviors

**All logs are structured JSON** for easy parsing, filtering, and integration with log aggregation tools (ELK stack, Splunk, etc.).
