-- AlterTable
ALTER TABLE "connection_tokens" ADD COLUMN "targetRole" VARCHAR(20) NOT NULL DEFAULT 'FAMILY_MEMBER';
