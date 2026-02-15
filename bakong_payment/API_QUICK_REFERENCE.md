# Bakong Payment Service - Quick API Reference

## Base URL
```
http://localhost:3002
```

## Authentication
All endpoints (except health) require:
```
Authorization: Bearer changeme_secure_api_key_here
```

---

## 🔄 Common Workflows

### Workflow 1: New Subscription
```bash
# Step 1: Create payment
curl -X POST http://localhost:3002/api/payments/create \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-123",
    "planType": "PREMIUM",
    "amount": 0.50,
    "currency": "USD"
  }'

# Response includes: transactionId, md5Hash, qrCode, deepLink

# Step 2: Monitor payment (auto-creates subscription on success)
curl -X POST http://localhost:3002/api/payments/monitor \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "transactionId": "<TRANSACTION_ID>",
    "options": {
      "timeout": 300000,
      "interval": 5000,
      "priority": "high"
    }
  }'

# Step 3: Verify subscription created
curl http://localhost:3002/api/subscriptions/status/user-123 \
  -H "Authorization: Bearer <API_KEY>"
```

---

### Workflow 2: Upgrade Subscription
```bash
# Step 1: Request upgrade (generates prorated payment)
curl -X POST http://localhost:3002/api/subscriptions/upgrade \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-123",
    "callback": "https://app.dastern.com/upgrade/success"
  }'

# Response includes: proratedAmount, payment details (QR code, etc.)

# Step 2: Monitor prorated payment
curl -X POST http://localhost:3002/api/payments/monitor \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "transactionId": "<TRANSACTION_ID>"
  }'

# Subscription automatically upgraded to FAMILY_PREMIUM on payment success
```

---

### Workflow 3: Check Payment Status
```bash
# Option A: Single payment check
curl http://localhost:3002/api/payments/status/<MD5_HASH> \
  -H "Authorization: Bearer <API_KEY>"

# Option B: Bulk check (up to 50)
curl -X POST http://localhost:3002/api/payments/bulk-check \
  -H "Authorization: Bearer <API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "md5Hashes": ["hash1", "hash2", "hash3"]
  }'
```

---

## 📋 Quick Reference

### Payment Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/payments/create` | Create payment + QR |
| GET | `/api/payments/status/:md5` | Check status |
| POST | `/api/payments/monitor` | Monitor until complete |
| POST | `/api/payments/bulk-check` | Check multiple |
| GET | `/api/payments/history` | Get user history |

### Subscription Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/subscriptions/status/:userId` | Get subscription |
| POST | `/api/subscriptions/upgrade` | Upgrade plan |
| POST | `/api/subscriptions/downgrade` | Downgrade plan |
| POST | `/api/subscriptions/cancel` | Cancel subscription |
| POST | `/api/subscriptions/renew` | Manual renewal |

### Health Endpoints (No Auth Required)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/health` | Full health check |
| GET | `/api/health/ready` | Readiness probe |
| GET | `/api/health/live` | Liveness probe |

---

## 🔑 Payment Statuses

- `PENDING` - Payment created, awaiting payment
- `PAID` - Payment successful
- `FAILED` - Payment failed
- `TIMEOUT` - Payment timed out (15 minutes)
- `EXPIRED` - QR code expired
- `CANCELLED` - Payment cancelled

---

## 📦 Subscription Statuses

- `PENDING` - Subscription created, awaiting first payment
- `ACTIVE` - Subscription active
- `EXPIRED` - Subscription expired (billing failed)
- `CANCELLED` - User cancelled subscription

---

## 💰 Plan Types & Pricing

| Plan | Price (USD) | Features |
|------|-------------|----------|
| `PREMIUM` | $0.50/month | Individual user |
| `FAMILY_PREMIUM` | $1.00/month | Family access |

---

## ⚡ Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... }
}
```

### Error Response
```json
{
  "statusCode": 400,
  "message": "Error description",
  "error": "Bad Request"
}
```

---

## 🚨 Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 401 | Unauthorized | Check API key |
| 400 | Bad Request | Validate request body |
| 404 | Not Found | Check resource ID |
| 429 | Too Many Requests | Wait before retry |
| 500 | Server Error | Check logs |

---

## 🧪 Testing Commands

```bash
# Health check (no auth)
curl http://localhost:3002/api/health

# Test authentication
curl http://localhost:3002/api/subscriptions/status/test \
  -H "Authorization: Bearer WRONG_KEY"
# Should return 401

# Create test payment
curl -X POST http://localhost:3002/api/payments/create \
  -H "Authorization: Bearer changeme_secure_api_key_here" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user",
    "planType": "PREMIUM",
    "amount": 0.50,
    "currency": "USD"
  }'

# Run full test suite
./test-api.sh
```

---

## 📊 Rate Limits

- **100 requests/minute** per API key or IP
- Headers included in response:
  - `X-RateLimit-Limit`: Total limit
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset timestamp
  - `Retry-After`: Seconds to wait (if limited)

---

## 🔒 Security Notes

1. **API Key**: Keep secure, don't commit to Git
2. **HTTPS**: Use HTTPS in production
3. **IP Blocking**: Auto-blocks after 10 failed auth attempts
4. **Logs**: Check `logs/security.log` for security events

---

## 📌 Tips

- **QR Image**: QR code images saved in `public/qr-codes/`
- **Monitoring**: High priority payments checked more frequently
- **Timeout**: Payments auto-timeout after 15 minutes
- **Billing**: All subscriptions use 30-day cycles
- **Prorated**: Upgrades calculate prorated amount automatically
- **Downgrades**: Take effect at next billing cycle (not immediate)

---

## 🆘 Troubleshooting

### Payment not found
- Check MD5 hash is correct (32 characters)
- Verify payment was created in database

### Authentication fails
- Verify API key matches `.env` file
- Check for any leading/trailing spaces
- Ensure `Bearer ` prefix in Authorization header

### Rate limited
- Wait for rate limit window to reset
- Check `Retry-After` header for wait time

### Subscription not created
- Verify payment status is `PAID`
- Check if monitoring completed successfully
- Review logs for errors

---

For detailed documentation, see:
- **README.md** - Complete guide
- **IMPLEMENTATION_REPORT.md** - All features
- **SECURITY_ASSESSMENT.md** - Security details
