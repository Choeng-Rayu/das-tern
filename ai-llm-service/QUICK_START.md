# Quick Start Guide - DasTern AI-LLM Service

## 🚀 First Time Setup (30 minutes)

### 1. Install Ollama
```bash
brew install ollama
ollama pull llama3.1:8b
```

### 2. Setup Python Environment
```bash
cd /Users/macbook/CADT/DasTern/ai-llm-service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_ollama.txt
```

### 3. Create Fine-Tuned Model
```bash
# Step 1: Create training data
python tools/create_finetuning_dataset.py

# Step 2: Fine-tune model (takes 5-15 minutes)
bash scripts/finetune_model.sh

# Step 3: Verify
ollama list
# Should show: dastern-medical-extractor
```

---

## 📋 Daily Usage (Every Time You Work)

### Open 3 Terminals:

**Terminal 1: Ollama**
```bash
ollama serve
```

**Terminal 2: AI Service**
```bash
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
python -m uvicorn app.main_ollama:app --reload --port 8002
```

**Terminal 3: Process OCR**
```bash
cd /Users/macbook/CADT/DasTern/ai-llm-service
source venv/bin/activate
python tools/process_ocr_file.py data/your_ocr.json
```

---

## 📁 Input Format

Your OCR JSON must have one of:
- `full_text` (most common)
- `corrected_text` (Tesseract)
- `text` (generic)

Example:
```json
{
  "full_text": "Paracetamol 500mg, take twice daily for 7 days",
  "overall_confidence": 0.82
}
```

---

## 📤 Output Format

Creates `data/extracted_*.json`:
```json
{
  "success": true,
  "extracted_data": {
    "medications": [{
      "medication_name": "Paracetamol",
      "strength": "500mg",
      "frequency": "twice daily",
      "duration": "7 days",
      "duration_days": 7
    }],
    "diagnosis": ["Fever"],
    "prescriber_name": "Dr. Smith",
    "prescription_date": "2025-06-15"
  },
  "model_used": "dastern-medical-extractor",
  "confidence": 0.90
}
```

---

## ✅ Checklist

- [ ] Ollama installed: `ollama --version`
- [ ] Base model downloaded: `ollama list` shows `llama3.1:8b`
- [ ] Python venv created and activated
- [ ] Packages installed: `pip list | grep fastapi`
- [ ] Training dataset created: `ls data/training/finetuning_dataset.jsonl`
- [ ] Fine-tuned model exists: `ollama list` shows `dastern-medical-extractor`
- [ ] Ollama server running: `curl http://localhost:11434/api/tags`
- [ ] AI service running: `curl http://localhost:8002/docs`
- [ ] Can process OCR: `python tools/process_ocr_file.py data/tesseract_result_7.json`

---

## 🔄 Re-training (When Needed)

When you have new correction reports:
```bash
# Recreate training data
python tools/create_finetuning_dataset.py

# Re-train model
bash scripts/finetune_model.sh

# Restart AI service (Terminal 2)
```

---

## 📚 Documentation

- **Full Guide:** `docs/HOW_TO_RUN_AND_TEST.md`
- **Fine-tuning Details:** `docs/FINETUNING_GUIDE.md`
- **Project Structure:** `docs/FOLDER_STRUCTURE.md`
- **Main README:** `README.md`

---

## ❓ Troubleshooting

**"Connection refused"**
→ Start Ollama: `ollama serve`

**"Model not available"**
→ Run fine-tuning: `bash scripts/finetune_model.sh`

**"Command not found: python"**
→ Activate venv: `source venv/bin/activate`

**"No module named fastapi"**
→ Install packages: `pip install -r requirements_ollama.txt`

---

## 🎯 Quick Test

```bash
# Test everything works
python tools/process_ocr_file.py data/tesseract_result_7.json

# Should output:
# ✅ Extraction successful!
# 💾 Saved extraction to: data/extracted_tesseract_result_7.json
```
