# AI LLM Service - Detailed Architecture

## Overview
The AI LLM service is a Python FastAPI-based microservice that enhances and refines OCR results using Large Language Models. It integrates with Ollama for local LLM inference and provides fine-tuned extraction endpoints for medical data with safety checks.

---

## Component Architecture

```mermaid
graph TB
    subgraph "AI LLM Service - Internal Architecture"
        API["FastAPI Routes<br/>/enhance /extract /prescribe /remind"]
        
        subgraph "LLM Integration Layer"
            OLLAMA_CLIENT["OllamaClient<br/>HTTP client to Ollama"]
            LLM_CLIENT["LLMClient<br/>Unified LLM provider interface"]
        end
        
        subgraph "Core Processing"
            ENHANCER["PrescriptionEnhancer<br/>Few-shot learning for enhancement"]
            EXTRACTOR["FinetunedMedicalExtractor<br/>Fine-tuned data extraction"]
            REMINDER["ReminderEngine<br/>Generate reminders from data"]
        end
        
        subgraph "Safety & Validation"
            SAFETY["SafetyModule<br/>Detect medical advice requests"]
            LANG_DETECT["LanguageDetector<br/>Detect language & encoding"]
            VALIDATOR["DataValidator<br/>Validate extracted data"]
        end
        
        subgraph "Models & Config"
            OLLAMA_MODEL["Ollama Model<br/>llama3.2:3b at port 11434"]
            PROMPTS["Prompt Templates<br/>Few-shot learning prompts"]
            CONFIG["Configuration<br/>Timeouts, thresholds"]
        end
    end
    
    INPUT["OCR Results<br/>From OCR Service"]
    OUTPUT["Enhanced Results<br/>JSON response"]
    OLLAMA_SERVER["🟢 Ollama Server<br/>Port 11434"]
    
    INPUT --> API
    API --> LLM_CLIENT
    LLM_CLIENT --> OLLAMA_CLIENT
    OLLAMA_CLIENT --> OLLAMA_SERVER
    
    API --> ENHANCER
    API --> EXTRACTOR
    API --> REMINDER
    
    ENHANCER --> LLM_CLIENT
    EXTRACTOR --> LLM_CLIENT
    
    ENHANCER --> SAFETY
    EXTRACTOR --> SAFETY
    
    SAFETY --> VALIDATOR
    LANG_DETECT --> VALIDATOR
    
    OLLAMA_MODEL -.-> OLLAMA_SERVER
    PROMPTS -.-> ENHANCER
    PROMPTS -.-> EXTRACTOR
    CONFIG -.-> API
```

---

## Ollama Integration Architecture

```mermaid
graph LR
    subgraph "AI LLM Service"
        CLIENT["OllamaClient<br/>HTTP wrapper"]
    end
    
    subgraph "Ollama Server<br/>Port 11434"
        OLLAMA["Ollama Server"]
        MODEL["llama3.2:3b Model<br/>3B parameters"]
        VRAM["VRAM<br/>~6GB"]
    end
    
    subgraph "Request/Response Cycle"
        REQ["POST /api/generate<br/>{model, prompt, stream}"]
        RESP["Response Stream<br/>Token by token"]
    end
    
    CLIENT -->|1. Connect| OLLAMA
    CLIENT -->|2. Send prompt| REQ
    REQ -->|3. Generate tokens| MODEL
    MODEL -->|4. Stream response| RESP
    RESP -->|5. Collect tokens| CLIENT
    
    MODEL -.->|Uses| VRAM
    OLLAMA -.->|Manages| MODEL
```

**Key Details:**
- **Ollama URL:** `http://localhost:11434`
- **Model:** `llama3.2:3b` (3 billion parameters)
- **Model Size:** ~2GB on disk, ~6GB in VRAM
- **Latency:** 100-500ms per request (depending on prompt length)
- **Features:** Streaming response, JSON mode, system prompts

---

## OllamaClient Details

```python
# /ai-llm-service/app/core/ollama_client.py

class OllamaClient:
    """HTTP client for communicating with Ollama server"""
    
    def __init__(self, 
                 base_url: str = "http://localhost:11434",
                 model: str = "llama3.2:3b",
                 timeout: int = 60):
        self.base_url = base_url
        self.model = model
        self.timeout = timeout
    
    async def generate(self, 
                      prompt: str,
                      system_prompt: str = None,
                      temperature: float = 0.3,
                      top_p: float = 0.9) -> str:
        """Send request to Ollama and get response"""
        # POST to http://localhost:11434/api/generate
        # Returns: Full text response
    
    async def generate_stream(self,
                             prompt: str) -> AsyncGenerator[str, None]:
        """Stream tokens from Ollama"""
        # Yields tokens as they arrive
```

