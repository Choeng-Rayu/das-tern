# OCR Service - Detailed Architecture

## Overview
The OCR service is a Python FastAPI-based microservice that extracts structured data from medical prescription images. It uses the Kiri-OCR engine to perform text recognition and a custom pipeline to extract medications, patient information, and prescriber details.

---

## Component Architecture

```mermaid
graph TB
    subgraph "OCR Service - Internal Architecture"
        API["FastAPI Routes<br/>/extract /health /config"]
        
        subgraph "Orchestrator"
            ORCH["PipelineOrchestrator<br/>Coordinates pipeline flow"]
        end
        
        subgraph "Pipeline Components"
            PREP["Preprocessor<br/>Quality checks & enhancement"]
            LAYOUT["LayoutAnalyzer<br/>Region detection"]
            OCR_ENGINE["KiriOCREngine<br/>Text recognition"]
            PARSER["TextParser<br/>Extract structured data"]
        end
        
        subgraph "Utilities"
            RECONSTRUCT["TableRowReconstructor<br/>Cluster table lines"]
            FORMAT["ResultFormatter<br/>JSON formatting"]
        end
        
        subgraph "Models & Config"
            KIRI_MODEL["Kiri-OCR Model<br/>mrrtmob/kiri-ocr"]
            CONFIG["Configuration<br/>Device, paths, models"]
        end
    end
    
    INPUT["Input Image<br/>prescription.jpg"]
    OUTPUT["Output JSON<br/>Extracted data"]
    
    INPUT --> API
    API --> ORCH
    
    ORCH --> PREP
    PREP --> LAYOUT
    LAYOUT --> OCR_ENGINE
    OCR_ENGINE --> PARSER
    PARSER --> RECONSTRUCT
    RECONSTRUCT --> FORMAT
    
    FORMAT --> OUTPUT
    
    KIRI_MODEL -.-> OCR_ENGINE
    CONFIG -.-> ORCH
    CONFIG -.-> PREP
    CONFIG -.-> OCR_ENGINE
```

---

## Detailed Pipeline Flow

```mermaid
sequenceDiagram
    participant Client as Client/Backend
    participant API as FastAPI Routes
    participant Orch as PipelineOrchestrator
    participant Prep as Preprocessor
    participant Layout as LayoutAnalyzer
    participant Engine as KiriOCREngine
    participant Parser as TextParser
    participant Formatter as ResultFormatter
    
    Client->>API: POST /extract (image_bytes)
    API->>Orch: process_image(image_data)
    
    Orch->>Prep: preprocess(image)
    Prep->>Prep: Check blur, brightness, quality
    Prep->>Prep: Deskew, denoise, CLAHE, sharpen
    Prep-->>Orch: preprocessed_image
    
    Orch->>Layout: detect_regions(image)
    Layout->>Layout: Find header, patient, clinical, table, footer
    Layout-->>Orch: region_map
    
    Orch->>Engine: extract_text(image)
    Engine->>Engine: Load mrrtmob/kiri-ocr model
    Engine->>Engine: Perform text recognition
    Engine-->>Orch: ocr_lines (text + confidence + bbox)
    
    Orch->>Parser: parse_ocr_results(ocr_lines, region_map)
    Parser->>Parser: Extract medications, metadata
    Parser->>Parser: Classify lines by region
    Parser-->>Orch: structured_data
    
    Orch->>Formatter: format_result(structured_data)
    Formatter->>Formatter: Build JSON output
    Formatter-->>Orch: result_json
    
    Orch-->>API: result_json
    API-->>Client: {status, medications, patient_info, ...}
```

---

## Component Details

### 1. **FastAPI Routes** (`/ocr/app/api/routes.py`)

| Endpoint | Method | Input | Output |
|----------|--------|-------|--------|
| `/extract` | POST | Image file (multipart) | OCR results (JSON) |
| `/health` | GET | None | {status: "ok"} |
| `/config` | GET | None | Configuration details |

**Key Features:**
- Handles image upload validation
- Calls PipelineOrchestrator
- Returns formatted results

---

### 2. **Preprocessor** (`/ocr/app/pipeline/preprocessor.py`)

