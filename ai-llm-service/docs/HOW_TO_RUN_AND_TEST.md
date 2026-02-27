# AI-LLM Service - Complete Guide

## 📋 Table of Contents
1. [What This Service Does](#what-this-service-does)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Fine-Tuning Setup](#fine-tuning-setup)
5. [Running the Service](#running-the-service)
6. [Processing OCR Files](#processing-ocr-files)
7. [Available Endpoints](#available-endpoints)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 What This Service Does

The AI-LLM Service uses a **fine-tuned LLaMA 3.1 8B model** (`dastern-medical-extractor`) via Ollama to provide:

### Core Capabilities:
1. **Prescription Data Extraction** 
   - Extracts 18 database fields from OCR text
   - Medications with full details (name, strength, dosage, frequency, duration)
   - Diagnosis extraction
   - Prescriber information
   - Prescription date

2. **OCR Error Correction**
   - Fixes common OCR mistakes: `s00mg` → `500mg`, `paracetamo1` → `Paracetamol`
   - Handles mixed languages (English/Khmer/French)

3. **Structured JSON Output**
   - Database-ready format
   - 90-95% extraction accuracy
   - Validation and confidence scores

---

## 📦 Prerequisites

### Required Software:
- **macOS** (or Linux/Windows with adjustments)
- **Python 3.8+**
- **Ollama** (AI model runtime)
- **curl** (for testing)

### System Requirements:
- Minimum 8GB RAM (16GB recommended for LLaMA 8B)
- 10GB free disk space (for model storage)
- Internet connection (for initial setup)

---

## 🚀 Initial Setup

### Step 1: Install Ollama

```bash
# Install Ollama on macOS
brew install ollama

# Or download from: https://ollama.ai/download

# Verify installation
ollama --version
```

### Step 2: Download Base AI Model

```bash
# Download LLaMA 3.1 8B model (4.9GB - one-time download)
ollama pull llama3.1:8b

# Verify model is downloaded
ollama list
# Expected output: llama3.1:8b    4.9 GB
```

### Step 3: Setup Python Environment

```bash
# Navigate to project directory
cd /Users/macbook/CADT/DasTern/ai-llm-service

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate
# You should see (venv) prefix in your terminal

# Install required packages
pip install -r requirements_ollama.txt
```

---

## 🎓 Fine-Tuning Setup (Required)

The service requires a fine-tuned model specialized for Cambodian prescriptions.

### Step 1: Create Training Dataset

```bash
# Make sure venv is activated
source venv/bin/activate

# Create training dataset from correction reports
python tools/create_finetuning_dataset.py
```

**Output:**
```
🎓 Creating Fine-tuning Dataset for DasTern Medical Extractor
======================================================================
📁 Found 2 correction reports
📄 Processing: correction_report_20260128_204805.json
   ✅ Generated 7 training examples
✅ Dataset saved to: data/training/finetuning_dataset.jsonl
📊 Total examples: 16
```

### Step 2: Fine-Tune the Model

```bash
# Run fine-tuning script (takes 5-15 minutes)
bash scripts/finetune_model.sh
```

**What happens:**
1. Creates Modelfile with medical extraction system prompt
2. Fine-tunes llama3.1:8b → dastern-medical-extractor
3. Optimizes for medical keyword extraction

**Expected output:**
```
🔨 Fine-tuning model...
gathering model components 
using existing layer sha256:...
creating new layer sha256:...
writing manifest 
success 

✅ SUCCESS! Fine-tuned model created
```

### Step 3: Verify Model

```bash
# Check model is available
ollama list

# Should show:
# dastern-medical-extractor    4.9 GB    2 minutes ago
# llama3.1:8b                  4.9 GB    7 days ago

# Test the model
ollama run dastern-medical-extractor "Extract: Paracetamol 500mg twice daily"
```

---

## 🚀 Running the Service

You need **3 terminals** running simultaneously:
pip list | grep -E 'fastapi|uvicorn|requests'

# Expected output should show:
# fastapi       0.104.0+
# uvicorn       0.24.0+
# requests      2.31.0+
```

---

## 🏃 Running the Service

### Terminal 1: Start Ollama

```bash
# Start Ollama server (keep this running)
ollama serve

# Expected output:
# Listening on 127.0.0.1:11434
```

### Terminal 2: Start AI Service

```bash
# Navigate to project
cd /Users/macbook/CADT/DasTern/ai-llm-service

# Activate virtual environment
source venv/bin/activate

# Start FastAPI service
python -m uvicorn app.main_ollama:app --reload --port 8002

# Wait for:
# INFO:     Application startup complete.
# INFO:     Available Ollama models: ['dastern-medical-extractor', 'llama3.1:8b']
```

### Terminal 3: Process OCR Files

```bash
# Navigate to project
cd /Users/macbook/CADT/DasTern/ai-llm-service

# Activate virtual environment
source venv/bin/activate

# Process an OCR file
python tools/process_ocr_file.py data/tesseract_result_7.json

# Or with user ID
python tools/process_ocr_file.py data/your_ocr.json user-12345
```

---

## 📊 Processing OCR Files

### Using the CLI Tool

The main tool is `tools/process_ocr_file.py`:
```

**Expected Output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8002
INFO:     Started reloader process [12345]
INFO:     OllamaClient initialized with base_url: http://localhost:11434, timeout: 300s
INFO:     Starting Ollama AI Service...
INFO:     Available Ollama models: ['llama3.1:8b']
INFO:     Application startup complete.
```

### Method 2: With Custom Configuration

```bash
# Start with custom timeout (10 minutes for complex prescriptions)
export OLLAMA_HOST=http://localhost:11434
export OLLAMA_TIMEOUT=600
export OLLAMA_MODEL=llama3.1:8b

python -m uvicorn app.main_ollama:app --reload --host 0.0.0.0 --port 8002
```

### Verify Service is Running

**Open in browser:**
```
http://localhost:8002/docs
```

This opens the **Swagger UI** - an interactive API documentation interface.

---

## 🧪 Testing the Service

### Test 1: Health Check

**Terminal 3 (New Terminal):**
```bash
curl http://localhost:8002/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "ollama-ai-service",
  "ollama_connected": true
}
```

### Test 2: Service Information

```bash
curl http://localhost:8002/
```

**Expected Response:**
```json
{
  "service": "Ollama AI Service",
  "status": "running",
  "model": "llama3.1:8b",
  "ollama_url": "http://localhost:11434",
  "capabilities": [
    "ocr_correction",
    "chatbot",
    "structured_reminders"
  ]
}
```

### Test 3: OCR Correction (Simple)

```bash
curl -X POST http://localhost:8002/correct-ocr \
  -H "Content-Type: application/json" \
  -d '{
    "text": "paracetamo1 s00mg\nDosage: Take 1 tab1et twice dai1y\nPatient: Mr. Pich Chan",
    "language": "en"
  }'
```

**Expected Response:**
```json
{
  "corrected_text": "Paracetamol 500mg\nDosage: Take 1 tablet twice daily\nPatient: Mr. Pich Chan",
  "confidence": 0.85,
  "corrections_made": 1,
  "model_used": "llama3.1:8b"
}
```

**Note:** First request may take 10-30 seconds (model warming up). Subsequent requests are faster.

### Test 4: OCR Correction (Standard API)

```bash
curl -X POST http://localhost:8002/api/v1/correct \
  -H "Content-Type: application/json" \
  -d '{
    "raw_text": "Dr. Sun Moniroth\nPatient: Mr. Sok Pich\nParacetamo1: s00mg\nTake 1 tab1et 2 times dai1y",
    "language": "en",
    "context": "prescription"
  }'
```

**Expected Response:**
```json
{
  "corrected_text": "Dr. Sun Moniroth\nPatient: Mr. Sok Pich\nParacetamol: 500mg\nTake 1 tablet 2 times daily",
  "confidence": 0.85,
  "language": "en",
  "metadata": {
    "model": "llama3.1:8b",
    "service": "ollama-ai-service"
  }
}
```

### Test 5: Medical Chatbot

```bash
curl -X POST http://localhost:8002/api/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is Paracetamol used for?",
    "language": "en",
    "context": "medical"
  }'
