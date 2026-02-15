-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "AuditActionType" ADD VALUE 'DOCTOR_NOTE_CREATE';
ALTER TYPE "AuditActionType" ADD VALUE 'DOCTOR_NOTE_UPDATE';
ALTER TYPE "AuditActionType" ADD VALUE 'DOCTOR_DISCONNECT';

-- CreateTable
CREATE TABLE "doctor_notes" (
    "id" UUID NOT NULL,
    "doctorId" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "doctor_notes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "doctor_notes_doctorId_idx" ON "doctor_notes"("doctorId");

-- CreateIndex
CREATE INDEX "doctor_notes_patientId_idx" ON "doctor_notes"("patientId");

-- CreateIndex
CREATE INDEX "doctor_notes_createdAt_idx" ON "doctor_notes"("createdAt");

-- CreateIndex
CREATE INDEX "doctor_notes_doctorId_patientId_idx" ON "doctor_notes"("doctorId", "patientId");

-- AddForeignKey
ALTER TABLE "doctor_notes" ADD CONSTRAINT "doctor_notes_doctorId_fkey" FOREIGN KEY ("doctorId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_notes" ADD CONSTRAINT "doctor_notes_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
