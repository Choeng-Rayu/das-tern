/*
  Warnings:

  - You are about to drop the column `pinCodeHash` on the `users` table. All the data in the column will be lost.

*/
-- CreateEnum
CREATE TYPE "MedicineType" AS ENUM ('PO', 'ORAL', 'INJECTION', 'TOPICAL', 'OTHER');

-- CreateEnum
CREATE TYPE "MedicineUnit" AS ENUM ('TABLET', 'CAPSULE', 'ML', 'MG', 'DROP', 'OTHER');

-- CreateEnum
CREATE TYPE "VitalType" AS ENUM ('BLOOD_PRESSURE', 'GLUCOSE', 'HEART_RATE', 'WEIGHT', 'TEMPERATURE', 'SPO2');

-- CreateEnum
CREATE TYPE "AlertSeverity" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "AuditActionType" ADD VALUE 'VITAL_RECORDED';
ALTER TYPE "AuditActionType" ADD VALUE 'EMERGENCY_TRIGGERED';

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "NotificationType" ADD VALUE 'VITAL_ANOMALY';
ALTER TYPE "NotificationType" ADD VALUE 'EMERGENCY_ALERT';

-- AlterTable
ALTER TABLE "medications" ADD COLUMN     "additionalNote" TEXT,
ADD COLUMN     "beforeMeal" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "createdBy" UUID,
ADD COLUMN     "description" TEXT,
ADD COLUMN     "dosageAmount" DOUBLE PRECISION NOT NULL DEFAULT 1,
ADD COLUMN     "duration" INTEGER,
ADD COLUMN     "isPRN" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "medicineType" "MedicineType" NOT NULL DEFAULT 'ORAL',
ADD COLUMN     "unit" "MedicineUnit" NOT NULL DEFAULT 'TABLET';

-- AlterTable
ALTER TABLE "prescriptions" ADD COLUMN     "clinicalNote" TEXT,
ADD COLUMN     "diagnosis" TEXT,
ADD COLUMN     "doctorLicenseNumber" VARCHAR(100),
ADD COLUMN     "endDate" DATE,
ADD COLUMN     "followUpDate" DATE,
ADD COLUMN     "startDate" DATE;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "pinCodeHash",
ADD COLUMN     "profilePictureUrl" TEXT;

-- CreateTable
CREATE TABLE "health_vitals" (
    "id" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "vitalType" "VitalType" NOT NULL,
    "value" DOUBLE PRECISION NOT NULL,
    "valueSecondary" DOUBLE PRECISION,
    "unit" VARCHAR(20) NOT NULL,
    "measuredAt" TIMESTAMPTZ(3) NOT NULL,
    "notes" TEXT,
    "isAbnormal" BOOLEAN NOT NULL DEFAULT false,
    "source" VARCHAR(50) DEFAULT 'manual',
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "health_vitals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "vital_thresholds" (
    "id" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "vitalType" "VitalType" NOT NULL,
    "minValue" DOUBLE PRECISION,
    "maxValue" DOUBLE PRECISION,
    "minSecondary" DOUBLE PRECISION,
    "maxSecondary" DOUBLE PRECISION,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "vital_thresholds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "health_alerts" (
    "id" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "vitalId" UUID,
    "alertType" VARCHAR(50) NOT NULL,
    "severity" "AlertSeverity" NOT NULL DEFAULT 'MEDIUM',
    "message" TEXT NOT NULL,
    "isResolved" BOOLEAN NOT NULL DEFAULT false,
    "resolvedAt" TIMESTAMPTZ(3),
    "resolvedBy" UUID,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "health_alerts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "health_vitals_patientId_idx" ON "health_vitals"("patientId");

-- CreateIndex
CREATE INDEX "health_vitals_vitalType_idx" ON "health_vitals"("vitalType");

-- CreateIndex
CREATE INDEX "health_vitals_measuredAt_idx" ON "health_vitals"("measuredAt");

-- CreateIndex
CREATE INDEX "health_vitals_patientId_vitalType_measuredAt_idx" ON "health_vitals"("patientId", "vitalType", "measuredAt");

-- CreateIndex
CREATE INDEX "vital_thresholds_patientId_idx" ON "vital_thresholds"("patientId");

-- CreateIndex
CREATE UNIQUE INDEX "vital_thresholds_patientId_vitalType_key" ON "vital_thresholds"("patientId", "vitalType");

-- CreateIndex
CREATE INDEX "health_alerts_patientId_idx" ON "health_alerts"("patientId");

-- CreateIndex
CREATE INDEX "health_alerts_isResolved_idx" ON "health_alerts"("isResolved");

-- CreateIndex
CREATE INDEX "health_alerts_createdAt_idx" ON "health_alerts"("createdAt");

-- AddForeignKey
ALTER TABLE "health_vitals" ADD CONSTRAINT "health_vitals_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "vital_thresholds" ADD CONSTRAINT "vital_thresholds_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_alerts" ADD CONSTRAINT "health_alerts_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_alerts" ADD CONSTRAINT "health_alerts_vitalId_fkey" FOREIGN KEY ("vitalId") REFERENCES "health_vitals"("id") ON DELETE SET NULL ON UPDATE CASCADE;