```mermaid
graph LR
    INPUT["Input Image"] --> BLUR["Blur Detection"]
    BLUR --> BRIGHTNESS["Brightness Check"]
    BRIGHTNESS --> DESKEW["Deskew"]
    DESKEW --> DENOISE["Denoise"]
    DENOISE --> CLAHE["CLAHE Enhancement"]
    CLAHE --> SHARPEN["Sharpen"]
    SHARPEN --> OUTPUT["Enhanced Image"]
    
    style BLUR fill:#e1f5ff
    style BRIGHTNESS fill:#e1f5ff
    style DESKEW fill:#f3e5f5
    style DENOISE fill:#f3e5f5
    style CLAHE fill:#e8f5e9
    style SHARPEN fill:#e8f5e9
```

**Methods:**
- `is_image_blurry()` - Uses Laplacian variance
- `is_image_too_dark()` - Checks mean brightness
- `deskew_image()` - Corrects image rotation
- `denoise_image()` - Applies bilateral filter
- `enhance_contrast()` - Uses CLAHE (Contrast Limited Adaptive Histogram Equalization)
- `sharpen_image()` - Uses unsharp mask

**Quality Metrics:**
- Blur threshold: Laplacian variance > 100
- Brightness threshold: Mean > 50
- Output: Enhanced image for OCR processing

---

### 3. **Layout Analyzer** (`/ocr/app/pipeline/layout_analyzer.py`)

```mermaid
graph TB
    subgraph "Region Detection"
        IMG["Input Image"]
        EDGES["Edge Detection<br/>Canny edges"]
        CONTOUR["Contour Detection<br/>Find regions"]
        CLUSTER["Clustering<br/>Group regions"]
    end
    
    subgraph "Region Classification"
        HEADER["Header Region<br/>Top 15% of image"]
        PATIENT["Patient Info<br/>Second section"]
        CLINICAL["Clinical Data<br/>Middle section"]
        TABLE["Table Region<br/>Detect tables"]
        FOOTER["Footer Region<br/>Bottom section"]
    end
    
    IMG --> EDGES
    EDGES --> CONTOUR
    CONTOUR --> CLUSTER
    CLUSTER --> HEADER
    CLUSTER --> PATIENT
    CLUSTER --> CLINICAL
    CLUSTER --> TABLE
    CLUSTER --> FOOTER
```

**Detection Methods:**
- Edge detection using Canny
- Contour-based region identification
- Spatial clustering
- Region type classification

**Output:**
```python
region_map = {
    'header': [(x1, y1, x2, y2), ...],
    'patient_info': [(x1, y1, x2, y2), ...],
    'clinical_data': [(x1, y1, x2, y2), ...],
    'table': [(x1, y1, x2, y2), ...],
    'footer': [(x1, y1, x2, y2), ...]
}
```

---

### 4. **Kiri-OCR Engine** (`/ocr/app/pipeline/ocr_engine.py`)

```mermaid
graph LR
    IMG["Input Image"] --> LOAD["Load Model<br/>mrrtmob/kiri-ocr"]
    LOAD --> WARMUP["Warmup Run<br/>First inference"]
    WARMUP --> EXTRACT["Extract Text<br/>Full inference"]
    EXTRACT --> OUTPUT["OCR Lines<br/>text + confidence + bbox"]
    
    style LOAD fill:#fff9c4
    style WARMUP fill:#fff9c4
    style EXTRACT fill:#c8e6c9
```

**Model Details:**
- **Model Name:** `mrrtmob/kiri-ocr`
- **Framework:** PyTorch
- **Input:** RGB image (preprocessed)
- **Output:** Text lines with bounding boxes and confidence scores

**Engine Methods:**
```python
def warmup() → None
    # First inference to initialize CUDA/hardware
    
def extract_text(image) → List[OCRLine]
    # Returns: [
    #   {'text': 'Medication', 'confidence': 0.95, 'bbox': (x, y, w, h)},
    #   ...
    # ]
```

---

### 5. **Text Parser** (`/ocr/app/pipeline/text_parser.py`)

