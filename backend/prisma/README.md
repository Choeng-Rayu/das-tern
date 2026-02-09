# Prisma Database Setup

## Quick Start

### 1. Start Database

```bash
# Start PostgreSQL container
docker compose up -d postgres

# Verify it's running
docker ps | grep postgres
```

### 2. Apply Migrations

```bash
# Navigate to backend directory
cd backend

# Apply all migrations
npx prisma migrate dev
```

### 3. Generate Prisma Client

```bash
# Generate TypeScript client
npx prisma generate
```

### 4. (Optional) Seed Database

```bash
# Run seed script
npx prisma db seed
```

## Common Commands

### Development

```bash
# Create a new migration
npx prisma migrate dev --name migration_name

# Reset database (WARNING: deletes all data)
npx prisma migrate reset

# Open Prisma Studio (database GUI)
npx prisma studio

# Check migration status
npx prisma migrate status
```

### Production

```bash
# Apply migrations (no client generation)
npx prisma migrate deploy

# Generate Prisma Client
npx prisma generate
```

### Database Inspection

```bash
# Pull current database schema
npx prisma db pull

# Push schema changes without migration
npx prisma db push

# Validate schema
npx prisma validate
```

## Database Schema

The database includes:

- **11 tables**: users, connections, prescriptions, medications, dose_events, notifications, audit_logs, subscriptions, family_members, meal_time_preferences, prescription_versions
- **14 enums**: UserRole, Gender, Language, Theme, AccountStatus, ConnectionStatus, PermissionLevel, PrescriptionStatus, TimePeriod, DoseEventStatus, SubscriptionTier, NotificationType, AuditActionType
- **30+ indexes**: For optimal query performance
- **15 foreign keys**: Ensuring referential integrity

## Environment Variables

Required in `.env` file:

```env
DATABASE_URL="postgresql://dastern_user:dastern_rayu@localhost:5432/dastern?schema=public"
```

## Troubleshooting

### Can't connect to database

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check database health
docker exec dastern-postgres pg_isready -U dastern_user -d dastern

# View logs
docker logs dastern-postgres --tail 50
```

### Migration failed

```bash
# Check migration status
npx prisma migrate status

# View detailed error
npx prisma migrate dev --create-only

# Reset and retry (development only)
npx prisma migrate reset
```

### Schema drift detected

```bash
# Sync schema without migration
npx prisma db push

# Or create a new migration
npx prisma migrate dev --name fix_schema_drift
```

## File Structure

```
backend/prisma/
├── schema.prisma           # Database schema definition
├── seed.ts                 # Database seeding script
├── migrations/             # Migration history
│   ├── 20260208074559_init/
│   │   └── migration.sql
│   └── migration_lock.toml
├── MIGRATION_GUIDE.md      # Detailed migration documentation
└── README.md               # This file
```

## Additional Documentation

- [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) - Comprehensive migration documentation
- [schema.prisma](./schema.prisma) - Database schema definition
- [Prisma Docs](https://www.prisma.io/docs) - Official Prisma documentation

## Database Access

### Via Docker

```bash
# Connect to PostgreSQL
docker exec -it dastern-postgres psql -U dastern_user -d dastern

# Run SQL query
docker exec dastern-postgres psql -U dastern_user -d dastern -c "SELECT COUNT(*) FROM users;"
```

### Via Prisma Studio

```bash
# Open web interface at http://localhost:5555
npx prisma studio
```

## Timezone Configuration

The database is configured to use **Cambodia timezone (Asia/Phnom_Penh, UTC+7)** by default.

All timestamp fields use `TIMESTAMPTZ(3)` for timezone-aware storage with millisecond precision.

## Storage Quotas

Default quotas by subscription tier:
- **FREEMIUM**: 5GB
- **PREMIUM**: 20GB  
- **FAMILY_PREMIUM**: 20GB

## Support

For issues or questions:
1. Check [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)
2. Review [Prisma documentation](https://www.prisma.io/docs)
3. Check Docker logs: `docker logs dastern-postgres`
4. Contact the development team

---

**Schema Version:** 1.0.0  
**Prisma Version:** 6.2.0  
**PostgreSQL Version:** 17
