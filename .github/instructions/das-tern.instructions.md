---
applyTo: '**'
---
AI AGENT RULES – DOCKER (POSTGRES & REDIS), NESTJS BACKEND, MOBILE APP


Scope
=====
- Docker is used ONLY to run PostgreSQL and Redis
- Backend framework is Nest (Nest.js)
- bakong_payment is implemented separately and is NOT part of this scope
- Mobile app consumes the backend API
- No OCR services
- No AI or LLM services


Core Rules
==========

1. Sensitive File Awareness
---------------------------
Treat the following files and directories as sensitive and high-risk:

- Database schema and migration files
  (SQL files, Prisma schema, TypeORM/MikroORM migrations)

- Environment variables
  (.env, .env.development, .env.production, .env.*)

- Database initialization scripts
  (init.sql, seed.sql, migration scripts)

Any detected change to these files MUST trigger a Docker consistency check
and container lifecycle validation.


2. Good Project File Structure Enforcement
------------------------------------------
The agent MUST enforce a clean and predictable project structure.

Recommended structure:

Rules:
- Docker is ONLY responsible for Postgres and Redis.
- Backend (NestJS) runs outside Docker unless explicitly stated.
- Database scripts must live under docker/postgres/ or backend_nestjs/database/.
- .env files must NEVER be hardcoded inside source code.
- .env.example must list ALL required environment variables.
- docker-compose.yml must reference correct database paths and variables.

If file placement or structure is incorrect, the agent must suggest
or apply restructuring.


3. Docker Compose Validation
----------------------------
After modifying any sensitive files, the agent MUST inspect docker-compose.yml
for:

- PostgreSQL service configuration
- Redis service configuration
- Environment variable mappings from .env
- Volume mounts for PostgreSQL data and init scripts
- Port mappings for local development

If mismatches or outdated references are found, the agent MUST update them.

5. backend_nestjs Configuration Verification
----------------------------------------------
After Docker containers are running, the agent MUST verify:

- backend_nestjs database connection matches .env values
- PostgreSQL host, port, user, and database name are correct
- Redis connection settings are correct
- No hardcoded credentials exist in the backend source code
- Backend starts without database or cache connection errors


6. Database State Verification
------------------------------
The agent MUST verify:

- PostgreSQL schema matches latest migration definitions
- Migrations run successfully
- Redis is reachable and operational
- No database or Redis errors appear in logs


7. Error Handling and Recovery
------------------------------
If any issue occurs (connection failure, migration error, container crash):

- Inspect Docker logs for Postgres and Redis
- Inspect backend (NestJS) logs
- Identify the root cause
- Propose or apply fixes
- Restart containers and backend
- Re-verify system stability


Expected Agent Behavior
======================

- Warns when Docker restart or volume reset is required
- Never assumes .env changes apply automatically
- Enforces clean file structure and separation of concerns
- Keeps PostgreSQL, Redis, backend_nestjs, and mobile app (das_tern_mcp)in sync
- Prioritizes data integrity, system stability and Security both backend and mobile
- Reports issues clearly and resolves them when possible


End of Rules
============
