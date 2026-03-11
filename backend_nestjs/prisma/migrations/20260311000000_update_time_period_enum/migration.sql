-- AlterEnum: Add MORNING, AFTERNOON, EVENING to TimePeriod (replacing DAYTIME)

-- Step 1: Add new enum values
ALTER TYPE "TimePeriod" ADD VALUE IF NOT EXISTS 'MORNING';
ALTER TYPE "TimePeriod" ADD VALUE IF NOT EXISTS 'AFTERNOON';
ALTER TYPE "TimePeriod" ADD VALUE IF NOT EXISTS 'EVENING';

-- Step 2: Migrate existing DAYTIME data to AFTERNOON
-- Note: PostgreSQL doesn't allow removing enum values directly.
-- We rename DAYTIME rows to AFTERNOON, then recreate the enum without DAYTIME.

-- We need to: create new enum, migrate column, drop old enum
-- Because PG can add values but not remove them, we recreate the type.

-- 2a. Create the new enum type
CREATE TYPE "TimePeriod_new" AS ENUM ('MORNING', 'AFTERNOON', 'EVENING', 'NIGHT');

-- 2b. Update the dose_events table: convert DAYTIME → AFTERNOON
ALTER TABLE "dose_events"
  ALTER COLUMN "timePeriod" TYPE "TimePeriod_new"
  USING (
    CASE "timePeriod"::text
      WHEN 'DAYTIME' THEN 'AFTERNOON'::"TimePeriod_new"
      ELSE "timePeriod"::text::"TimePeriod_new"
    END
  );

-- 2c. Drop old enum and rename new one
DROP TYPE "TimePeriod";
ALTER TYPE "TimePeriod_new" RENAME TO "TimePeriod";

-- Step 3: Add eveningMeal column to meal_time_preferences
ALTER TABLE "meal_time_preferences" ADD COLUMN IF NOT EXISTS "eveningMeal" VARCHAR(20);

-- Step 4: Rename daytimeDosage to afternoonDosage and add eveningDosage on medications
ALTER TABLE "medications" RENAME COLUMN "daytimeDosage" TO "afternoonDosage";
ALTER TABLE "medications" ADD COLUMN IF NOT EXISTS "eveningDosage" JSONB;
