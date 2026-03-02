# AI-LLM Service

AI-powered prescription OCR extraction service using **fine-tuned LLaMA 3.1 8B** (dastern-medical-extractor) via Ollama.

## What This Does

Takes OCR output from prescription images and:
- **Corrects OCR errors** (s00mg → 500mg, paracetamo1 → Paracetamol)
- **Extracts structured medical data** (medications with dosage, frequency, duration)
- **Extracts diagnosis** (medical conditions)
- **Extracts prescriber information** (doctor name, facility)
- **Outputs database-ready JSON** with 18 prescription fields
- **Supports mixed languages** (English, Khmer, French)

---

## Setup (First Time)

### 1. Install Ollama & Download Base Model

```bash
# Install Ollama
brew install ollama

# Start Ollama server (keep this running in one terminal)
ollama serve

# In another terminal, download base LLaMA model (4.9GB, one-time download)
ollama pull llama3.1:8b

# Verify model is downloaded
ollama list
# Should show: llama3.1:8b
```

### 2. Setup Python Environment

```bash
cd /Users/macbook/CADT/DasTern/ai-llm-service

# Create virtual environment (first time only)
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# You should see (venv) prefix in your terminal
# Install dependencies
pip install -r requirements.txt
```

### 3. Set Environment Variable

```bash
# Set this every time you open a new terminal
export OLLAMA_HOST=http://localhost:11434

# Or add to ~/.zshrc to make it permanent:
echo 'export OLLAMA_HOST=http://localhost:11434' >> ~/.zshrc
```

### 4. Create Fine-Tuned Model (Required)

```bash
# Make sure you're in the project directory with venv activated
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate

# Step 1: Create training dataset from correction reports
python tools/create_finetuning_dataset.py
# Output: Creates data/training/finetuning_dataset.jsonl

# Step 2: Fine-tune the model (takes 5-15 minutes)
bash scripts/finetune_model.sh
# Output: Creates dastern-medical-extractor model

# Step 3: Verify fine-tuned model is created
ollama list
# Should now show: dastern-medical-extractor AND llama3.1:8b
```

### 5. Verify Setup

```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# Should show both models

# Test the fine-tuned model
ollama run dastern-medical-extractor "Extract: Paracetamol 500mg twice daily"
# Should return structured JSON with medication details
```

---

## Daily Usage

Every time you start working (3 terminals needed):

```bash
# Terminal 1: Start Ollama (keep running)
ollama serve

# Terminal 2: Start AI Service (keep running)
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
python -m uvicorn app.main_ollama:app --reload --port 8002
# Wait for: "Application startup complete."

# Terminal 3: Process OCR files
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
python tools/process_ocr_file.py data/your_ocr_file.json
```

---

## How to Use

### Process OCR Files

The main tool is `process_ocr_file.py` which extracts structured prescription data from OCR JSON files.

```bash
# Process any OCR file
python tools/process_ocr_file.py data/your_ocr_file.json

# With user ID (optional)
python tools/process_ocr_file.py data/your_ocr_file.json user-12345

# Example with existing test file
python tools/process_ocr_file.py data/tesseract_result_7.json
```

**Input format** - OCR JSON with any of these fields:
- `full_text` (most common)
- `corrected_text` (Tesseract format)
- `text` (generic format)
```json
{
  "corrected_text": "Dr. Sun Moniroth\nPatient: Mr. Pich\nparacetamo1 s00mg...",
  "raw": [...],
  "stats": {...}
}
```

**Output:** Creates `data/extracted_*.json` with database-ready data:
```json
{
  "success": true,
  "extracted_data": {
    "medications": [{
      "medication_name": "Paracetamol",
      "strength": "500mg",
      "form": "tablet",
      "dosage": "1 tablet",
      "frequency": "twice daily",
      "frequency_times": 2,
      "duration": "7 days",
      "duration_days": 7
    }],
    "diagnosis": ["Chronic Cystitis"],
    "prescriber_name": "Dr. Sun Moniroth"
  },
  "model_used": "dastern-medical-extractor",
  "confidence": 0.90
}
```

### Improve Model Accuracy (Re-train)

**When to use:** Add more training examples to improve accuracy

