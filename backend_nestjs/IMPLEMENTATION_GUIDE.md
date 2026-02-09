# NestJS Backend Implementation Guide

This guide will help you complete the Das Tern NestJS backend implementation based on the specifications.

---

## 🎯 Current Status

**Phase 1 Complete**: Authentication module with OTP, patient/doctor registration, and account lockout.

**Next**: Implement remaining 7 modules (Users, Prescriptions, Doses, Connections, Notifications, Audit, Subscriptions).

---

## 🚀 Quick Start

```bash
cd /home/rayu/das-tern/backend_nestjs
./quick-start.sh
npm run start:dev
```

---

## 📋 Implementation Checklist

### ✅ Phase 1: Authentication (COMPLETE)
- [x] Auth DTOs with validation
- [x] OTP service (5min expiry, 60s cooldown, 5 attempts)
- [x] Patient registration with OTP
- [x] Doctor registration with verification
- [x] Login with account lockout
- [x] JWT tokens (access + refresh)
- [x] Google OAuth integration

### 🚧 Phase 2: Users Module (IN PROGRESS)

**Files to update**:
- `src/modules/users/users.service.ts`
- `src/modules/users/users.controller.ts`
- `src/modules/users/dto/` (create DTOs)

**Tasks**:
1. Create `update-profile.dto.ts`:
```typescript
import { IsOptional, IsEnum, IsString } from 'class-validator';
import { Language, Theme } from '@prisma/client';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsEnum(Language)
  language?: Language;

  @IsOptional()
  @IsEnum(Theme)
  theme?: Theme;
}
```

2. Update `users.service.ts`:
   - Add `calculateStorageUsage(userId)` method
   - Add `calculateDailyProgress(userId)` method for patients
   - Add proper error handling
   - Return formatted profile with storage info

3. Update `users.controller.ts`:
   - Add `GET /users/storage` endpoint
   - Add proper validation
   - Add role-based response formatting

### 📝 Phase 3: Prescriptions Module

**Key Requirements**:
- CRUD operations with versioning
- Medication grid format (morning, daytime, night dosages)
- Urgent updates with auto-apply
- Prescription confirmation/retake workflow
- Khmer/English medication names

**Implementation Steps**:

1. Create DTOs:
```typescript
// create-prescription.dto.ts
export class CreatePrescriptionDto {
  patientId: string;
  patientName: string;
  patientGender: Gender;
  patientAge: number;
  symptoms: string; // Khmer text
  medications: MedicationDto[];
  isUrgent?: boolean;
  urgentReason?: string;
}

// medication.dto.ts
export class MedicationDto {
  rowNumber: number;
  medicineName: string;
  medicineNameKhmer?: string;
  morningDosage?: DosageDto;
  daytimeDosage?: DosageDto;
  nightDosage?: DosageDto;
  imageUrl?: string;
}

// dosage.dto.ts
export class DosageDto {
  amount: string;
  beforeMeal: boolean;
}
```

2. Implement `prescriptions.service.ts`:
   - `create()` - Validate doctor-patient connection
   - `update()` - Create new version, preserve old
   - `urgentUpdate()` - Auto-apply and notify
   - `confirm()` - Activate and generate dose events
   - `retake()` - Mark for revision, notify doctor
   - `generateDoseEvents()` - Create schedule from grid

3. Implement `prescriptions.controller.ts`:
   - `POST /prescriptions` - Create
   - `GET /prescriptions` - List with filters
   - `GET /prescriptions/:id` - Get with versions
   - `PATCH /prescriptions/:id` - Update
   - `POST /prescriptions/:id/urgent-update` - Urgent
   - `POST /prescriptions/:id/confirm` - Confirm
   - `POST /prescriptions/:id/retake` - Request retake

### 📊 Phase 4: Doses Module

**Key Requirements**:
- Time period grouping (Daytime/Night)
- Status tracking (DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED)
- Adherence calculation
- Reminder time management

**Implementation Steps**:

1. Create DTOs:
```typescript
// mark-dose-taken.dto.ts
export class MarkDoseTakenDto {
  @IsOptional()
  @IsDateString()
  takenAt?: string;

  @IsOptional()
  @IsBoolean()
  offline?: boolean;
}

// skip-dose.dto.ts
export class SkipDoseDto {
  @IsString()
  @IsNotEmpty()
  reason: string;
}
```

2. Implement `doses.service.ts`:
   - `getSchedule(patientId, date, groupBy)` - Return grouped schedule
   - `markTaken(doseId, takenAt, offline)` - Apply time window logic
   - `skip(doseId, reason)` - Mark as skipped
   - `calculateDailyProgress(patientId, date)` - Percentage
   - `calculateAdherence(patientId, startDate, endDate)` - Percentage
   - `applyTimeWindowLogic(dose, takenAt)` - Determine status

3. Time window logic:
```typescript
private applyTimeWindowLogic(scheduledTime: Date, takenAt: Date): DoseEventStatus {
  const diffMinutes = (takenAt.getTime() - scheduledTime.getTime()) / 60000;
  
  if (diffMinutes >= -30 && diffMinutes <= 30) {
    return 'TAKEN_ON_TIME'; // Within 30 min window
  } else if (diffMinutes > 30 && diffMinutes <= 120) {
    return 'TAKEN_LATE'; // Late but within 2 hours
  } else {
    return 'MISSED'; // Too late
  }
}
```

### 🔗 Phase 5: Connections Module

**Key Requirements**:
- Mutual acceptance (doctor-patient)
- Permission levels (NOT_ALLOWED, REQUEST, SELECTED, ALLOWED)
- Family invitations (phone/email/QR code)

