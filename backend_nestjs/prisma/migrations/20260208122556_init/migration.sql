-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('PATIENT', 'DOCTOR', 'FAMILY_MEMBER');

-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('MALE', 'FEMALE', 'OTHER');

-- CreateEnum
CREATE TYPE "Language" AS ENUM ('KHMER', 'ENGLISH');

-- CreateEnum
CREATE TYPE "Theme" AS ENUM ('LIGHT', 'DARK');

-- CreateEnum
CREATE TYPE "AccountStatus" AS ENUM ('ACTIVE', 'PENDING_VERIFICATION', 'VERIFIED', 'REJECTED', 'LOCKED');

-- CreateEnum
CREATE TYPE "ConnectionStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REVOKED');

-- CreateEnum
CREATE TYPE "PermissionLevel" AS ENUM ('NOT_ALLOWED', 'REQUEST', 'SELECTED', 'ALLOWED');

-- CreateEnum
CREATE TYPE "PrescriptionStatus" AS ENUM ('DRAFT', 'ACTIVE', 'PAUSED', 'INACTIVE');

-- CreateEnum
CREATE TYPE "TimePeriod" AS ENUM ('DAYTIME', 'NIGHT');

-- CreateEnum
CREATE TYPE "DoseEventStatus" AS ENUM ('DUE', 'TAKEN_ON_TIME', 'TAKEN_LATE', 'MISSED', 'SKIPPED');

-- CreateEnum
CREATE TYPE "SubscriptionTier" AS ENUM ('FREEMIUM', 'PREMIUM', 'FAMILY_PREMIUM');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('CONNECTION_REQUEST', 'PRESCRIPTION_UPDATE', 'MISSED_DOSE_ALERT', 'URGENT_PRESCRIPTION_CHANGE', 'FAMILY_ALERT');

