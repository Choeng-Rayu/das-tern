---
applyTo: '**'
---

# AI AGENT RULES – DASTERN ARCHITECTURE & WORKFLOW

## Architecture

### Services

1. **Backend (NestJS)**
- Main business logic
- Handles authentication, medication, prescription, and payment
- Communicates with **Bakong Service**, **OCR Service**, and **AI LLM Service**
- Connects to **PostgreSQL and Redis (Docker)**

2. **Bakong Service (Separate VPS)**
- Handles Bakong payment integration
- Generates QR code and receives payment notification
- Sends payment confirmation to backend
- Stores minimal payment data
- **Does NOT connect to main database**

3. **OCR Service**
- Extracts text from prescription images
- Returns OCR result to backend
- **No direct communication with frontend**

4. **AI LLM Service**
- Improves OCR results
- Receives OCR output from backend
- Returns refined prescription data

5. **Frontend – das_tern_mcp (Flutter)**
- Mobile app
- Communicates **ONLY with backend**
- Must support **English and Khmer**
- Use localization files in  
`/home/rayu/das-tern/das_tern_mcp/lib/l10n`

Flutter rules:
- Always run `flutter analyze`
- Must have **0 issues before testing**
- Widgets must be **reusable and scalable**

6. **Database**
- PostgreSQL (Docker)
- Redis (Docker)
- Docker is used **ONLY for database services**

---

# System Flow

## Payment Flow

1. Flutter → Backend (payment request)
2. Backend → Bakong Service (encrypted payload)
3. Bakong Service → Bakong API (generate QR)
4. Bakong Service → Backend (QR response)
5. Backend → Flutter (show QR)
6. User pays
7. Bakong → Bakong Service (payment notification)
8. Bakong Service → Backend (payment confirmation)
9. Backend → PostgreSQL (update status)
10. Backend → Flutter (payment success)

Rules:
- Flutter **never talks to Bakong Service**
- Only backend updates database

---

## OCR + AI Flow

1. Flutter scans prescription
2. Flutter uploads image → Backend
3. Backend → OCR Service
4. OCR Service → Backend (OCR result)
5. Backend → AI LLM Service
6. AI returns improved prescription

### AI Fallback Rule

If AI responds:
- Backend returns **AI improved result** to frontend

If AI fails:
- Backend returns **OCR result** to frontend

System **must never block user** if AI fails.

Frontend must always receive:
- AI result **OR**
- OCR result

---

# Agent Execution Rules

## Main Agent Responsibility

The **Main Agent must NOT implement features directly.**

The Main Agent must:
1. Create a **Todo task list**
2. Break features into **small atomic tasks**
3. Assign tasks to **Sub-Agents**

---

## Sub-Agent Rules

Sub-agents handle **small single tasks only**.

Bad example:
- Implement prescription feature

Good examples:

Backend sub-agent tasks:
- Create Prescription entity
- Create DTO
- Implement API endpoint
- Add OCR service integration
- Add AI service client

Frontend sub-agent tasks:
- Create ScanPrescription screen
- Implement image upload
- Display OCR result
- Display AI improved result

Integration sub-agent tasks:
- Verify API response structure
- Test OCR → AI fallback
- Verify frontend API connection

Rule:
- **1 sub-agent = 1 responsibility**

---

## UI Implementation Rule

When implementing Flutter UI:

Main agent must assign a **UI sub-agent** to:
- Check Figma using MCP server
- Implement UI based on design
- Ensure layout and spacing match design

---

## Code Quality Rule (Flutter)

Before testing:

```bash
flutter analyze