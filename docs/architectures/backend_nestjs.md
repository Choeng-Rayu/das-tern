# Backend NestJS

```mermaid
flowchart LR
    APP[Das Tern App] --> BE[Backend NestJS]
    BE --> AUTH[Login and permissions]
    BE --> RX[Prescriptions and reminders]
    BE --> REL[Doctor and family connections]
    BE --> DB[(Main Database)]
    BE --> OCR[OCR Service]
    BE --> AI[AI LLM Service]
    BE --> PAY[Bakong Payment Service]
```

## Simple explanation

- This is the main control center of the platform.
- It handles users, prescriptions, reminders, sharing, and health records.
- It also connects to OCR, AI, and payment services when needed.

## Main idea

- The app talks to one main backend.
- The backend enforces the rules and stores the data.
- Users do not need to connect to the specialist services directly.