---

## LLMClient - Unified Provider Interface

```mermaid
graph TB
    LLM_CLIENT["LLMClient<br/>Unified interface"]
    
    subgraph "Provider Detection"
        DETECT["Detect Provider<br/>via PROVIDER env var"]
    end
    
    subgraph "Providers"
        OLLAMA["OllamaProvider<br/>Local Ollama"]
        OPENROUTER["OpenRouterProvider<br/>Remote API"]
    end
    
    subgraph "Methods"
        GENERATE["generate(prompt)"]
        CHAT["chat(messages)"]
        EXTRACT_JSON["extract_json(prompt)"]
    end
    
    LLM_CLIENT --> DETECT
    DETECT -->|PROVIDER=ollama| OLLAMA
    DETECT -->|PROVIDER=openrouter| OPENROUTER
    
    LLM_CLIENT --> GENERATE
    LLM_CLIENT --> CHAT
    LLM_CLIENT --> EXTRACT_JSON
    
    GENERATE --> OLLAMA
    GENERATE --> OPENROUTER
```

**Configuration:**
```env
LLM_PROVIDER=ollama  # or 'openrouter'
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2:3b
OPENROUTER_API_KEY=sk-...
OPENROUTER_MODEL=llama2-7b  # fallback
```

---

## Prescription Enhancement Pipeline

```mermaid
sequenceDiagram
    participant Client as Client/Backend
    participant API as FastAPI Routes
    participant Enhancer as PrescriptionEnhancer
    participant LLM as LLMClient
    participant Safety as SafetyModule
    participant Validator as DataValidator
    
    Client->>API: POST /enhance {ocr_results}
    API->>Enhancer: enhance_prescription(ocr_results)
    
    Enhancer->>Enhancer: Create few-shot prompt
    Enhancer->>Enhancer: Add OCR data to prompt
    
    Enhancer->>LLM: generate(prompt, system_prompt)
    LLM->>LLM: Send to Ollama (port 11434)
    LLM-->>Enhancer: Enhanced text (streaming)
    
    Enhancer->>Enhancer: Parse LLM response
    Enhancer->>Enhancer: Merge with original OCR
    
    Enhancer->>Safety: check_safety(enhanced_data)
    Safety->>Safety: Detect medical advice requests
    Safety->>Safety: Detect language & encoding
    Safety-->>Enhancer: {is_safe, detected_language}
    
    Enhancer->>Validator: validate(enhanced_data)
    Validator->>Validator: Verify data structure
    Validator->>Validator: Check confidence scores
    Validator-->>Enhancer: {valid, errors}
    
    Enhancer-->>API: enhanced_results
    API-->>Client: {medications, confidence, warnings, ...}
```

---

## Component Details

### 1. **FastAPI Routes** (`/ai-llm-service/app/api/extraction_routes.py`)

| Endpoint | Method | Input | Output |
|----------|--------|-------|--------|
| `/enhance` | POST | OCR results | Enhanced results |
| `/extract/complete` | POST | OCR results | Full structured extraction |
| `/extract/medications` | POST | OCR results | Medication list only |
| `/prescribe` | POST | Symptoms + context | Recommendations |
| `/remind` | POST | Prescription data | Reminder text |
| `/health` | GET | None | {status: "ok"} |

**Example Request:**
```json
POST /enhance
{
  "ocr_results": {
    "medications": ["Aspirin 500mg"],
    "patient_info": {"name": "John Doe"},
    "metadata": {"date": "2024-03-16"}
  }
}
```

**Example Response:**
```json
{
  "status": "success",
  "enhanced_medications": [
    {
      "name": "Aspirin",
      "dose": "500mg",
      "frequency": "3 times daily",
      "duration": "14 days",
      "confidence": 0.98
    }
  ],
  "detected_language": "en",
  "is_safe": true,
  "warnings": []
}
```

---

### 2. **PrescriptionEnhancer** (`/ai-llm-service/app/features/prescription/enhancer.py`)