```bash
# Step 1: Re-create training dataset (reads all correction reports)
python tools/create_finetuning_dataset.py

# Step 2: Re-train the model (takes 5-15 minutes)
bash scripts/finetune_model.sh

# Step 3: Restart AI service (picks up new model automatically)
```

### Run Tests

```bash
# Test OCR processing
python tools/process_ocr_file.py data/tesseract_result_7.json

# Test model directly
ollama run dastern-medical-extractor "Extract: Paracetamol 500mg BD x 7 days"
```

---

## Project Structure

```
ai-llm-service/
├── tools/                              # CLI tools
│   ├── process_ocr_file.py             # Main OCR processor (USE THIS)
│   └── create_finetuning_dataset.py    # Create training data
├── scripts/                            # Automation scripts
│   └── finetune_model.sh               # Fine-tune model
├── app/                                # FastAPI application
│   ├── main_ollama.py                  # Main server
│   ├── api/extraction_routes.py        # Extraction endpoints
│   ├── core/finetuned_extractor.py     # Fine-tuned model client
│   └── core/ollama_client.py           # Ollama API client
├── data/                               # Data files
│   ├── training/finetuning_dataset.jsonl  # Training data
│   ├── reports/correction_report_*.json   # Correction reports
│   └── extracted_*.json                   # Extraction outputs
├── docs/                               # Documentation
│   ├── FINETUNING_GUIDE.md             # Complete fine-tuning guide
│   └── HOW_TO_RUN_AND_TEST.md          # Detailed usage guide
└── requirements_ollama.txt             # Python dependencies
```

---

## Common Tasks

### Daily Workflow

```bash
# Terminal 1: Start Ollama
ollama serve

# Terminal 2: Start AI Service  
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
python -m uvicorn app.main_ollama:app --reload --port 8002

# Terminal 3: Process OCR files
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
python tools/process_ocr_file.py data/prescription1.json
python tools/process_ocr_file.py data/prescription2.json

# Check outputs
ls -lh data/extracted_*.json
cat data/extracted_prescription1.json | python -m json.tool
```

### Re-train Model with New Data

```bash
# When you have new correction reports in data/reports/
python tools/create_finetuning_dataset.py
bash scripts/finetune_model.sh

# Restart service to use updated model
```

**Scenario:** You receive OCR from a new hospital and AI makes mistakes.

**Step 1: Test current AI**
```bash
python3 tools/process_with_corrections.py data/new_hospital.json
```

Check `reports/` - is the output correct?
- ✅ If correct → Done! No training needed
- ❌ If wrong → Continue to Step 2

**Step 2: Add training example**

You need:
1. The OCR JSON file (`new_hospital.json`)
2. The **original prescription image** (to read correct data)

```bash
python3 tools/add_training_simple.py data/new_hospital.json
```

**Step 3: Look at the image and type correct data**

Tool shows messy OCR, you type what you **see in the image**:
```
Patient name? [Look at image, type: "លោក ពេជ្រ ចន្ទ"]
Age? [Look at image, type: "35"]
Medication? [Look at image, type: "Paracetamol"]
Strength? [Look at image, type: "500mg"]
```

**Step 4: Test again**
```bash
python3 tools/process_with_corrections.py data/similar_prescription.json
```

AI now knows the pattern and will handle similar formats correctly!

### Update AI Behavior

Edit `prompts/medical_system_prompt.py`:
- Add new medication name patterns
- Add new OCR error corrections
- Update extraction rules

### View Generated Reports

```bash
# List all reports
ls -lh reports/

# View specific report (with jq for pretty formatting)
cat reports/correction_report_20260128_204805.json | jq

# Or without jq
cat reports/correction_report_20260128_204805.json
```

---

## Troubleshooting

**Ollama not responding:**
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not, start it
ollama serve
```

**Model not found:**
```bash
# List installed models
ollama list

# Pull LLaMA if missing
ollama pull llama3.1:8b
```

**Import errors:**
```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies if needed
pip install -r requirements.txt
```

**"venv/bin/activate: No such file":**
```bash
# You need to create venv first
python3 -m venv venv

# Then activate it
source venv/bin/activate
```

**Wrong Python version:**
```bash
# Check Python version (should be 3.8+)
python3 --version

