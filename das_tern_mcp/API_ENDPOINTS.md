# API Endpoints Reference

## Base URL
```
https://api.dastern.site/api/v1
```

## Authentication Endpoints

### Login
```
POST /auth/login
Body: { identifier: string, password: string }
Response: { accessToken, refreshToken, user }
```

### Register Patient
```
POST /auth/register/patient
Body: { firstName, lastName, gender, dateOfBirth, email, phoneNumber, password }
Response: { user, accessToken, refreshToken }
```

### Register Doctor
```
POST /auth/register/doctor
Body: { fullName, email, phoneNumber, hospitalClinic, specialty, licenseNumber, password }
Response: { user, accessToken, refreshToken }
```

### Refresh Token
```
POST /auth/refresh
Body: { refreshToken: string }
Response: { accessToken, refreshToken }
```

### Get Profile
```
GET /auth/me
Headers: Authorization: Bearer <token>
Response: { user }
```

### Logout
```
POST /auth/logout
Headers: Authorization: Bearer <token>
```

## User Endpoints

### Get My Profile
```
GET /users/me
Headers: Authorization: Bearer <token>
Response: { user }
```

### Update Profile
```
PATCH /users/me
Headers: Authorization: Bearer <token>
Body: { firstName, lastName, ... }
Response: { user }
```

### Get Storage Info
```
GET /users/storage
Headers: Authorization: Bearer <token>
Response: { used, quota, percentage }
```

## Prescription Endpoints

### Get Prescriptions
```
GET /prescriptions?status=&patientId=
Headers: Authorization: Bearer <token>
Response: [{ prescription }]
```

### Get Prescription Detail
```
GET /prescriptions/:id
Headers: Authorization: Bearer <token>
Response: { prescription }
```

### Create Prescription
```
POST /prescriptions
Headers: Authorization: Bearer <token>
Body: { medicines, notes, ... }
Response: { prescription }
```

### Update Prescription
```
PATCH /prescriptions/:id
Headers: Authorization: Bearer <token>
Body: { ... }
Response: { prescription }
```

## Dose Endpoints

### Get Dose Schedule
```
GET /doses/schedule?date=&groupBy=
Headers: Authorization: Bearer <token>
Response: { schedule }
```

### Get Dose History
```
GET /doses/history?page=&take=
Headers: Authorization: Bearer <token>
Response: { doses, adherencePercentage, total }
```

### Mark Dose Taken
```
PATCH /doses/:id/taken
Headers: Authorization: Bearer <token>
Body: { takenAt, offline }
Response: { dose }
```

### Skip Dose
```
PATCH /doses/:id/skipped
Headers: Authorization: Bearer <token>
Body: { reason: string }
Response: { dose }
```

## Connection Endpoints

### Get Connections
```
GET /connections?status=
Headers: Authorization: Bearer <token>
Response: [{ connection }]
```

### Create Connection
```
POST /connections
Headers: Authorization: Bearer <token>
Body: { patientId, permissionLevel }
Response: { connection }
```

### Accept Connection
```
PATCH /connections/:id/accept
Headers: Authorization: Bearer <token>
Response: { connection }
```

## OCR Endpoints

### Scan Prescription
```
POST /ocr/scan
Headers: Authorization: Bearer <token>
Body: FormData { file: image }
Response: { prescription, medicines }
```

### Extract Prescription (Preview)
```
POST /ocr/extract
Headers: Authorization: Bearer <token>
Body: FormData { file: image }
Response: { medicines, extracted_data }
```

## Health Check

### Backend Health
```
GET /health
Response: { status, service, timestamp, uptime }
```

## Error Responses

All errors follow this format:
```json
{
  "statusCode": 400,
  "message": "Error description",
  "error": "BadRequest"
}
```

## Common Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized (token expired/invalid)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Server Error

## Token Management

1. **Access Token:** Short-lived (15 minutes)
2. **Refresh Token:** Long-lived (7 days)
3. **Auto-Refresh:** On 401 response, automatically refresh and retry
4. **Storage:** Encrypted in secure storage

## CORS Configuration

Allowed origins:
- `https://api.dastern.site`
- `https://ocr.dastern.site`
- `https://ai.dastern.site`
- `https://payment.dastern.site`

## Rate Limiting

- Login: 20 attempts per minute
- OTP Send: 3 requests per 5 minutes
- OTP Verify: 5 attempts per 5 minutes
- General: 40 requests per minute

See `lib/services/api_service.dart` for all available methods!

