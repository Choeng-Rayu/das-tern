# Overall Architecture Overview

## Logical Architecture

```mermaid
flowchart LR
    U[Users\nPatient Doctor Family] --> APP[Mobile App]
    APP --> BE[Main Backend\nNestJS]

    BE --> RX[Prescription and reminder management]
    BE --> CONN[Doctor and family connection management]
    BE --> HEALTH[Health tracking and notifications]
    BE --> DB[(Main Database)]

    BE --> OCR[OCR Service\nPython FastAPI]
    OCR --> AI[AI LLM Service\nPython FastAPI]
    AI --> OLLAMA[Ollama LLM\nhttp://localhost:11434]
    AI --> BE

    BE --> PAY[Bakong Payment Service\nNestJS]
    PAY --> PAYDB[(Bakong DB)]
    PAY --> BAKONG[Bakong Network]
```

## Physical Architecture

```mermaid
flowchart TB
    USER[Mobile App Users] --> INTERNET[Internet]
    INTERNET --> VPS[VPS Server]

    subgraph VPS["VPS Server (Docker & Nginx)"]
        NGINX[Nginx Reverse Proxy<br/>Port 80, 443]

        subgraph SERVICES["Docker Containers"]
            BACKEND[Backend Container<br/>NestJS<br/>Port 3001]
            OCR[OCR Container<br/>Python FastAPI<br/>Port 8000]
            AI[AI LLM Container<br/>Python FastAPI<br/>Port 8001]
            OLLAMA[Ollama Container<br/>LLM Server<br/>Port 11434]
            BAKONG[Bakong Payment<br/>NestJS<br/>Port 3002]
            POSTGRES[(PostgreSQL<br/>Port 5432)]
            REDIS[(Redis<br/>Port 6379)]
            RABBIT[(RabbitMQ<br/>Port 5672)]
            MINIO[(MinIO Storage<br/>Port 9000)]
            PAYDB[(Bakong DB<br/>PostgreSQL)]
        end
    end

    NGINX --> BACKEND
    NGINX --> AI
    NGINX --> OCR
    NGINX --> BAKONG
    
    BACKEND --> OCR
    BACKEND --> AI
    BACKEND --> BAKONG
    BACKEND --> POSTGRES
    BACKEND --> REDIS
    BACKEND --> RABBIT
    BACKEND --> MINIO
    
    AI --> OLLAMA
    OLLAMA --> OLLAMA_MODEL["Ollama Models<br/>llama3.2:3b<br/>etc."]
    
    BAKONG --> PAYDB
    BAKONG --> BAKONG_NET[Bakong Network<br/>External]
```

## Flow Details

### Prescription Scanning Flow
1. User uploads prescription image via Mobile App
2. Nginx routes request to Backend
3. Backend sends image to OCR Service
4. OCR Service reads the image and extracts text
5. Backend sends OCR result to AI LLM Service
6. AI LLM Service calls Ollama (local LLM) to improve data quality
7. Backend saves the final prescription with enhanced data

### Payment Flow
1. User selects premium plan in Mobile App
2. Nginx routes to Backend
3. Backend calls Bakong Payment Service
4. Bakong Payment Service generates KHQR QR code
5. User scans QR and pays via Bakong
6. Bakong Payment Service checks payment status
7. When confirmed, subscription is updated in main database

## Simple explanation

- Users access via mobile app through Nginx.
- Nginx routes requests to the appropriate backend service.
- Backend (NestJS) is the main control center.
- OCR Service reads prescription images (Python).
- AI LLM Service improves OCR results using Ollama local language model.
- Ollama runs a lightweight 3B model (llama3.2:3b) for fast, local AI processing.
- Bakong Payment handles subscription upgrades.
- All services are containerized with Docker on the VPS.

## Main idea

- Logically: Backend coordinates, OCR reads images, AI improves quality, Bakong handles payments.
- Physically: Single VPS with Docker containers, Nginx routing, and Ollama for local AI.
- Ollama is self-hosted (not external), giving better privacy, faster inference, and no API costs.