```

**Expected Response:**
```json
{
  "response": "Paracetamol is commonly used to treat pain and reduce fever. It's effective for headaches, muscle aches, arthritis, backaches, toothaches, and colds.",
  "language": "en",
  "confidence": 0.85,
  "metadata": {
    "model": "llama3.1:8b",
    "service": "ollama-ai-service"
  }
}
```

### Test 6: Extract Medication Reminders

```bash
curl -X POST http://localhost:8002/extract-reminders \
  -H "Content-Type: application/json" \
  -d '{
    "ocr_data": {
      "corrected_text": "Patient: Mr. Sok Pich\nAge: 35\n\nMedications:\n1. Paracetamol 500mg - Take 1 tablet twice daily for 7 days\n2. Amoxicillin 250mg - Take 1 capsule three times daily for 5 days",
      "raw": []
    }
  }'
```

**Expected Response:**
```json
{
  "patient_name": "Mr. Sok Pich",
  "medications": [
    {
      "name": "Paracetamol",
      "dosage": "500mg",
      "frequency": "twice daily",
      "duration": "7 days",
      "reminders": [
        {
          "time": "08:00",
          "description": "Take 1 tablet of Paracetamol 500mg"
        },
        {
          "time": "20:00",
          "description": "Take 1 tablet of Paracetamol 500mg"
        }
      ]
    },
    {
      "name": "Amoxicillin",
      "dosage": "250mg",
      "frequency": "three times daily",
      "duration": "5 days",
      "reminders": [
        {
          "time": "08:00",
          "description": "Take 1 capsule of Amoxicillin 250mg"
        },
        {
          "time": "14:00",
          "description": "Take 1 capsule of Amoxicillin 250mg"
        },
        {
          "time": "20:00",
          "description": "Take 1 capsule of Amoxicillin 250mg"
        }
      ]
    }
  ]
}
```

### Test 7: Using Test Scripts

**Run built-in tests:**

```bash
# Make sure service is running first

