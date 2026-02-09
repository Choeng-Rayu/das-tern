# Database Migration Guide

## Overview

This guide documents the database migration process for the Das Tern Backend API. The project uses Prisma ORM with PostgreSQL 17 for database management.

## Initial Migration

The initial migration (`init`) was created on **2024-02-08** and includes the complete database schema for the Das Tern application.

### Migration Details

**Migration Name:** `20260208074559_init`

**Created:** February 8, 2024

**Database:** PostgreSQL 17

**Schema Version:** 1.0.0

### Schema Components

The initial migration creates the following database objects:

#### Enums (14 types)
- `UserRole`: PATIENT, DOCTOR, FAMILY_MEMBER
- `Gender`: MALE, FEMALE, OTHER
- `Language`: KHMER, ENGLISH
- `Theme`: LIGHT, DARK
- `AccountStatus`: ACTIVE, PENDING_VERIFICATION, VERIFIED, REJECTED, LOCKED
- `ConnectionStatus`: PENDING, ACCEPTED, REVOKED
- `PermissionLevel`: NOT_ALLOWED, REQUEST, SELECTED, ALLOWED
- `PrescriptionStatus`: DRAFT, ACTIVE, PAUSED, INACTIVE
- `TimePeriod`: DAYTIME, NIGHT
- `DoseEventStatus`: DUE, TAKEN_ON_TIME, TAKEN_LATE, MISSED, SKIPPED
- `SubscriptionTier`: FREEMIUM, PREMIUM, FAMILY_PREMIUM
- `NotificationType`: CONNECTION_REQUEST, PRESCRIPTION_UPDATE, MISSED_DOSE_ALERT, URGENT_PRESCRIPTION_CHANGE, FAMILY_ALERT
- `AuditActionType`: CONNECTION_REQUEST, CONNECTION_ACCEPT, CONNECTION_REVOKE, PERMISSION_CHANGE, PRESCRIPTION_CREATE, PRESCRIPTION_UPDATE, PRESCRIPTION_CONFIRM, PRESCRIPTION_RETAKE, DOSE_TAKEN, DOSE_SKIPPED, DOSE_MISSED, DATA_ACCESS, NOTIFICATION_SENT, SUBSCRIPTION_CHANGE

#### Tables (11 tables)
1. **users** - User accounts (patients, doctors, family members)
2. **connections** - Relationships between users
3. **prescriptions** - Medication prescriptions
4. **prescription_versions** - Version history for prescriptions
5. **medications** - Individual medications within prescriptions
6. **dose_events** - Scheduled medication doses
7. **notifications** - User notifications
8. **audit_logs** - Audit trail for all actions
9. **subscriptions** - User subscription plans
10. **family_members** - Family premium subscription members
11. **meal_time_preferences** - User meal time preferences

#### Indexes (30+ indexes)
- Primary key indexes on all tables
- Foreign key indexes for relationships
- Performance indexes on frequently queried fields
- Composite indexes for common query patterns

#### Foreign Keys (15 relationships)
- Cascade deletes for dependent data
- Set null for optional relationships
- Referential integrity enforcement

## Prerequisites

Before running migrations, ensure:

1. **Docker is running:**
   ```bash
   sudo systemctl start docker
   ```

2. **PostgreSQL container is up:**
   ```bash
   docker compose up -d postgres
   ```

3. **Database is accessible:**
   ```bash
   docker exec dastern-postgres pg_isready -U dastern_user -d dastern
   ```

4. **Environment variables are set:**
   - Copy `.env` from root to `backend/` directory if not present
   - Verify `DATABASE_URL` is correctly configured

## Running Migrations

### Development Environment

To apply migrations in development:

```bash
cd backend
npx prisma migrate dev
```

This command will:
- Apply pending migrations
- Generate Prisma Client
- Optionally run seed scripts

### Production Environment

To apply migrations in production:

```bash
cd backend
npx prisma migrate deploy
```

