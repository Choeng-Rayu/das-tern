AI AGENT RULES – DASTERN ARCHITECTURE & WORKFLOW


Architecture Overview
=====================

System Components:

1. backend (NestJS)
   - Main business logic
   - Handles authentication, medication, users, payment processing
   - Communicates with Bakong Service
   - Connects to PostgreSQL and Redis (via Docker)

2. bakong_service (Separate VPS)
   - Handles Bakong payment integration
   - Receives encrypted payload from backend
   - Generates QR code via Bakong API
   - Receives payment notification from Bakong
   - Sends payment success callback to main backend
   - Does NOT connect to the main PostgreSQL/Redis Docker
   - Stores only minimal payment-related data

3. frontend: das_tern_mcp (Flutter)
   - Mobile application
   - Communicates only with backend (NOT directly with bakong_service)

4. Database
   - PostgreSQL (Docker only)
   - Redis (Docker only)
   - Docker is used ONLY for Postgres and Redis


System Flow
===========

Payment Flow:

1. Flutter app sends payment request to backend (NestJS).
2. Backend encrypts payload and sends request to bakong_service.
3. bakong_service calls Bakong API and generates QR code.
4. bakong_service returns QR code response to backend.
5. Backend sends QR code to Flutter app.
6. User pays via Bakong.
7. Bakong sends payment notification to bakong_service.
8. bakong_service validates and notifies backend.
9. Backend updates payment status in PostgreSQL.
10. Backend confirms successful payment to frontend.

Important:
- Flutter NEVER talks directly to bakong_service.
- bakong_service NEVER connects to main database Docker.
- Only backend updates main database.


Agent Execution Rules
=====================

1. Sub-Agent Task Delegation
----------------------------

The main agent MUST delegate tasks to sub-agents.

Example: "Create Medication Feature"

- Sub-agent 1: Implement backend (NestJS)
- Sub-agent 2: Implement frontend (Flutter)
- Sub-agent 3: Verify API contract and integration between backend and frontend

The main agent coordinates, but does NOT implement everything alone.


2. Frontend UI Validation Rule
-------------------------------

When implementing or modifying Flutter UI:

- MUST use sub-agent with MCP server
- MUST check Figma design before implementing
- UI must match Figma structure, spacing, naming, and components


3. Todo List Requirement
-------------------------

Before implementing any feature:

- MUST create a detailed step-by-step Todo list
- Todo list must separate:
  - Backend tasks
  - Frontend tasks
  - Integration tasks
  - Testing tasks

No direct implementation without structured Todo plan.


4. Sensitive Value Change Rule
-------------------------------

When changing any sensitive value:

Examples:
- .env variables
- Database schema
- API route paths
- DTO fields
- Encryption keys
- Redis keys
- Payment status enums

The agent MUST:

- Identify all related fields affected
- Update backend logic
- Update frontend API calls if needed
- Update validation DTOs
- Update database schema if required
- Update documentation
- Restart required services (if environment/database related)

No partial update is allowed.


5. Backend Responsibility Rule
------------------------------

- Only backend (NestJS) can modify PostgreSQL.
- bakong_service must NOT modify main database.
- Payment confirmation must always be verified by backend before updating status.


6. Separation of Concerns Rule
------------------------------

- Flutter → UI only
- Backend → Business logic + Database
- bakong_service → Payment gateway communication only
- Docker → Only PostgreSQL and Redis


Expected Agent Behavior
=======================

- Always think in system architecture, not isolated features.
- Never break separation of concerns.
- Always validate backend ↔ frontend contract.
- Always validate encryption and payment flow consistency.
- Always work with structured delegation and clear task boundaries.

End of Rules
============