# Use python3 explicitly
python3 tools/process_with_corrections.py data/file.json
```

---

## How Few-Shot Learning Works

**NOT traditional training** - no model updates, no GPU needed!

**What happens when you add training:**
1. Your example is saved to `data/training/sample_prescriptions.jsonl`
2. Every time AI processes OCR, it reads these examples
3. AI sees the pattern and mimics it

**Example:**

Before adding training:
```
AI sees: "paracetamo1 s00mg"
AI output: Confused, might fail
```

After adding ONE example:
```
Prompt to AI:
"Example: paracetamo1 s00mg → Paracetamol 500mg
Now process: Esome praso1 40mg"

AI output: Esomeprazole 40mg ✓
```

**Key points:**
- ✅ Works instantly (no training time)
- ✅ 3-5 examples usually enough
- ✅ No GPU needed
- ✅ Model stays the same (llama3.1:8b)

---

## Training Examples

Training data location: `data/training/sample_prescriptions.jsonl`

Current examples:
1. Khmer prescription (Calmette Hospital)
2. Mixed language prescription
3. English prescription
4. Messy OCR (Khmer-Soviet Hospital) with corrections

Add more using `tools/add_training_simple.py`

---

## Docker Deployment

```bash
# Build image
docker build -t ai-llm-service .

# Run container
docker run -p 8000:8000 \
  -e OLLAMA_HOST=http://host.docker.internal:11434 \
  ai-llm-service
```

---

## For Your Teammates

Three options for using this AI service:

### Option 1: Local Ollama (Recommended)
Everyone installs Ollama and downloads the model:
```bash
brew install ollama
ollama pull llama3.1:8b  # 4.9GB download per person
ollama serve
```
**Pros:** Fast (local), works offline  
**Cons:** 5GB storage per person

### Option 2: Shared Server
One person hosts Ollama, others connect remotely:
```bash
# Host machine (you):
OLLAMA_HOST=0.0.0.0:11434 ollama serve

# Teammates:
export OLLAMA_HOST=http://YOUR_IP:11434
python3 tools/process_with_corrections.py data/file.json
```
**Pros:** No model download for teammates  
**Cons:** Your machine must stay running

### Option 3: Docker
Package everything in Docker (see Docker Deployment section)

---

## Tips

- **Environment variables:** Always set `OLLAMA_HOST` before running scripts
- **Virtual environment:** Always activate with `source venv/bin/activate`
- **Training:** Start with 3-5 examples, add more as needed
- **Testing:** Use `test_real_ocr_data.py` to verify improvements
- **Reports:** Check `reports/` folder for detailed correction analysis
- **Original images:** Keep prescription images to add training examples later

### **Check Current Training Examples**
```bash
# View all examples
cat data/training/sample_prescriptions.jsonl | jq
```

### **Run All Tests**
```bash
cd tests/
python3 test_simple.py
python3 test_phase2.py
python3 test_real_ocr_data.py
```

---

## 🎯 Workflow Summary

```
1. Get OCR JSON from your system
   ↓
2. Process with AI
   python3 tools/process_with_corrections.py data/ocr.json
   ↓
3. Check accuracy in reports/
   ↓
4. If accuracy low (<85%), add training example
   python3 tools/add_training_simple.py data/ocr.json
   ↓
5. Process again - accuracy improves!
```

---

## 🆘 Need Help?

- **Setup issues:** See `docs/TESTING_GUIDE.md`
- **How to use tools:** See `docs/QUICK_REFERENCE.md`
- **Understanding corrections:** Check `reports/correction_report_*.json`

---

## 📞 Quick Commands

```bash
# Setup
source venv/bin/activate
export OLLAMA_HOST=http://localhost:11434

# Add training
python3 tools/add_training_simple.py <ocr.json>

# Process OCR
python3 tools/process_with_corrections.py <ocr.json>

# Test
python3 tests/test_real_ocr_data.py
```

---

**Everything is organized and ready to use!** 🚀
=======
# ai-llm-service

MT5-based FastAPI service for OCR correction and chat.

## Prerequisites
- Python 3.10+
- (Optional) GPU drivers/CUDA for faster inference

## Setup
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Run
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

Open:
- API docs: http://localhost:8001/docs
- Health: http://localhost:8001/health

## Endpoints
- POST /api/v1/correct
- POST /api/v1/chat

## Notes
- The MT5 model is downloaded on first run (can take time and disk space).
>>>>>>> 37d6bba29275ae1bbf219be386ab684374815fad