```mermaid
graph TB
    INPUT["OCR Results"]
    
    PROMPT_BUILD["1. Build Few-Shot Prompt"]
    
    EXAMPLES["Few-Shot Examples:<br/>Input: 'Aspirin 500'<br/>Output: 'Aspirin 500mg, 3x daily'"]
    
    INJECT["2. Inject OCR Data"]
    
    LLM_REQ["3. Send to LLM"]
    
    PARSE["4. Parse Response"]
    
    MERGE["5. Merge with OCR"]
    
    OUTPUT["Enhanced Results"]
    
    INPUT --> PROMPT_BUILD
    EXAMPLES --> PROMPT_BUILD
    PROMPT_BUILD --> INJECT
    INJECT --> LLM_REQ
    LLM_REQ --> PARSE
    PARSE --> MERGE
    MERGE --> OUTPUT
```

**Few-Shot Learning Template:**
```python
system_prompt = """You are a medical prescription analyzer. 
Extract and enhance medication information from OCR results."""

few_shot_examples = [
    {
        "input": "Aspirin 500 TID",
        "output": {
            "name": "Aspirin",
            "dose": "500mg",
            "frequency": "3 times daily",
            "duration": "Not specified"
        }
    },
    {
        "input": "Amoxicillin 250mg daily x7days",
        "output": {
            "name": "Amoxicillin",
            "dose": "250mg",
            "frequency": "Once daily",
            "duration": "7 days"
        }
    }
]

prompt = f"""Given OCR results: {ocr_results}

Examples:
{json.dumps(few_shot_examples, indent=2)}

Extract and enhance the medications:"""
```

**Methods:**
```python
def enhance_prescription(ocr_results: Dict) -> Dict
    # Build prompt with few-shot examples
    # Send to LLM
    # Parse structured response
    # Return enhanced data

def build_few_shot_prompt(ocr_data: Dict) -> str
    # Create prompt with examples

def parse_llm_response(response: str) -> Dict
    # Extract JSON from response
    # Validate structure
```

---

### 3. **FinetunedMedicalExtractor** (`/ai-llm-service/app/features/extraction/extractor.py`)

```mermaid
graph TB
    subgraph "Extraction Stages"
        STAGE1["Stage 1: Medication Extraction<br/>name, dose, frequency, duration"]
        STAGE2["Stage 2: Diagnosis Extraction<br/>condition, ICD code"]
        STAGE3["Stage 3: Prescriber Extraction<br/>doctor, clinic, speciality"]
        STAGE4["Stage 4: Metadata Extraction<br/>date, next visit, notes"]
    end
    
    INPUT["Input<br/>OCR + Enhanced data"]
    LLM["LLM Inference<br/>via OllamaClient"]
    SAFETY["Safety Check"]
    VALIDATE["Data Validation"]
    OUTPUT["Structured Output"]
    
    INPUT --> STAGE1
    INPUT --> STAGE2
    INPUT --> STAGE3
    INPUT --> STAGE4
    
    STAGE1 --> LLM
    STAGE2 --> LLM
    STAGE3 --> LLM
    STAGE4 --> LLM
    
    LLM --> SAFETY
    SAFETY --> VALIDATE
    VALIDATE --> OUTPUT
```

**Extraction Template:**
```python
extraction_prompts = {
    "medications": """Extract medications:
    - Name (generic name preferred)
    - Dose (with units)
    - Frequency (e.g., 3x daily, once daily)
    - Duration (e.g., 14 days, as needed)
    - Confidence (0-1)""",
    
    "diagnosis": """Extract diagnosis:
    - Condition name
    - ICD-10 code (if present)
    - Severity""",
    
    "prescriber": """Extract prescriber info:
    - Doctor name
    - Speciality
    - Clinic/Hospital
    - Contact info"""
}
```

---

### 4. **ReminderEngine** (`/ai-llm-service/app/features/prescription/reminder_engine.py`)

```mermaid
graph LR
    DATA["Prescription Data<br/>medications, dates, notes"]
    
    TEMPLATE["Reminder Template<br/>Generate user-friendly text"]
    
    FORMAT["Format for Display<br/>Time, frequency, warnings"]
    
    OUTPUT["Reminder Text<br/>'Take Aspirin 500mg with meals'"]
    
    DATA --> TEMPLATE
    TEMPLATE --> FORMAT
    FORMAT --> OUTPUT
```

