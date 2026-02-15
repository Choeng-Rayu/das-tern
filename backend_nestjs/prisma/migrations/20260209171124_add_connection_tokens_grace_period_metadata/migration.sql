-- AlterTable
ALTER TABLE "connections" ADD COLUMN     "metadata" JSONB;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "gracePeriodMinutes" INTEGER NOT NULL DEFAULT 30;

-- CreateTable
CREATE TABLE "connection_tokens" (
    "id" UUID NOT NULL,
    "patientId" UUID NOT NULL,
    "token" VARCHAR(20) NOT NULL,
    "permissionLevel" "PermissionLevel" NOT NULL DEFAULT 'ALLOWED',
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "usedAt" TIMESTAMPTZ(3),
    "usedById" UUID,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "connection_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "connection_tokens_token_key" ON "connection_tokens"("token");

-- CreateIndex
CREATE INDEX "connection_tokens_token_idx" ON "connection_tokens"("token");

-- CreateIndex
CREATE INDEX "connection_tokens_patientId_idx" ON "connection_tokens"("patientId");

-- CreateIndex
CREATE INDEX "connection_tokens_expiresAt_idx" ON "connection_tokens"("expiresAt");

-- AddForeignKey
ALTER TABLE "connection_tokens" ADD CONSTRAINT "connection_tokens_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
