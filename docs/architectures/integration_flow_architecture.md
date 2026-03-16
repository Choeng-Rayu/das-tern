# Integration Architecture - OCR + AI LLM + Backend

## Complete Prescription Processing Flow

```mermaid
graph TD
    USER["👤 User<br/>Mobile App<br/>Flutter"]
    
    subgraph "Frontend Layer"
        UPLOAD["Upload Prescription Image"]
    end
    
    subgraph "Backend - NestJS (Port 3001)"
        AUTH["Authentication Check"]
        API_GATEWAY["API Gateway"]
        CONTROLLER["Prescription Controller"]
        SERVICE["Prescription Service"]
        QUEUE["Task Queue<br/>RabbitMQ"]
        DB["Database<br/>PostgreSQL"]
    end
    
    subgraph "OCR Service (Port 8000)"
        OCR_API["API Routes"]
        PREPROCESS["Preprocessor"]
        LAYOUT["Layout Analyzer"]
        OCR_ENGINE["Kiri-OCR Engine"]
        PARSE["Text Parser"]
        OCR_OUT["OCR Output"]
    end
    
    subgraph "AI LLM Service (Port 8001)"
        AI_API["API Routes"]
        ENHANCE["PrescriptionEnhancer"]
        LLM_CLIENT["LLMClient"]
        EXTRACTOR["FinetunedExtractor"]
        SAFETY["SafetyModule"]
        AI_OUT["Enhanced Output"]
    end
    
    subgraph "Ollama (Port 11434)"
        OLLAMA["Ollama Server"]
        MODEL["llama3.2:3b Model"]
    end
    
    USER -->|1. Upload| UPLOAD
    UPLOAD -->|2. POST /prescriptions| API_GATEWAY
    API_GATEWAY --> AUTH
    AUTH -->|3. Authenticated| CONTROLLER
    CONTROLLER -->|4. Save + Queue| SERVICE
    SERVICE -->|5. Save metadata| DB
    SERVICE -->|6. Publish task| QUEUE
    
    QUEUE -->|7. Process| OCR_API
    OCR_API -->|8. Preprocess| PREPROCESS
    PREPROCESS -->|9. Analyze layout| LAYOUT
    LAYOUT -->|10. Extract text| OCR_ENGINE
    OCR_ENGINE -->|11. Parse data| PARSE
    PARSE -->|12. Return| OCR_OUT
    
    OCR_OUT -->|13. Enhance| AI_API
    AI_API -->|14. Build prompt| ENHANCE
    ENHANCE -->|15. Send to LLM| LLM_CLIENT
    LLM_CLIENT -->|16. Forward| OLLAMA
    OLLAMA -->|17. Inference| MODEL
    MODEL -->|18. Stream tokens| OLLAMA
    OLLAMA -->|19. Return| LLM_CLIENT
    LLM_CLIENT -->|20. Process response| EXTRACTOR
    EXTRACTOR -->|21. Safety check| SAFETY
    SAFETY -->|22. Validate| AI_OUT
    
    AI_OUT -->|23. Update prescription| SERVICE
    SERVICE -->|24. Save enhanced data| DB
    SERVICE -->|25. Notify user| USER
    
    DB -.->|Cache| QUEUE
```

---

## Detailed Service Interaction Matrix

```mermaid
graph LR
    subgraph "Service Boundaries"
        BACKEND["NestJS Backend"]
        OCR["OCR Service"]
        AI["AI LLM Service"]
    end
    
    subgraph "Communication Channels"
        HTTP["HTTP REST API"]
        ASYNC["Async Queue<br/>RabbitMQ"]
    end
    
    BACKEND -->|POST /prescriptions| OCR
    BACKEND -->|POST /enhance| AI
    OCR -->|Results| BACKEND
    AI -->|Results| BACKEND
    
    BACKEND -->|Publish tasks| ASYNC
    ASYNC -->|Consume| OCR
    ASYNC -->|Consume| AI
```

---

## Step-by-Step Processing Pipeline

### Phase 1: User Upload & Validation

```mermaid
sequenceDiagram
    participant User as User/Mobile
    participant Backend as Backend<br/>:3001
    participant Auth as Auth Module
    participant DB as Database
    
    User->>Backend: POST /prescriptions<br/>(image_file, userId)
    Backend->>Auth: Verify token
    Auth-->>Backend: Valid ✓
    Backend->>DB: Save prescription metadata
    DB-->>Backend: prescription_id
    Backend-->>User: 200 OK<br/>{prescription_id, status: processing}
```

