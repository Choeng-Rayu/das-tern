-- AlterTable
ALTER TABLE "users"
  ADD COLUMN IF NOT EXISTS "telegramId" VARCHAR(255),
  ADD COLUMN IF NOT EXISTS "telegramUsername" VARCHAR(255),
  ADD COLUMN IF NOT EXISTS "telegramFirstName" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "telegramLastName" VARCHAR(100),
  ADD COLUMN IF NOT EXISTS "telegramPhotoUrl" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "users_telegramId_key" ON "users"("telegramId");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "users_telegramId_idx" ON "users"("telegramId");
