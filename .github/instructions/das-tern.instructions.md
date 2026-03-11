---
applyTo: '**'
---

# AI AGENT RULES – DASTERN ARCHITECTURE & WORKFLOW


# Architecture Overview

## System Components

### 1. backend (NestJS)
- Main business logic
- Handles authentication, medication, users, prescription processing, and payment
- Communicates with Bakong Service
- Communicates with OCR service and AI LLM service
- Connects to PostgreSQL and Redis (via Docker)

### 2. bakong_service (Separate VPS)
- Handles Bakong payment integration
- Receives encrypted payload from backend
- Generates QR code via Bakong API
- Receives payment notification from Bakong
- Sends payment success callback to main backend
- Does **NOT** connect to the main PostgreSQL/Redis Docker
- Stores only minimal payment-related data

### 3. OCR Service
- Responsible for scanning and extracting text from prescription images
- Receives image from backend
- Processes OCR extraction
- Returns structured OCR result to backend
- Does **NOT** directly communicate with the frontend

### 4. AI LLM Service
- Responsible for improving or interpreting OCR results
- Receives OCR output from backend
- Analyzes medication names, dosage, and prescription structure
- Returns refined or structured prescription data
- If the AI service fails or does not respond, backend must fallback to OCR result

### 5. frontend: das_tern_mcp (Flutter)
- Mobile application
- Communicates **only with backend**
- NEVER communicates directly with OCR, AI LLM, or Bakong services
- Must support **English and Khmer**

Localization rules:
- Check existing localization files in  
`/home/rayu/das-tern/das_tern_mcp/lib/l10n`
- Follow the same pattern when adding new strings

Flutter quality rules:
- Always run `flutter analyze`
- Fix ALL issues until **ZERO issues**
- Only test when analysis is clean

Widget rules:
- Widgets must be scalable and reusable
- Build base widgets with configurable parameters
- Specialized widgets must extend or compose base widgets
- Always integrate with theme and localization

### 6. Database
- PostgreSQL (Docker only)
- Redis (Docker only)
- Docker is used **ONLY** for PostgreSQL and Redis


# System Flow

## Payment Flow

1. Flutter app sends payment request to backend (NestJS)
2. Backend encrypts payload and sends request to `bakong_service`
3. bakong_service calls Bakong API and generates QR code
4. bakong_service returns QR code to backend
5. Backend sends QR code to Flutter
6. User pays via Bakong
7. Bakong sends payment notification to `bakong_service`
8. bakong_service validates payment
9. bakong_service sends payment confirmation to backend
10. Backend updates payment status in PostgreSQL
11. Backend confirms payment success to frontend

Important rules:
- Flutter NEVER talks to bakong_service
- bakong_service NEVER connects to main database
- Only backend updates database


# Prescription OCR & AI Flow

1. User scans prescription in Flutter
2. Flutter uploads image to backend
3. Backend sends image to **OCR Service**
4. OCR Service extracts prescription text
5. OCR result is returned to backend
6. Backend sends OCR result to **AI LLM Service**
7. AI analyzes and improves the prescription structure

### AI Response Handling Rule

If AI responds successfully:
- Backend uses **AI improved result**
- Backend sends refined prescription to frontend

If AI fails or does not respond:
- Backend MUST fallback to **original OCR result**
- Backend sends OCR result directly to frontend
- The system must continue working without blocking the user

**AI service failure must NEVER break the prescription flow.**

Frontend must always receive a result:
- AI enhanced result OR
- Raw OCR result


# Agent Execution Rules


# 1. Sub-Agent Task Delegation

## Core Principle
Sub-agents handle **small atomic tasks only**.

Never assign:
- Full feature implementation
- Backend + frontend in the same task
- Large or unclear tasks

## Task Size Rule

Bad tasks:
- Implement prescription feature
- Implement medication system

Good tasks:

Backend tasks
- Create Prescription entity
- Create CreatePrescription DTO
- Implement POST /prescriptions endpoint
- Add OCR integration service
- Add AI service client

Frontend tasks
- Create ScanPrescription screen
- Implement image upload
- Display OCR result
- Display AI improved result

Integration tasks
- Verify OCR response structure
- Verify AI fallback logic
- Verify API response to Flutter

## Delegation Rule

Each sub-agent must have:

- Task type (Backend / Frontend / Integration / Database)
- Clear objective
- Expected output
- Verification step

One sub-agent = one responsibility.


# 2. Frontend UI Validation Rule

When implementing Flutter UI:

- MUST use sub-agent with MCP server
- MUST check Figma design
- UI must match spacing, layout, and components from Figma


# 3. Flutter Code Quality Rule

Before testing:

All issues MUST be fixed until **0 issues remain**.

Testing workflow:

1. Implement feature
2. Run `flutter analyze`
3. Fix issues
4. Confirm 0 issues
5. Run tests
6. Fix issues discovered during testing
7. Run analysis again
8. Confirm 0 issues before completion

Never test with existing analyzer issues.


# 4. Todo List Requirement

Before implementing any feature:

Agent MUST create a detailed Todo list including:

- Backend tasks
- Frontend tasks
- Integration tasks
- Testing tasks

Implementation must follow the Todo plan.


# 5. Sensitive Value Change Rule

Sensitive values include:

- `.env` variables
- Database schema
- API routes
- DTO fields
- Encryption keys
- Redis keys
- Payment status enums

When these change, the agent must update:

- Backend logic
- DTO validation
- Database schema
- Frontend API calls
- Documentation

No partial updates allowed.


# 6. Backend Responsibility Rule

- Only backend (NestJS) modifies PostgreSQL
- bakong_service cannot modify main database
- OCR and AI services also cannot modify the main database


# 7. Separation of Concerns

System responsibility separation:

Flutter → UI only  
Backend → Business logic + database  
OCR service → text extraction only  
AI LLM service → prescription interpretation only  
bakong_service → payment gateway communication  
Docker → PostgreSQL and Redis only


# Expected Agent Behavior

The agent must:

- Think in system architecture, not isolated code
- Maintain strict separation of services
- Validate backend ↔ frontend API contracts
- Ensure payment flow reliability
- Ensure OCR → AI fallback reliability
- Always delegate tasks into small sub-agent tasks
- Maintain scalable Flutter widget design