```mermaid
graph TB
    subgraph "Parsing Pipeline"
        OCR_LINES["OCR Lines Input"]
        REGION_MAP["Region Map Input"]
        CLASSIFY["Classify Lines<br/>Assign to regions"]
        EXTRACT_MED["Extract Medications<br/>Regex patterns"]
        EXTRACT_PAT["Extract Patient Info<br/>Name, age, ID"]
        EXTRACT_PRES["Extract Prescriber<br/>Doctor, clinic"]
        EXTRACT_META["Extract Metadata<br/>Date, diagnosis"]
    end
    
    subgraph "Output Structure"
        OUT_MED["Medications[]<br/>name, dose, frequency"]
        OUT_PAT["PatientInfo<br/>name, age, gender"]
        OUT_PRES["PrescriberInfo<br/>doctor, clinic"]
        OUT_META["Metadata<br/>date, diagnosis"]
    end
    
    OCR_LINES --> CLASSIFY
    REGION_MAP --> CLASSIFY
    CLASSIFY --> EXTRACT_MED
    CLASSIFY --> EXTRACT_PAT
    CLASSIFY --> EXTRACT_PRES
    CLASSIFY --> EXTRACT_META
    
    EXTRACT_MED --> OUT_MED
    EXTRACT_PAT --> OUT_PAT
    EXTRACT_PRES --> OUT_PRES
    EXTRACT_META --> OUT_META
```

**Parsing Methods:**
- **Line Classification:** Assign each OCR line to a region type
- **Medication Extraction:** Regex patterns + keyword matching
- **Patient Info:** Parse name, age, gender, ID number
- **Prescriber Info:** Extract doctor name, clinic, contact
- **Metadata:** Date, diagnosis codes, special notes

**Output Structure:**
```python
parsed_data = {
    'medications': [
        {'name': 'Aspirin', 'dose': '500mg', 'frequency': '3x daily'},
        ...
    ],
    'patient_info': {'name': 'John Doe', 'age': 45, 'gender': 'M'},
    'prescriber_info': {'doctor': 'Dr. Smith', 'clinic': 'City Hospital'},
    'metadata': {'date': '2024-03-16', 'diagnosis': 'Hypertension'}
}
```

---

### 6. **Table Row Reconstructor** (`/ocr/app/pipeline/table_row_reconstructor.py`)

```mermaid
graph TB
    LINES["Table Region OCR Lines<br/>y-coordinate: 100, 102, 105, 110"]
    
    CLUSTER["Y-Coordinate Clustering<br/>Group by vertical position"]
    
    ROW1["Row 1<br/>Lines at y=100-105"]
    ROW2["Row 2<br/>Lines at y=110-115"]
    
    SORT1["Sort by X-Coordinate"]
    SORT2["Sort by X-Coordinate"]
    
    RECONSTRUCT1["Reconstruct: 'Med1 | Dose1 | Freq1'"]
    RECONSTRUCT2["Reconstruct: 'Med2 | Dose2 | Freq2'"]
    
    LINES --> CLUSTER
    CLUSTER --> ROW1
    CLUSTER --> ROW2
    ROW1 --> SORT1
    ROW2 --> SORT2
    SORT1 --> RECONSTRUCT1
    SORT2 --> RECONSTRUCT2
```

**Purpose:** Reconstruct table rows from scattered OCR lines

**Algorithm:**
1. Group OCR lines by vertical position (y-coordinate)
2. Sort lines within each group by horizontal position (x-coordinate)
3. Concatenate text to form complete rows

---

### 7. **Pipeline Orchestrator** (`/ocr/app/pipeline/orchestrator.py`)

```mermaid
graph TB
    START["Start: process_image(image_data)"]
    
    STEP1["1. Preprocess Image"]
    STEP2["2. Analyze Layout & Regions"]
    STEP3["3. Extract Text via OCR"]
    STEP4["4. Parse Extracted Text"]
    STEP5["5. Reconstruct Table Rows"]
    STEP6["6. Format Results"]
    
    ERROR["Error Handling<br/>Fallback strategies"]
    
    END["Return Result"]
    
    START --> STEP1
    STEP1 --> STEP2
    STEP2 --> STEP3
    STEP3 --> STEP4
    STEP4 --> STEP5
    STEP5 --> STEP6
    STEP6 --> END
    
    STEP1 -.-> ERROR
    STEP2 -.-> ERROR
    STEP3 -.-> ERROR
    ERROR -.-> STEP6
    
    style ERROR fill:#ffcdd2
```