### Phase 2: OCR Processing

```mermaid
sequenceDiagram
    participant Queue as RabbitMQ Queue
    participant OCR as OCR Service<br/>:8000
    participant Preproc as Preprocessor
    participant Engine as Kiri-OCR
    participant Parser as Parser
    participant Backend as Backend
    
    Queue->>OCR: Task: extract image
    OCR->>Preproc: Preprocess image
    Preproc->>Preproc: Quality checks + enhance
    Preproc-->>OCR: Enhanced image
    
    OCR->>Engine: Extract text
    Engine->>Engine: Load model + inference
    Engine-->>OCR: OCR lines + confidence
    
    OCR->>Parser: Parse lines
    Parser->>Parser: Extract medications<br/>Extract patient info
    Parser-->>OCR: Structured data
    
    OCR->>Backend: POST /prescriptions/{id}/ocr-results
    Backend->>DB: Update with OCR data
    Backend->>Queue: Publish: AI Enhancement task
```

### Phase 3: AI Enhancement

```mermaid
sequenceDiagram
    participant Queue as RabbitMQ Queue
    participant AI as AI LLM<br/>:8001
    participant Enhance as Enhancer
    participant LLM as LLMClient
    participant Ollama as Ollama<br/>:11434
    participant Safety as SafetyModule
    participant Backend as Backend
    
    Queue->>AI: Task: enhance OCR results
    AI->>Enhance: enhance_prescription(ocr_data)
    
    Enhance->>Enhance: Build few-shot prompt<br/>+ OCR data
    Enhance->>LLM: generate(prompt, system_prompt)
    
    LLM->>Ollama: POST /api/generate
    Ollama->>Ollama: llama3.2:3b inference
    Ollama-->>LLM: Token stream (streaming)
    
    LLM->>LLM: Collect + parse tokens
    LLM-->>Enhance: Enhanced text
    
    Enhance->>Safety: check_safety(data)
    Safety->>Safety: Medical advice detection<br/>Language detection
    Safety-->>Enhance: {is_safe, language}
    
    Enhance->>Enhance: Validate structure
    Enhance-->>AI: Enhanced results
    
    AI->>Backend: POST /prescriptions/{id}/ai-results
    Backend->>DB: Update with enhanced data
    Backend-->>User: Notify: Processing complete
```

### Phase 4: Data Storage & Retrieval

```mermaid
graph TB
    AI_RESULT["AI Enhanced Results<br/>Medications, diagnosis, prescriber"]
    
    STORE["Store in Database"]
    
    subgraph "Database Schema"
        PRESCRIPTION["Prescription<br/>id, user_id, date, status"]
        OCR_DATA["OCRData<br/>raw_text, confidence, errors"]
        ENHANCED_DATA["EnhancedData<br/>medications, diagnosis, extracted"]
        EXTRACTION["Extraction<br/>name, dose, frequency, duration"]
    end
    
    subgraph "Caching"
        REDIS["Redis Cache<br/>Recent prescriptions<br/>User history"]
    end
    
    AI_RESULT --> STORE
    STORE --> PRESCRIPTION
    STORE --> OCR_DATA
    STORE --> ENHANCED_DATA
    STORE --> EXTRACTION
    
    PRESCRIPTION -.-> REDIS
    ENHANCED_DATA -.-> REDIS
```

---

## Error Handling & Fallback Strategies