-- CreateEnum
CREATE TYPE "AuditActionType" AS ENUM ('CONNECTION_REQUEST', 'CONNECTION_ACCEPT', 'CONNECTION_REVOKE', 'PERMISSION_CHANGE', 'PRESCRIPTION_CREATE', 'PRESCRIPTION_UPDATE', 'PRESCRIPTION_CONFIRM', 'PRESCRIPTION_RETAKE', 'DOSE_TAKEN', 'DOSE_SKIPPED', 'DOSE_MISSED', 'DATA_ACCESS', 'NOTIFICATION_SENT', 'SUBSCRIPTION_CHANGE');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "role" "UserRole" NOT NULL,
    "firstName" VARCHAR(100),
    "lastName" VARCHAR(100),
    "fullName" VARCHAR(200),
    "phoneNumber" VARCHAR(20) NOT NULL,
    "email" VARCHAR(255),
    "passwordHash" VARCHAR(255) NOT NULL,
    "pinCodeHash" VARCHAR(255),
    "gender" "Gender",
    "dateOfBirth" DATE,
    "idCardNumber" VARCHAR(50),
    "language" "Language" NOT NULL DEFAULT 'KHMER',
    "theme" "Theme" NOT NULL DEFAULT 'LIGHT',
    "hospitalClinic" VARCHAR(255),
    "specialty" VARCHAR(100),
    "licenseNumber" VARCHAR(100),
    "licensePhotoUrl" TEXT,
    "accountStatus" "AccountStatus" NOT NULL DEFAULT 'ACTIVE',
    "failedLoginAttempts" INTEGER NOT NULL DEFAULT 0,
    "lockedUntil" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "connections" (
    "id" UUID NOT NULL,
    "initiatorId" UUID NOT NULL,
    "recipientId" UUID NOT NULL,
    "status" "ConnectionStatus" NOT NULL DEFAULT 'PENDING',
    "permissionLevel" "PermissionLevel" NOT NULL DEFAULT 'ALLOWED',
    "requestedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acceptedAt" TIMESTAMPTZ(3),
    "revokedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "connections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prescriptions" (
    "id" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "doctorId" UUID,
    "patientName" VARCHAR(200) NOT NULL,
    "patientGender" "Gender" NOT NULL,
    "patientAge" INTEGER NOT NULL,
    "symptoms" TEXT NOT NULL,
    "status" "PrescriptionStatus" NOT NULL DEFAULT 'DRAFT',
    "currentVersion" INTEGER NOT NULL DEFAULT 1,
    "isUrgent" BOOLEAN NOT NULL DEFAULT false,
    "urgentReason" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "prescriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prescription_versions" (
    "id" UUID NOT NULL,
    "prescriptionId" UUID NOT NULL,
    "versionNumber" INTEGER NOT NULL,
    "authorId" UUID,
    "changeReason" TEXT,
    "medicationsSnapshot" JSONB NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "prescription_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medications" (
    "id" UUID NOT NULL,
    "prescriptionId" UUID NOT NULL,
    "rowNumber" INTEGER NOT NULL,
    "medicineName" VARCHAR(255) NOT NULL,
    "medicineNameKhmer" VARCHAR(255),
    "imageUrl" TEXT,
    "morningDosage" JSONB,
    "daytimeDosage" JSONB,
    "nightDosage" JSONB,
    "frequency" VARCHAR(100),
    "timing" VARCHAR(100),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "medications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dose_events" (
    "id" UUID NOT NULL,
    "prescriptionId" UUID NOT NULL,
    "medicationId" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "scheduledTime" TIMESTAMPTZ(3) NOT NULL,
    "timePeriod" "TimePeriod" NOT NULL,
    "reminderTime" VARCHAR(10),
    "status" "DoseEventStatus" NOT NULL DEFAULT 'DUE',
    "takenAt" TIMESTAMPTZ(3),
    "skipReason" TEXT,
    "wasOffline" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "dose_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "recipientId" UUID NOT NULL,
    "type" "NotificationType" NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "message" TEXT NOT NULL,
    "data" JSONB,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "readAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "actorId" UUID,
    "actorRole" "UserRole",
    "actionType" "AuditActionType" NOT NULL,
    "resourceType" VARCHAR(100) NOT NULL,
    "resourceId" UUID,
    "details" JSONB,
    "ipAddress" VARCHAR(45),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "tier" "SubscriptionTier" NOT NULL DEFAULT 'FREEMIUM',
    "storageQuota" BIGINT NOT NULL DEFAULT 5368709120,
    "storageUsed" BIGINT NOT NULL DEFAULT 0,
    "expiresAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "family_members" (
    "id" UUID NOT NULL,
    "subscriptionId" UUID NOT NULL,
    "memberId" UUID NOT NULL,
    "addedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "family_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "meal_time_preferences" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "morningMeal" VARCHAR(20),
    "afternoonMeal" VARCHAR(20),
    "nightMeal" VARCHAR(20),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "meal_time_preferences_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phoneNumber_key" ON "users"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_idCardNumber_key" ON "users"("idCardNumber");

-- CreateIndex
CREATE UNIQUE INDEX "users_licenseNumber_key" ON "users"("licenseNumber");

-- CreateIndex
CREATE INDEX "users_phoneNumber_idx" ON "users"("phoneNumber");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_role_idx" ON "users"("role");

-- CreateIndex
CREATE INDEX "users_accountStatus_idx" ON "users"("accountStatus");

-- CreateIndex
CREATE INDEX "connections_initiatorId_idx" ON "connections"("initiatorId");

-- CreateIndex
CREATE INDEX "connections_recipientId_idx" ON "connections"("recipientId");

-- CreateIndex
CREATE INDEX "connections_status_idx" ON "connections"("status");

-- CreateIndex
CREATE UNIQUE INDEX "connections_initiatorId_recipientId_key" ON "connections"("initiatorId", "recipientId");

-- CreateIndex
CREATE INDEX "prescriptions_patientId_idx" ON "prescriptions"("patientId");

-- CreateIndex
CREATE INDEX "prescriptions_doctorId_idx" ON "prescriptions"("doctorId");

-- CreateIndex
CREATE INDEX "prescriptions_status_idx" ON "prescriptions"("status");

-- CreateIndex
CREATE INDEX "prescriptions_patientId_status_idx" ON "prescriptions"("patientId", "status");

-- CreateIndex
CREATE INDEX "prescription_versions_prescriptionId_idx" ON "prescription_versions"("prescriptionId");

-- CreateIndex
CREATE UNIQUE INDEX "prescription_versions_prescriptionId_versionNumber_key" ON "prescription_versions"("prescriptionId", "versionNumber");

-- CreateIndex
CREATE INDEX "medications_prescriptionId_idx" ON "medications"("prescriptionId");

-- CreateIndex
CREATE INDEX "dose_events_patientId_idx" ON "dose_events"("patientId");

-- CreateIndex
CREATE INDEX "dose_events_scheduledTime_idx" ON "dose_events"("scheduledTime");

-- CreateIndex
CREATE INDEX "dose_events_status_idx" ON "dose_events"("status");

-- CreateIndex
CREATE INDEX "dose_events_patientId_scheduledTime_idx" ON "dose_events"("patientId", "scheduledTime");

-- CreateIndex
CREATE INDEX "dose_events_prescriptionId_idx" ON "dose_events"("prescriptionId");

-- CreateIndex
CREATE INDEX "notifications_recipientId_idx" ON "notifications"("recipientId");

-- CreateIndex
CREATE INDEX "notifications_recipientId_isRead_idx" ON "notifications"("recipientId", "isRead");

-- CreateIndex
CREATE INDEX "notifications_createdAt_idx" ON "notifications"("createdAt");

-- CreateIndex
CREATE INDEX "audit_logs_actorId_idx" ON "audit_logs"("actorId");

-- CreateIndex
CREATE INDEX "audit_logs_resourceId_idx" ON "audit_logs"("resourceId");

-- CreateIndex
CREATE INDEX "audit_logs_createdAt_idx" ON "audit_logs"("createdAt");

-- CreateIndex
CREATE INDEX "audit_logs_actionType_idx" ON "audit_logs"("actionType");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_userId_key" ON "subscriptions"("userId");

-- CreateIndex
CREATE INDEX "subscriptions_userId_idx" ON "subscriptions"("userId");

-- CreateIndex
CREATE INDEX "subscriptions_tier_idx" ON "subscriptions"("tier");

-- CreateIndex
CREATE INDEX "family_members_subscriptionId_idx" ON "family_members"("subscriptionId");

-- CreateIndex
CREATE UNIQUE INDEX "family_members_subscriptionId_memberId_key" ON "family_members"("subscriptionId", "memberId");

-- CreateIndex
CREATE UNIQUE INDEX "meal_time_preferences_userId_key" ON "meal_time_preferences"("userId");

-- CreateIndex
CREATE INDEX "meal_time_preferences_userId_idx" ON "meal_time_preferences"("userId");

-- AddForeignKey
ALTER TABLE "connections" ADD CONSTRAINT "connections_initiatorId_fkey" FOREIGN KEY ("initiatorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "connections" ADD CONSTRAINT "connections_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prescriptions" ADD CONSTRAINT "prescriptions_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prescriptions" ADD CONSTRAINT "prescriptions_doctorId_fkey" FOREIGN KEY ("doctorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prescription_versions" ADD CONSTRAINT "prescription_versions_prescriptionId_fkey" FOREIGN KEY ("prescriptionId") REFERENCES "prescriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prescription_versions" ADD CONSTRAINT "prescription_versions_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medications" ADD CONSTRAINT "medications_prescriptionId_fkey" FOREIGN KEY ("prescriptionId") REFERENCES "prescriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dose_events" ADD CONSTRAINT "dose_events_prescriptionId_fkey" FOREIGN KEY ("prescriptionId") REFERENCES "prescriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dose_events" ADD CONSTRAINT "dose_events_medicationId_fkey" FOREIGN KEY ("medicationId") REFERENCES "medications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dose_events" ADD CONSTRAINT "dose_events_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "subscriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "family_members" ADD CONSTRAINT "family_members_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meal_time_preferences" ADD CONSTRAINT "meal_time_preferences_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