# Simple extraction test
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
export OLLAMA_HOST=http://localhost:11434

python tests/test_simple.py
```

**Expected Output:**
```
🧪 Testing Simple Prescription Extraction
============================================================
Raw LLaMA Response:
----------------------------------------
{"patient_name": "John Doe", "medication_name": "Paracetamol"}
----------------------------------------

Extracted JSON:
{"patient_name": "John Doe", "medication_name": "Paracetamol"}

✅ Test passed!
```

**Run real OCR data test:**

```bash
python tests/test_real_ocr_data.py
```

---

## 📚 Available Endpoints

### 1. **GET /** - Service Information
- **Purpose:** Get service status and capabilities
- **No authentication required**

### 2. **GET /health** - Health Check
- **Purpose:** Verify service and Ollama connection
- **Returns:** Connection status

### 3. **POST /correct-ocr** - Simple OCR Correction
- **Purpose:** Fix OCR errors quickly
- **Input:**
  ```json
  {
    "text": "string (required)",
    "language": "string (optional, default: en)"
  }
  ```
- **Output:**
  ```json
  {
    "corrected_text": "string",
    "confidence": "float",
    "corrections_made": "int",
    "model_used": "string"
  }
  ```

### 4. **POST /api/v1/correct** - Standard OCR Correction
- **Purpose:** Full-featured OCR correction with metadata
- **Input:**
  ```json
  {
    "raw_text": "string (required)",
    "language": "string (optional)",
    "context": "string (optional)"
  }
  ```

### 5. **POST /api/v1/chat** - Medical Chatbot
- **Purpose:** Ask medical questions
- **Input:**
  ```json
  {
    "message": "string (required)",
    "language": "string (optional)",
    "context": "string (optional)"
  }
  ```

### 6. **POST /extract-reminders** - Generate Medication Reminders
- **Purpose:** Extract structured medication schedules
- **Input:**
  ```json
  {
    "ocr_data": {
      "corrected_text": "string",
      "raw": []
    }
  }
  ```

### Interactive API Documentation
- **Swagger UI:** http://localhost:8002/docs
- **ReDoc:** http://localhost:8002/redoc

---

## 🔧 Troubleshooting

### Problem 1: "Cannot connect to Ollama"

**Symptom:**
```json
{"status": "unhealthy", "ollama_connected": false}
```

**Solution:**
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If no response, start Ollama
ollama serve
```