```mermaid
graph TD
    PROCESS["Start Processing"]
    
    subgraph "Stage 1: OCR"
        OCR_CHECK["OCR Processing"]
        OCR_FAIL["OCR Failed<br/>Low quality image?"]
        OCR_FALLBACK["Fallback:<br/>Return raw OCR<br/>Skip enhancement"]
    end
    
    subgraph "Stage 2: AI Enhancement"
        AI_CHECK["AI Enhancement"]
        OLLAMA_FAIL["Ollama unavailable?"]
        AI_FALLBACK["Fallback:<br/>Use OCR results<br/>Skip enhancement"]
    end
    
    subgraph "Final Step"
        SAVE_DB["Save Results to DB"]
        NOTIFY_USER["Notify User"]
    end
    
    PROCESS --> OCR_CHECK
    OCR_CHECK -->|Success| AI_CHECK
    OCR_CHECK -->|Fail| OCR_FALLBACK
    
    AI_CHECK -->|Success| SAVE_DB
    AI_CHECK -->|Fail| OLLAMA_FAIL
    OLLAMA_FAIL --> AI_FALLBACK
    
    OCR_FALLBACK --> SAVE_DB
    AI_FALLBACK --> SAVE_DB
    SAVE_DB --> NOTIFY_USER
    
    style OCR_FAIL fill:#fff9c4
    style OLLAMA_FAIL fill:#fff9c4
    style OCR_FALLBACK fill:#fff9c4
    style AI_FALLBACK fill:#fff9c4
```

---

## Performance Metrics & Timing

```mermaid
graph LR
    START["Start: 0ms"]
    
    UPLOAD["Upload<br/>100-500ms"]
    
    OCR_TIME["OCR Processing<br/>2-5 seconds"]
    
    AI_TIME["AI Enhancement<br/>1-2 seconds"]
    
    SAVE["Save to DB<br/>100-300ms"]
    
    DONE["Complete<br/>3-8 seconds total"]
    
    START -->|User uploads| UPLOAD
    UPLOAD -->|Backend queues| OCR_TIME
    OCR_TIME -->|Results processed| AI_TIME
    AI_TIME -->|Data formatted| SAVE
    SAVE -->|Notify user| DONE
    
    style DONE fill:#c8e6c9
```

**Latency Breakdown:**
- **Upload:** 100-500ms (network dependent)
- **OCR Processing:** 2-5 seconds (image quality dependent)
  - Preprocessing: 500-800ms
  - Layout analysis: 300-500ms
  - OCR inference: 800-2000ms
  - Text parsing: 200-400ms
- **AI Enhancement:** 1-2 seconds (Ollama inference)
  - Prompt building: 50-100ms
  - Ollama inference: 400-800ms
  - Response parsing: 100-200ms
  - Safety check: 50-100ms
- **Database save:** 100-300ms
- **Total:** 3-8 seconds

---

## Database Schema

```mermaid
graph TB
    subgraph "Schema"
        USER["users<br/>id (PK), email, password"]
        
        PRESCRIPTION["prescriptions<br/>id (PK), user_id (FK), created_at,<br/>image_path, status"]
        
        OCR_RESULT["ocr_results<br/>id (PK), prescription_id (FK),<br/>raw_text, confidence, regions"]
        
        ENHANCED_RESULT["enhanced_results<br/>id (PK), prescription_id (FK),<br/>enhanced_text, language, is_safe"]
        
        MEDICATIONS["medications<br/>id (PK), prescription_id (FK),<br/>name, dose, frequency, duration,<br/>confidence"]
        
        DIAGNOSIS["diagnosis<br/>id (PK), prescription_id (FK),<br/>condition, icd_code"]
        
        PRESCRIBER["prescriber_info<br/>id (PK), prescription_id (FK),<br/>doctor_name, speciality, clinic"]
    end
    
    USER -->|1:N| PRESCRIPTION
    PRESCRIPTION -->|1:1| OCR_RESULT
    PRESCRIPTION -->|1:1| ENHANCED_RESULT
    PRESCRIPTION -->|1:N| MEDICATIONS
    PRESCRIPTION -->|1:N| DIAGNOSIS
    PRESCRIPTION -->|1:N| PRESCRIBER
```

---

## Deployment Architecture

```mermaid
graph TB
    subgraph "VPS Server<br/>Single Machine"
        subgraph "Docker Network"
            NGINX["Nginx Reverse Proxy<br/>:80, :443"]
            
            BACKEND["Backend Container<br/>NestJS:3001"]
            OCR["OCR Container<br/>FastAPI:8000"]
            AI["AI LLM Container<br/>FastAPI:8001"]
            OLLAMA["Ollama Container<br/>:11434"]
            
            subgraph "Infrastructure"
                DB["PostgreSQL:5432"]
                REDIS["Redis:6379"]
                RABBIT["RabbitMQ:5672"]
                MINIO["MinIO:9000<br/>File storage"]
            end
        end
    end
    
    INTERNET["Internet<br/>HTTPS"]
    
    INTERNET -->|HTTPS| NGINX
    NGINX -->|Route /api| BACKEND
    NGINX -->|Route /ocr| OCR
    NGINX -->|Route /ai| AI
    
    BACKEND -->|HTTP| OCR
    BACKEND -->|HTTP| AI
    OCR -->|HTTP| OLLAMA
    AI -->|HTTP| OLLAMA
    
    BACKEND -->|TCP| DB
    BACKEND -->|TCP| REDIS
    BACKEND -->|TCP| RABBIT
    OCR -->|S3 API| MINIO
    
    RABBIT -->|Async| OCR
    RABBIT -->|Async| AI
```