**Implementation Steps**:

1. Create DTOs:
```typescript
// create-connection.dto.ts
export class CreateConnectionDto {
  @IsUUID()
  targetUserId: string;

  @IsEnum(UserRole)
  targetRole: UserRole;
}

// accept-connection.dto.ts
export class AcceptConnectionDto {
  @IsOptional()
  @IsEnum(PermissionLevel)
  permissionLevel?: PermissionLevel; // Default: ALLOWED
}

// create-invitation.dto.ts
export class CreateInvitationDto {
  @IsEnum(['PHONE', 'EMAIL', 'QR_CODE'])
  method: string;

  @IsOptional()
  @IsString()
  contact?: string; // Required for PHONE and EMAIL
}
```

2. Implement `connections.service.ts`:
   - `requestConnection()` - Create pending connection
   - `acceptConnection()` - Accept and set permission
   - `revokeConnection()` - Revoke access
   - `updatePermission()` - Change permission level
   - `checkPermission()` - Validate access
   - `createInvitation()` - Generate token and QR code
   - `acceptInvitation()` - Create connection from token

### 🔔 Phase 6: Notifications Module

**Key Requirements**:
- Real-time delivery (SSE or WebSocket)
- Missed dose alerts to family
- Delayed notifications for offline sync

**Implementation Steps**:

1. Implement `notifications.service.ts`:
   - `send()` - Create and deliver notification
   - `sendMissedDoseAlert()` - Alert family members
   - `sendDelayedNotifications()` - Queue for offline users
   - `markAsRead()` - Update read status
   - `getNotifications()` - List with filters

2. Implement SSE endpoint:
```typescript
@Sse('notifications/stream')
@UseGuards(AuthGuard('jwt'))
async streamNotifications(@CurrentUser() user: any): Observable<MessageEvent> {
  return this.notificationsService.streamForUser(user.id);
}
```

### 📝 Phase 7: Audit Module

**Key Requirements**:
- Log all actions
- Immutable records
- IP address tracking

**Implementation Steps**:

1. Implement `audit.service.ts`:
```typescript
async log(entry: {
  actorId: string;
  actorRole: UserRole;
  actionType: AuditActionType;
  resourceType: string;
  resourceId: string;
  details?: any;
  ipAddress?: string;
}): Promise<void> {
  await this.prisma.auditLog.create({ data: entry });
}
```

2. Create audit interceptor:
```typescript
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    
    return next.handle().pipe(
      tap(() => {
        // Log action after successful execution
        this.auditService.log({
          actorId: user.id,
          actorRole: user.role,
          actionType: this.getActionType(request),
          resourceType: this.getResourceType(request),
          resourceId: request.params.id,
          ipAddress: request.ip,
        });
      }),
    );
  }
}
```

### 💳 Phase 8: Subscriptions Module

**Key Requirements**:
- Three tiers (FREEMIUM, PREMIUM, FAMILY_PREMIUM)
- Storage quota enforcement
- Family plan (max 3 members)

**Implementation Steps**:

1. Implement `subscriptions.service.ts`:
   - `getSubscription()` - Get current subscription
   - `upgradeTier()` - Change tier
   - `addFamilyMember()` - Add to family plan
   - `removeFamilyMember()` - Remove from family plan
   - `checkStorageQuota()` - Validate storage
   - `updateStorageUsage()` - Track usage

2. Create storage guard:
```typescript
@Injectable()
export class StorageQuotaGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const fileSize = request.headers['content-length'];
    
    const subscription = await this.subscriptionsService.getSubscription(user.id);
    
    if (subscription.storageUsed + fileSize > subscription.storageQuota) {
      throw new ForbiddenException('Storage quota exceeded');
    }
    
    return true;
  }
}
```

---

## 🧪 Testing Strategy

### Unit Tests
```bash
npm run test
```

Example test:
```typescript
describe('AuthService', () => {
  it('should register patient with OTP', async () => {
    const dto = {
      firstName: 'John',
      lastName: 'Doe',
      phoneNumber: '+85512345678',
      // ... other fields
    };
    
    const result = await authService.registerPatient(dto);
    
    expect(result.requiresOTP).toBe(true);
    expect(result.userId).toBeDefined();
  });
});
```

### E2E Tests
```bash
npm run test:e2e
```

Example E2E test:
```typescript
describe('Auth (e2e)', () => {
  it('/auth/register/patient (POST)', () => {
    return request(app.getHttpServer())
      .post('/auth/register/patient')
      .send(patientDto)
      .expect(201)
      .expect((res) => {
        expect(res.body.requiresOTP).toBe(true);
      });
  });
});
```

---

## 📚 Additional Resources

- **Prisma Docs**: https://www.prisma.io/docs
- **NestJS Docs**: https://docs.nestjs.com
- **Passport.js**: http://www.passportjs.org
- **Class Validator**: https://github.com/typestack/class-validator

---

## 🐛 Common Issues & Solutions

### Issue: Circular dependency between modules
**Solution**: Use `forwardRef()` or restructure to remove dependency

### Issue: Prisma Client not generated
**Solution**: Run `npm run prisma:generate`

### Issue: Database connection error
**Solution**: Check Docker containers with `docker compose ps`

### Issue: JWT token expired
**Solution**: Use refresh token endpoint to get new access token

---

## 📞 Need Help?

1. Check `IMPLEMENTATION_PROGRESS.md` for current status
2. Review `README.md` for setup instructions
3. Check `QUICK_REFERENCE.md` for commands
4. Review specs in `/home/rayu/das-tern/.kiro/specs/`

---

**Happy Coding! 🚀**