### Problem 2: "Model not found"

**Symptom:**
```
WARNING: Default model llama3.1:8b not found
```

**Solution:**
```bash
# List available models
ollama list

# Download missing model
ollama pull llama3.1:8b
```

### Problem 3: Timeout Errors

**Symptom:**
```json
{"detail": "Ollama request timeout"}
```

**Solution:**
```bash
# Increase timeout (default 300s)
export OLLAMA_TIMEOUT=600

# Then restart service
python -m uvicorn app.main_ollama:app --reload --host 0.0.0.0 --port 8002
```

### Problem 4: Port Already in Use

**Symptom:**
```
ERROR: [Errno 48] error while attempting to bind on address ('0.0.0.0', 8002)
```

**Solution:**
```bash
# Find process using port 8002
lsof -ti:8002

# Kill the process (use PID from above)
kill -9 <PID>

# Or use different port
python -m uvicorn app.main_ollama:app --reload --host 0.0.0.0 --port 8003
```

### Problem 5: Virtual Environment Issues

**Symptom:**
```
ModuleNotFoundError: No module named 'fastapi'
```

**Solution:**
```bash
# Make sure venv is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

### Problem 6: Slow First Request

**Expected Behavior:**
- First request: 10-30 seconds (model loading)
- Subsequent requests: 2-10 seconds (normal)

**Not a problem** - this is expected behavior!

---

## 📊 Performance Tips

### 1. Model Optimization
```bash
# Use smaller model for faster responses
ollama pull llama3.2:3b  # Smaller, faster
export OLLAMA_MODEL=llama3.2:3b
```

### 2. Reduce Input Size
- Limit text to 200 characters for faster processing
- Service automatically truncates long inputs

### 3. Adjust Temperature
- Lower temperature (0.1-0.3) = More consistent, faster
- Higher temperature (0.7-0.9) = More creative, slower

---

## 🔒 Security Notes

### Development Mode (Current)
- CORS: Allow all origins (`*`)
- No authentication required
- Suitable for **local development only**

### Production Recommendations
- Add API key authentication
- Restrict CORS to specific domains
- Use HTTPS
- Rate limiting
- Input validation

---

## 📝 Daily Workflow

```bash
# Every time you start working:

# 1. Start Ollama (Terminal 1)
ollama serve

# 2. Start AI Service (Terminal 2)
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
export OLLAMA_HOST=http://localhost:11434
python -m uvicorn app.main_ollama:app --reload --host 0.0.0.0 --port 8002

# 3. Test (Terminal 3)
curl http://localhost:8002/health

# 4. Use Swagger UI for interactive testing
# Open: http://localhost:8002/docs
```

---

## 🎓 Learn More

### Documentation Files:
- `README.md` - Overview and quick start
- `TIMEOUT_FIX.md` - Timeout optimization guide
- `requirements.txt` - Python dependencies
- `app/schemas.py` - API request/response schemas

### Example Data:
- `data/ocr_result_*.json` - Sample OCR outputs
- `data/training/sample_prescriptions.jsonl` - Training examples

### Test Scripts:
- `tests/test_simple.py` - Basic functionality test
- `tests/test_real_ocr_data.py` - Real-world OCR test
- `tests/test_phase2.py` - Advanced features

---

## ✅ Quick Checklist

Before using the service, ensure:

- [ ] Ollama installed: `ollama --version`
- [ ] Model downloaded: `ollama list` shows `llama3.1:8b`
- [ ] Ollama running: `ollama serve`
- [ ] Python venv activated: `(venv)` prefix visible
- [ ] Dependencies installed: `pip list | grep fastapi`
- [ ] Environment set: `echo $OLLAMA_HOST`
- [ ] Service running: `curl http://localhost:8002/health`

---

## 🆘 Need Help?

If you encounter issues not covered here:

1. Check service logs in the terminal where uvicorn is running
2. Verify Ollama logs: `ollama list` and check model status
3. Review `TIMEOUT_FIX.md` for timeout-related issues
4. Test with Swagger UI at http://localhost:8002/docs
5. Try the simple test script: `python tests/test_simple.py`

---

**Service Version:** 1.0.0  
**Last Updated:** February 3, 2026  
**Maintained by:** DasTern Development Team