---

## Scaling Considerations

```mermaid
graph TB
    subgraph "Current: Single Instance"
        SINGLE["Single VPS<br/>All services co-located"]
    end
    
    subgraph "Future: Horizontal Scaling"
        LB["Load Balancer"]
        
        BACKEND_POOL["Backend Pool<br/>3-5 instances"]
        OCR_POOL["OCR Pool<br/>2-3 instances"]
        AI_POOL["AI Pool<br/>1-2 instances<br/>(GPU limited)"]
        
        SHARED["Shared Infrastructure<br/>DB, Redis, RabbitMQ"]
    end
    
    SINGLE -.->|Scale| LB
    LB --> BACKEND_POOL
    LB --> OCR_POOL
    LB --> AI_POOL
    
    BACKEND_POOL --> SHARED
    OCR_POOL --> SHARED
    AI_POOL --> SHARED
```

**Scaling Strategy:**
- **Backend (NestJS):** CPU-bound, can scale horizontally
- **OCR Service:** GPU-bound (optional), 2-3 instances on separate GPU nodes
- **AI LLM (Ollama):** GPU-memory-bound, limited by VRAM
- **Shared Services:** Use managed services (Managed PostgreSQL, Redis, RabbitMQ)

---

## Request/Response Cycle - Complete Flow

```mermaid
sequenceDiagram
    participant Client as Mobile Client
    participant Gateway as API Gateway
    participant Backend as Backend Service
    participant Queue as Message Queue
    participant OCR as OCR Service
    participant AI as AI Service
    participant Ollama as Ollama
    participant Database as Database
    
    
    rect rgb(200, 220, 255)
    Note over Client,Gateway: Phase 1: Upload & Validation
    Client->>Gateway: POST /prescriptions (image)
    Gateway->>Backend: Authenticate + validate
    Backend->>Database: Store metadata (status: processing)
    Backend-->>Client: 200 OK {id, status}
    end
    
    rect rgb(200, 255, 200)
    Note over Queue,OCR: Phase 2: OCR Processing
    Backend->>Queue: Publish OCR task
    Queue-->>OCR: Task available
    OCR->>OCR: Preprocess image
    OCR->>OCR: Detect regions
    OCR->>OCR: Extract text
    OCR->>Backend: POST /prescriptions/{id}/ocr-results
    Backend->>Database: Update OCR data
    end
    
    rect rgb(255, 220, 200)
    Note over Queue,Ollama: Phase 3: AI Enhancement
    Backend->>Queue: Publish AI enhancement task
    Queue-->>AI: Task available
    AI->>AI: Build few-shot prompt
    AI->>Ollama: POST /api/generate
    Ollama->>Ollama: Inference (llama3.2:3b)
    Ollama-->>AI: Token stream
    AI->>AI: Parse + validate response
    AI->>Backend: POST /prescriptions/{id}/ai-results
    Backend->>Database: Update enhanced data
    Backend-->>Client: Notification: Complete
    end
```

---

## Summary

The complete prescription processing pipeline:

1. **User Upload** → Flutter mobile app
2. **Backend Validation** → NestJS API Gateway
3. **Async Processing** → RabbitMQ queue
4. **OCR Pipeline** → Image preprocessing → Region detection → Text extraction
5. **AI Enhancement** → Few-shot prompting → Ollama inference → Data validation
6. **Data Storage** → PostgreSQL with structured schema
7. **User Notification** → Real-time updates to mobile client

**Total Processing Time:** 3-8 seconds end-to-end
**Bottleneck:** OCR inference (2-5 seconds) + Ollama inference (400-800ms)
**Optimization:** Can parallelize preprocessing and inference with batching