This command will:
- Apply pending migrations only
- Not generate Prisma Client
- Not run seed scripts

### Creating New Migrations

When you modify the Prisma schema:

```bash
cd backend
npx prisma migrate dev --name descriptive_migration_name
```

Example:
```bash
npx prisma migrate dev --name add_user_avatar_field
```

## Prisma Client Generation

After pulling new migrations or modifying the schema:

```bash
cd backend
npx prisma generate
```

This regenerates the Prisma Client with updated types.

## Database Inspection

### View Current Schema

```bash
cd backend
npx prisma db pull
```

### Open Prisma Studio

```bash
cd backend
npx prisma studio
```

This opens a web interface at `http://localhost:5555` for browsing and editing data.

### Check Migration Status

```bash
cd backend
npx prisma migrate status
```

## Rollback Migrations

Prisma doesn't support automatic rollbacks. To rollback:

1. **Restore from backup:**
   ```bash
   docker exec -i dastern-postgres psql -U dastern_user -d dastern < backup.sql
   ```

2. **Or manually revert:**
   - Delete the migration folder
   - Reset the database
   - Reapply desired migrations

## Database Seeding

To seed the database with test data:

```bash
cd backend
npx prisma db seed
```

The seed script is located at `backend/prisma/seed.ts`.

## Troubleshooting

### Migration Failed

If a migration fails:

1. Check database logs:
   ```bash
   docker logs dastern-postgres --tail 50
   ```

2. Verify database connection:
   ```bash
   docker exec dastern-postgres psql -U dastern_user -d dastern -c "SELECT version();"
   ```

3. Reset database (development only):
   ```bash
   npx prisma migrate reset
   ```

### Connection Issues

If you can't connect to the database:

1. Verify PostgreSQL is running:
   ```bash
   docker ps | grep postgres
   ```

2. Check DATABASE_URL in `.env`:
   ```
   DATABASE_URL="postgresql://dastern_user:dastern_rayu@localhost:5432/dastern?schema=public"
   ```

3. Test connection:
   ```bash
   docker exec dastern-postgres pg_isready -U dastern_user -d dastern
   ```

### Schema Drift

If Prisma detects schema drift:

```bash
npx prisma db push
```

This syncs the database with your schema without creating a migration.

## Best Practices

1. **Always backup before migrations** in production
2. **Test migrations** in a staging environment first
3. **Use descriptive migration names** that explain the change
4. **Review generated SQL** before applying migrations
5. **Never edit migration files** after they've been applied
6. **Keep schema.prisma** as the single source of truth
7. **Run migrations** during low-traffic periods in production
8. **Monitor migration performance** for large tables

## Database Configuration

### Connection Pool Settings

The PostgreSQL container is configured with:
- Max connections: 20
- Shared buffers: 256MB
- Effective cache size: 1GB
- Timezone: Asia/Phnom_Penh (UTC+7)

### Storage Quotas

Default storage quotas by subscription tier:
- FREEMIUM: 5GB (5,368,709,120 bytes)
- PREMIUM: 20GB (21,474,836,480 bytes)
- FAMILY_PREMIUM: 20GB (21,474,836,480 bytes)

## Migration History

| Date | Migration | Description |
|------|-----------|-------------|
| 2024-02-08 | `20260208074559_init` | Initial database schema with all tables, enums, indexes, and foreign keys |

## Additional Resources

- [Prisma Documentation](https://www.prisma.io/docs)
- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [Das Tern API Design Document](.kiro/specs/das-tern-backend-api/design.md)
- [Das Tern API Requirements](.kiro/specs/das-tern-backend-api/requirements.md)

## Support

For migration issues or questions:
1. Check the troubleshooting section above
2. Review Prisma logs in `backend/prisma/migrations/`
3. Consult the team's technical documentation
4. Contact the database administrator

---

**Last Updated:** February 8, 2024
**Schema Version:** 1.0.0
**Prisma Version:** 6.2.0
**PostgreSQL Version:** 17
