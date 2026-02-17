-- CreateTable
CREATE TABLE "medication_batches" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "patientId" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "scheduledTime" VARCHAR(10) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "medication_batches_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "medications" ADD COLUMN "batchId" UUID;

-- CreateIndex
CREATE INDEX "medication_batches_patientId_idx" ON "medication_batches"("patientId");

-- CreateIndex
CREATE INDEX "medication_batches_patientId_isActive_idx" ON "medication_batches"("patientId", "isActive");

-- CreateIndex
CREATE INDEX "medications_batchId_idx" ON "medications"("batchId");

-- AddForeignKey
ALTER TABLE "medications" ADD CONSTRAINT "medications_batchId_fkey" FOREIGN KEY ("batchId") REFERENCES "medication_batches"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_batches" ADD CONSTRAINT "medication_batches_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