**Reminder Generation:**
```python
def generate_reminders(prescription: Dict) -> List[str]:
    """Generate user-friendly reminder messages"""
    
    reminders = []
    for med in prescription['medications']:
        reminder = f"""Take {med['name']} {med['dose']}
        {med['frequency']} for {med['duration']}
        Warnings: {med.get('warnings', 'None')}"""
        reminders.append(reminder)
    
    return reminders
```

---

### 5. **SafetyModule** (`/ai-llm-service/app/core/safety_module.py`)

```mermaid
graph TB
    INPUT["Input Data"]
    
    subgraph "Safety Checks"
        ADVICE["Medical Advice Detection<br/>User asking for diagnosis/treatment?"]
        LANG["Language Detection<br/>Detect language & encoding"]
        INJECTION["Injection Detection<br/>Check for prompt injection"]
        CONTENT["Content Validation<br/>Check for inappropriate content"]
    end
    
    subgraph "Response"
        SAFE["Safe: Process normally"]
        UNSAFE["Unsafe: Flag warning"]
        BLOCK["Dangerous: Block request"]
    end
    
    INPUT --> ADVICE
    INPUT --> LANG
    INPUT --> INJECTION
    INPUT --> CONTENT
    
    ADVICE -->|Detected| UNSAFE
    LANG -->|Valid| SAFE
    INJECTION -->|Detected| BLOCK
    CONTENT -->|Invalid| UNSAFE
    
    SAFE --> OUTPUT["Return results"]
    UNSAFE --> OUTPUT
    BLOCK --> OUTPUT
    
    style SAFE fill:#c8e6c9
    style UNSAFE fill:#fff9c4
    style BLOCK fill:#ffcdd2
```

**Safety Checks:**
```python
class SafetyModule:
    def check_medical_advice_request(text: str) -> bool:
        """Detect if user is asking for medical advice"""
        keywords = ['should i', 'do i have', 'am i', 'can you diagnose']
        return any(kw in text.lower() for kw in keywords)
    
    def detect_language(text: str) -> str:
        """Detect language of input"""
        # Uses langdetect library
        return langdetect.detect(text)
    
    def check_prompt_injection(text: str) -> bool:
        """Detect prompt injection attempts"""
        suspicious = ['system:', 'prompt:', 'ignore', 'override']
        return any(s in text.lower() for s in suspicious)
```

---

### 6. **DataValidator** (`/ai-llm-service/app/core/validator.py`)

```mermaid
graph TB
    DATA["Extracted Data"]
    
    VALIDATE["Validation Steps"]
    
    CHECK1["1. Structure Check<br/>Required fields present?"]
    CHECK2["2. Type Check<br/>Correct data types?"]
    CHECK3["3. Range Check<br/>Values within bounds?"]
    CHECK4["4. Confidence Check<br/>Confidence scores valid?"]
    
    RESULT["Validation Result"]
    
    DATA --> CHECK1
    DATA --> CHECK2
    DATA --> CHECK3
    DATA --> CHECK4
    
    CHECK1 --> RESULT
    CHECK2 --> RESULT
    CHECK3 --> RESULT
    CHECK4 --> RESULT
```

**Validation Schema:**
```python
medication_schema = {
    "name": {"type": "string", "required": True},
    "dose": {"type": "string", "required": True},
    "frequency": {"type": "string", "required": True},
    "duration": {"type": "string", "required": False},
    "confidence": {
        "type": "float",
        "required": True,
        "min": 0.0,
        "max": 1.0
    }
}
```

---

## Request/Response Flow

```mermaid
sequenceDiagram
    participant Backend as NestJS Backend<br/>Port 3001
    participant AI as AI LLM Service<br/>Port 8001
    participant Ollama as Ollama Server<br/>Port 11434
    
    Backend->>AI: POST /enhance (OCR results)
    AI->>AI: Build few-shot prompt
    AI->>Ollama: POST /api/generate (prompt)
    
    Ollama->>Ollama: Run llama3.2:3b inference
    Ollama-->>AI: Token stream (streaming)
    
    AI->>AI: Collect tokens + parse JSON
    AI->>AI: Safety check
    AI->>AI: Validate structure
    AI-->>Backend: Enhanced results + metadata
```

---

## Environment Configuration

**File:** `/ai-llm-service/.env`

