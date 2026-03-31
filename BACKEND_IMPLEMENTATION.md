# 🔧 Backend Implementation Guide - Quick Reference

> Detailed code examples and implementation patterns for Das Tern backend

**Version:** 1.0.0  
**Last Updated:** March 2025

---

## 📖 Quick Links

- [Prescription Versioning](#1-prescription-versioning-system)
- [Offline-First Dose Tracking](#2-offline-first-dose-tracking)
- [OCR Integration](#3-ocr-integration)
- [Connection Management](#4-connection-management)
- [Urgent Updates](#5-urgent-prescription-updates)
- [Health Monitoring](#6-health-monitoring)

---

## 1. Prescription Versioning System

### When Doctor Updates Prescription

```typescript
// 1. Create new version
const newVersion = await prisma.prescriptionVersion.create({
  data: {
    prescriptionId: id,
    versionNumber: lastVersion.versionNumber + 1,
    authorId: doctorId,
    medicinesSnapshot: dto.medicines,
    changeReason: "Dosage adjustment"
  }
});

// 2. Update prescription
await prisma.prescription.update({
  where: { id },
  data: {
    medicines: { deleteMany: {}, create: dto.medicines },
    currentVersion: newVersion.versionNumber
  }
});

// 3. Notify patient
await notificationService.send({
  userId: patientId,
  title: "Prescription Updated",
  requiresConfirmation: true
});
```

### Patient Confirms

```typescript
// 1. Activate prescription
await prisma.prescription.update({
  where: { id },
  data: { status: 'ACTIVE' }
});

// 2. Generate dose schedule
await generateDoseSchedule(id);

// 3. Sync to device (for offline)
await deviceSyncService.sendSchedule(patientId, schedule);
```

---

## 2. Offline-First Dose Tracking

### Recording Doses (Both Online & Offline)

**Online:** Immediate update
```typescript
await prisma.doseEvent.update({
  where: { id: doseId },
  data: {
    status: calculateStatus(now, doseEvent),
    actualTime: now,
    syncedAt: now
  }
});
```

**Offline:** Store locally, sync when online
```typescript
// Device stores locally:
localStorage.setItem('pendingDoses', JSON.stringify({
  doseId,
  medicineId,
  status,
  actualTime,
  offline: true
}));

// When online, sync:
POST /doses/sync
{
  "doses": [{ doseId, status, actualTime, ... }]
}
```

### Missed Dose Escalation

```typescript
// If dose time passes without recording
if (now > doseEvent.cutoffTime && !doseEvent.actualTime) {
  // 1. Mark as MISSED
  await prisma.doseEvent.update({
    where: { id },
    data: { status: 'MISSED' }
  });

  // 2. Alert family (if online) or queue (if offline)
  if (isOnline) {
    await notifyFamilyImmediately(patientId);
  } else {
    await queueMissedDoseNotification(patientId);
  }

  // 3. When patient syncs, send late notification
  // "Dose missed at 2:00 PM (notified at 4:30 PM after sync)"
}
```

---

## 3. OCR Integration

### Backend Controller

```typescript
@Post('scan')
async scanPrescription(@UploadedFile() file, @CurrentUser() user) {
  // 1. Validate
  if (file.size > 10MB) throw new BadRequestException();

  // 2. Upload to S3
  const imageUrl = await s3Service.upload(file);

  // 3. Call OCR service
  const result = await httpService.post(
    'http://ocr-service:8003/api/v1/extract',
    { file }
  );

  // 4. Create prescription
  const prescription = await prisma.prescription.create({
    data: {
      patientId: user.id,
      status: 'DRAFT',
      medicines: result.medicines,
      prescriptionImageUrl: imageUrl
    }
  });

  return prescription;
}
```

### OCR Service (Python)

```python
@app.post("/api/v1/extract")
async def extract(file: UploadFile = File(...)):
    # 1. Preprocess image
    image = preprocess(await file.read())
    
    # 2. Extract text (OCR)
    text = engine.recognize(image)
    
    # 3. Parse medicines
    medicines = parse_medicines(text)
    
    # 4. Structure result
    return {
        "extractedText": text,
        "medicines": medicines,
        "confidence": 0.95
    }
```

---

## 4. Connection Management

### Doctor Initiates

```typescript
// 1. Send request
const connection = await prisma.connection.create({
  data: {
    initiatorId: doctorId,
    recipientId: patientId,
    status: 'PENDING'
  }
});

// 2. Patient notified
await notifications.send({
  userId: patientId,
  title: "Dr. X wants to connect",
  metadata: { connectionId: connection.id }
});
```

### Patient Accepts & Sets Permission

```typescript
// 1. Accept
await prisma.connection.update({
  where: { id },
  data: { status: 'ACCEPTED', acceptedAt: new Date() }
});

// 2. Set permission
await prisma.connection.update({
  where: { id },
  data: { permissionLevel: 'ALLOWED' }  // or REQUEST, SELECTED, NOT_ALLOWED
});

// 3. Doctor now has access (based on permission)
```

### Permission Enforcement

```typescript
// When doctor requests patient data
async getPatientData(doctorId, patientId) {
  const connection = await prisma.connection.findFirst({
    where: {
      initiatorId: doctorId,
      recipientId: patientId,
      status: 'ACCEPTED'
    }
  });

  if (connection.permissionLevel === 'NOT_ALLOWED') {
    throw new ForbiddenException();
  }

  if (connection.permissionLevel === 'ALLOWED') {
    return allPatientData;  // Full access
  }

  if (connection.permissionLevel === 'SELECTED') {
    return selectedItemsOnly;  // Filtered
  }
}
```

---

## 5. Urgent Prescription Updates

### Doctor Marks Urgent

```typescript
@Post(':id/urgent-update')
async urgentUpdate(
  @CurrentUser() doctor,
  @Param('id') prescriptionId,
  @Body() dto: UpdatePrescriptionDto
) {
  // 1. Create new version (marked urgent)
  const version = await prisma.prescriptionVersion.create({
    data: {
      prescriptionId,
      versionNumber: 2,
      authorId: doctor.id,
      isUrgent: true,
      wasAutoApplied: true,
      changeReason: "Safety critical: increased dosage"
    }
  });

  // 2. Auto-apply immediately (no patient confirmation)
  await prisma.prescription.update({
    where: { id: prescriptionId },
    data: {
      status: 'ACTIVE',
      medicines: dto.medicines,
      isUrgent: true
    }
  });

  // 3. Regenerate schedule
  await generateDoseSchedule(prescriptionId);

  // 4. Send URGENT notification
  await notifications.send({
    userId: patientId,
    title: '⚡ URGENT Prescription Update',
    priority: 'URGENT',
    message: "Safety critical: increased dosage"
  });

  // 5. Log everything
  await auditService.log({
    action: 'URGENT_UPDATE',
    urgentFlag: true,
    autoApplied: true,
    reason: dto.urgentReason
  });
}
```

---

## 6. Health Monitoring

### Record Vital Sign

```typescript
@Post('vitals')
async recordVital(@CurrentUser() user, @Body() dto) {
  // 1. Create record
  const vital = await prisma.healthVital.create({
    data: {
      patientId: user.id,
      type: 'BP',
      systolic: 150,
      diastolic: 95,
      recordedAt: new Date()
    }
  });

  // 2. Check thresholds
  const threshold = await prisma.vitalThreshold.findFirst({
    where: { patientId: user.id, vitalType: 'BP' }
  });

  // 3. Alert if abnormal
  if (vital.systolic > threshold.highThreshold) {
    await notifications.send({
      userId: user.id,
      title: '⚠️ High Blood Pressure',
      message: `Your BP is ${vital.systolic}/${vital.diastolic}`
    });

    // Notify connected doctor
    const connections = await prisma.connection.findMany({
      where: { recipientId: user.id, status: 'ACCEPTED' }
    });

    for (const conn of connections) {
      await notifications.send({
        userId: conn.initiatorId,
        title: 'Patient Alert',
        message: `${user.firstName} BP is abnormal`
      });
    }
  }

  return vital;
}
```

---

## 📋 Common Database Queries

### Find Connected Patients (Doctor)

```typescript
const patients = await prisma.connection.findMany({
  where: {
    initiatorId: doctorId,
    status: 'ACCEPTED'
  },
  include: {
    recipient: true
  }
});
```

### Get Prescription Adherence

```typescript
const adherence = await prisma.doseEvent.groupBy({
  by: ['status'],
  where: {
    patientId,
    scheduledTime: {
      gte: subDays(new Date(), 7)
    }
  },
  _count: true
});

const adherenceRate = (
  adherence.filter(a => a.status.includes('TAKEN')).reduce((sum, a) => sum + a._count, 0) /
  adherence.reduce((sum, a) => sum + a._count, 0)
) * 100;
```

### Audit Log Search

```typescript
const logs = await prisma.auditLog.findMany({
  where: {
    entityType: 'Prescription',
    entityId: prescriptionId,
    action: 'PRESCRIPTION_UPDATED'
  },
  orderBy: { createdAt: 'desc' }
});
```

---

## 🚀 API Response Examples

### Create Prescription

**Request:**
```
POST /api/v1/prescriptions
{
  "patientId": "patient-123",
  "symptoms": "Fever, cough",
  "diagnosis": "Common cold",
  "medicines": [
    {
      "medicineName": "Paracetamol",
      "dosage": "500mg",
      "frequency": "3 times daily"
    }
  ]
}
```

**Response:**
```json
{
  "statusCode": 201,
  "message": "Prescription created",
  "data": {
    "id": "rx-456",
    "status": "DRAFT",
    "currentVersion": 1,
    "medicines": [...]
  }
}
```

### Record Dose

**Request:**
```
POST /api/v1/doses/rx-456/record
{
  "medicineId": "med-789",
  "actualTime": "2025-03-31T14:30:00Z"
}
```

**Response:**
```json
{
  "statusCode": 200,
  "message": "Dose recorded",
  "data": {
    "doseId": "dose-111",
    "status": "TAKEN_ON_TIME",
    "adherenceRate": 87.5
  }
}
```

---

## 🛠️ Debugging Tips

### Check Prescription Status

```typescript
const rx = await prisma.prescription.findUnique({
  where: { id: prescriptionId },
  include: {
    medicines: true,
    versions: { orderBy: { versionNumber: 'desc' } }
  }
});

console.log('Status:', rx.status);
console.log('Version:', rx.currentVersion);
console.log('Urgent:', rx.isUrgent);
console.log('History:', rx.versions.map(v => ({
  v: v.versionNumber,
  reason: v.changeReason,
  urgent: v.isUrgent
})));
```

### Check Dose Events

```typescript
const doses = await prisma.doseEvent.findMany({
  where: { prescriptionId: 'rx-456' },
  orderBy: { scheduledTime: 'asc' }
});

doses.forEach(d => {
  console.log(
    `${d.scheduledTime}: ${d.status} (actual: ${d.actualTime || 'N/A'})`
  );
});
```

### Check Connections

```typescript
const connections = await prisma.connection.findMany({
  where: {
    OR: [
      { initiatorId: userId },
      { recipientId: userId }
    ]
  },
  include: {
    initiator: { select: { firstName: true, role: true } },
    recipient: { select: { firstName: true, role: true } }
  }
});

connections.forEach(c => {
  console.log(
    `${c.initiator.firstName} → ${c.recipient.firstName}: ${c.status} (${c.permissionLevel})`
  );
});
```

---

## 📚 File Structure Reference

```
backend_nestjs/
├── src/
│   ├── app.controller.ts
│   ├── app.module.ts          # Main app setup
│   ├── main.ts                # Bootstrap
│   ├── common/
│   │   ├── decorators/        # @CurrentUser, @Roles
│   │   ├── guards/            # AuthGuard, RolesGuard
│   │   └── filters/           # Exception filters
│   ├── database/
│   │   ├── database.module.ts
│   │   └── prisma.service.ts  # Database connection
│   └── modules/
│       ├── auth/              # Authentication
│       ├── prescriptions/      # Prescriptions
│       ├── doses/             # Dose tracking
│       ├── connections/       # Doctor-patient connections
│       ├── ocr/               # OCR integration
│       ├── notifications/     # Push notifications
│       ├── audit/             # Audit logging
│       ├── health-monitoring/ # Vitals tracking
│       └── ...                # Other modules
├── prisma/
│   ├── schema.prisma          # Database schema
│   └── migrations/            # Migration files
├── test/                      # E2E tests
└── package.json
```

---

## 🔗 Related Documentation

- **Architecture:** [BACKEND_ARCHITECTURE.md](./BACKEND_ARCHITECTURE.md)
- **Database:** Run `npx prisma studio`
- **API Docs:** Swagger at `http://localhost:3001/api`

---

<div align="center">

**Last Updated:** March 31, 2025

[⬆ Back to Top](#-backend-implementation-guide)

</div>
