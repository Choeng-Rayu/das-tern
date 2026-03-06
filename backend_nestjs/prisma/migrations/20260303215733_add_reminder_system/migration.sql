-- CreateEnum
CREATE TYPE "ReminderStatus" AS ENUM ('PENDING', 'DELIVERING', 'DELIVERED', 'SNOOZED', 'COMPLETED', 'MISSED', 'FAILED');

-- AlterEnum
ALTER TYPE "AuditActionType" ADD VALUE 'REMINDER_GENERATED';
ALTER TYPE "AuditActionType" ADD VALUE 'REMINDER_SNOOZED';

-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'REMINDER_DELIVERED';
ALTER TYPE "NotificationType" ADD VALUE 'REMINDER_SNOOZED';

-- AlterEnum
ALTER TYPE "TimePeriod" ADD VALUE 'MORNING';

-- AlterTable
ALTER TABLE "dose_events" ADD COLUMN "reminderId" UUID;

-- AlterTable
ALTER TABLE "medications" ADD COLUMN "customTimes" JSONB,
ADD COLUMN "remindersEnabled" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "users" ADD COLUMN "repeatIntervalMinutes" INTEGER NOT NULL DEFAULT 10,
ADD COLUMN "repeatRemindersEnabled" BOOLEAN NOT NULL DEFAULT true;

-- CreateTable
CREATE TABLE "reminders" (
    "id" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "medicationId" UUID NOT NULL,
    "prescriptionId" UUID NOT NULL,
    "scheduledTime" TIMESTAMPTZ(3) NOT NULL,
    "timePeriod" "TimePeriod" NOT NULL,
    "status" "ReminderStatus" NOT NULL DEFAULT 'PENDING',
    "deliveredAt" TIMESTAMPTZ(3),
    "completedAt" TIMESTAMPTZ(3),
    "snoozedUntil" TIMESTAMPTZ(3),
    "snoozeCount" INTEGER NOT NULL DEFAULT 0,
    "repeatCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "reminders_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "reminders_patientId_scheduledTime_idx" ON "reminders"("patientId", "scheduledTime");

-- CreateIndex
CREATE INDEX "reminders_status_scheduledTime_idx" ON "reminders"("status", "scheduledTime");

-- CreateIndex
CREATE INDEX "reminders_medicationId_idx" ON "reminders"("medicationId");

-- CreateIndex
CREATE UNIQUE INDEX "dose_events_reminderId_key" ON "dose_events"("reminderId");

-- AddForeignKey
ALTER TABLE "dose_events" ADD CONSTRAINT "dose_events_reminderId_fkey" FOREIGN KEY ("reminderId") REFERENCES "reminders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_medicationId_fkey" FOREIGN KEY ("medicationId") REFERENCES "medications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_prescriptionId_fkey" FOREIGN KEY ("prescriptionId") REFERENCES "prescriptions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