**Key Responsibilities:**
- Coordinate all pipeline stages
- Handle errors and fallbacks
- Manage temporary data
- Return formatted results

---

## Data Flow Example

```mermaid
graph LR
    IMG["📄 Prescription Image<br/>1200x1600px, PNG"]
    
    PREP_OUT["✅ Preprocessed Image<br/>Denoised, enhanced, deskewed"]
    
    LAYOUT_OUT["🗺️ Region Map<br/>{header: [...], table: [...]}"]
    
    OCR_OUT["🔤 OCR Lines<br/>[{text, confidence, bbox}, ...]"]
    
    PARSE_OUT["📊 Structured Data<br/>{medications: [...], patient: {...}}"]
    
    JSON_OUT["✅ Final JSON Output<br/>Ready for AI enhancement"]
    
    IMG --> PREP_OUT
    PREP_OUT --> LAYOUT_OUT
    LAYOUT_OUT --> OCR_OUT
    OCR_OUT --> PARSE_OUT
    PARSE_OUT --> JSON_OUT
```

---

## Configuration

**Environment Variables:** (`/ocr/.env`)
```ini
DEVICE=cuda  # or 'cpu'
OCR_MODEL_NAME=mrrtmob/kiri-ocr
PREPROCESSOR_ENABLED=true
LAYOUT_ANALYSIS_ENABLED=true
TABLE_RECONSTRUCTION_ENABLED=true
LOG_LEVEL=INFO
```

**Model Paths:**
```
/ocr/app/models/kiri-ocr/  # Cached model
```

---

## Performance Metrics

| Metric | Value |
|--------|-------|
| Image Processing Time | 2-5 seconds |
| Model Load Time | ~3 seconds (first run) |
| OCR Accuracy | 92-98% (depending on image quality) |
| Supported Image Formats | PNG, JPG, TIFF |
| Max Image Size | 4096x4096px |
| Memory Usage | ~2GB (GPU) / ~500MB (CPU) |

---

## Error Handling

```mermaid
graph TD
    INPUT["Input Validation"]
    INPUT -->|Invalid| ERR1["Return 400: Invalid image"]
    INPUT -->|Valid| PROCESS["Process Image"]
    
    PROCESS -->|Blur detected| WARN1["Warn: Low image quality"]
    PROCESS -->|Brightness issue| WARN2["Warn: Poor lighting"]
    PROCESS -->|Success| OUTPUT["Return results"]
    
    PROCESS -->|OCR fails| ERR2["Return 500: OCR processing failed"]
    PROCESS -->|Parse fails| ERR3["Return 500: Data parsing failed"]
    
    style ERR1 fill:#ffcdd2
    style ERR2 fill:#ffcdd2
    style ERR3 fill:#ffcdd2
    style WARN1 fill:#fff9c4
    style WARN2 fill:#fff9c4
```

---

## Integration with Backend

```mermaid
graph LR
    BACKEND["🔵 NestJS Backend<br/>Port 3001"]
    OCR["🟢 OCR Service<br/>Port 8000"]
    AI["🟠 AI LLM Service<br/>Port 8001"]
    
    BACKEND -->|1. POST /extract<br/>image_bytes| OCR
    OCR -->|2. Return<br/>OCR results| BACKEND
    BACKEND -->|3. POST /enhance<br/>OCR results| AI
    AI -->|4. Return<br/>Enhanced results| BACKEND
```

---

## Summary

The OCR service follows a **modular pipeline architecture**:

1. **Input Validation** → Image received
2. **Preprocessing** → Quality enhancement
3. **Layout Analysis** → Region detection
4. **OCR Engine** → Text extraction (mrrtmob/kiri-ocr)
5. **Text Parsing** → Structured data extraction
6. **Table Reconstruction** → Row formation
7. **Output Formatting** → JSON response

Each component is **independently testable** and can be **extended or replaced** without affecting others.