```ini
# Ollama Configuration
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2:3b

# LLM Provider
LLM_PROVIDER=ollama  # or 'openrouter'

# OpenRouter (Fallback)
OPENROUTER_API_KEY=sk-...
OPENROUTER_MODEL=llama2-7b

# Service Configuration
SERVICE_PORT=8001
SERVICE_HOST=0.0.0.0
LOG_LEVEL=INFO
DEBUG=false

# Timeouts
OLLAMA_TIMEOUT=60
REQUEST_TIMEOUT=120

# Safety
ENABLE_SAFETY_CHECK=true
ENABLE_LANGUAGE_DETECTION=true
```

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| Average Response Time | 500ms - 2s |
| Model Latency (Ollama) | 200-800ms |
| Memory Usage | ~6GB (GPU) |
| Concurrent Requests | 1-2 (per llama3.2:3b) |
| Throughput | 5-10 requests/min |
| Confidence Accuracy | 88-95% |

**Optimization Tips:**
- Use batch processing for multiple prescriptions
- Cache few-shot examples in memory
- Implement request queuing for concurrent requests
- Monitor Ollama GPU memory usage

---

## Integration with OCR Service

```mermaid
graph LR
    USER["📱 User<br/>Mobile App"]
    
    BACKEND["🔵 Backend<br/>NestJS:3001"]
    
    OCR["🟢 OCR Service<br/>Port 8000"]
    
    AI["🟠 AI LLM<br/>Port 8001"]
    
    OLLAMA["🟡 Ollama<br/>Port 11434"]
    
    DB["📦 Database<br/>PostgreSQL"]
    
    USER -->|1. Upload Prescription| BACKEND
    BACKEND -->|2. Send to OCR| OCR
    OCR -->|3. Return OCR Results| BACKEND
    BACKEND -->|4. Send OCR to AI| AI
    AI -->|5. Send Prompt to Ollama| OLLAMA
    OLLAMA -->|6. Return Enhanced Data| AI
    AI -->|7. Return Enhanced Results| BACKEND
    BACKEND -->|8. Save to DB| DB
    BACKEND -->|9. Return to User| USER
```

---

## Model Details: llama3.2:3b

```mermaid
graph TB
    MODEL["llama3.2:3b<br/>Meta's Language Model"]
    
    SPECS["Specifications"]
    PERF["Performance"]
    USE["Use Cases"]
    
    SPECS --> PARAM["3 Billion Parameters"]
    SPECS --> SIZE["~2GB model file"]
    SPECS --> TRAIN["Trained on 15T tokens"]
    
    PERF --> SPEED["Fast inference (200-800ms)"]
    PERF --> QUAL["Good quality for medical domain"]
    PERF --> COST["Low inference cost (runs locally)"]
    
    USE --> MED["Medical extraction"]
    USE --> ENHANCE["Text enhancement"]
    USE --> REASON["Medical reasoning"]
    
    style PARAM fill:#e1f5ff
    style SIZE fill:#e1f5ff
    style TRAIN fill:#e1f5ff
    style SPEED fill:#c8e6c9
    style QUAL fill:#c8e6c9
    style COST fill:#c8e6c9
```

---

## Error Handling

```mermaid
graph TD
    INPUT["Input Validation"]
    INPUT -->|Invalid| ERR1["400: Invalid request"]
    INPUT -->|Valid| PROCESS["Process"]
    
    PROCESS -->|Ollama unavailable| ERR2["503: Service unavailable"]
    PROCESS -->|Timeout| ERR3["504: Gateway timeout"]
    PROCESS -->|Parse error| ERR4["422: Invalid response format"]
    PROCESS -->|Success| OUTPUT["200: Success"]
    
    style ERR1 fill:#ffcdd2
    style ERR2 fill:#ffcdd2
    style ERR3 fill:#ffcdd2
    style ERR4 fill:#ffcdd2
    style OUTPUT fill:#c8e6c9
```

---

## Summary

The AI LLM Service provides **intelligent enhancement and extraction** of OCR results:

1. **LLM Integration** → Connected to Ollama (llama3.2:3b)
2. **Few-Shot Learning** → Use examples in prompts
3. **Structured Extraction** → Medications, diagnosis, prescriber info
4. **Safety Validation** → Medical advice detection, language detection
5. **Data Validation** → Schema and range checks
6. **Reminder Generation** → User-friendly reminder text

All components are **modular, testable**, and follow **clean architecture principles**.
