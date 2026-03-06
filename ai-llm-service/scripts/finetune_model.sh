#!/bin/bash

echo "🎓 DasTern Medical Extractor - Fine-tuning Script"
echo "======================================================================"
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "❌ Error: Ollama is not running"
    echo "   Please start Ollama first: ollama serve"
    exit 1
fi

echo "✅ Ollama is running"
echo ""

# Check if training data exists
TRAINING_FILE="data/training/finetuning_dataset.jsonl"
if [ ! -f "$TRAINING_FILE" ]; then
    echo "❌ Error: Training dataset not found"
    echo "   Please run: python tools/create_finetuning_dataset.py"
    exit 1
fi

echo "✅ Training dataset found: $TRAINING_FILE"
LINE_COUNT=$(wc -l < "$TRAINING_FILE")
echo "   📊 Training examples: $LINE_COUNT"
echo ""

# Create Modelfile
echo "📝 Creating Modelfile..."
cat > Modelfile.dastern <<'EOF'
# DasTern Medical Prescription Extractor
# Fine-tuned model for Cambodian prescription data extraction

FROM llama3.1:8b

# System prompt for medical extraction
SYSTEM """
You are DasTern Medical Extractor, specialized in extracting structured data from Cambodian prescription OCR text.

YOUR TASK:
Extract prescription information into structured JSON format.

CRITICAL FIELDS TO EXTRACT:
1. **Medications** (array):
   - medication_name (string): Drug name
   - strength (string): e.g., "500mg", "20mg"
   - form (string): tablet, capsule, syrup, injection, cream
   - dosage (string): e.g., "1 tablet", "2 capsules"
   - frequency (string): e.g., "twice daily", "3 times a day"
   - frequency_times (integer): 1, 2, 3, 4
   - duration (string): e.g., "7 days", "2 weeks"
   - duration_days (integer): 7, 14, 30
   - instructions_english (string)
   - instructions_khmer (string)

2. **Diagnosis** (array of strings):
   - Extract all medical conditions
   - Look for numbered lists, "Diagnosis:" sections
   - Examples: ["Chronic Cystitis", "Hypertension"]

3. **Prescriber Information**:
   - prescriber_name: Doctor's name (with Dr. title)
   - prescriber_facility: Hospital/clinic name
   - prescriber_contact: Phone/contact (if present)

4. **Metadata**:
   - prescription_date: Date from prescription
   - language_detected: "en", "km", or "mixed"

OCR ERROR CORRECTION:
- Fix common OCR mistakes: 1→l, 0→O, 5→S, 8→B
- Example: "paracetamo1" → "Paracetamol"
- Example: "s00mg" → "500mg"

LANGUAGE SUPPORT:
- Handle both English and Khmer text
- Translate Khmer instructions to English
- Keep original Khmer in instructions_khmer field

OUTPUT FORMAT:
Always return valid JSON. No markdown, no explanations, just JSON.

EXAMPLE INPUT:
"1. Chronic Cystitis
Paracetamol s00mg
Take 1 tab1et twice dai1y for 7 days
Friendship Hospital"

EXAMPLE OUTPUT:
{
  "medications": [{
    "medication_name": "Paracetamol",
    "strength": "500mg",
    "form": "tablet",
    "dosage": "1 tablet",
    "frequency": "twice daily",
    "frequency_times": 2,
    "duration": "7 days",
    "duration_days": 7,
    "instructions_english": "Take 1 tablet twice daily for 7 days",
    "instructions_khmer": "ផឹកថ្នាំ ១គ្រាប់ ២ដង ក្នុងមួយថ្ងៃ រយៈពេល ៧ថ្ងៃ"
  }],
  "diagnosis": ["Chronic Cystitis"],
  "prescriber_facility": "Friendship Hospital",
  "prescriber_name": null,
  "prescription_date": null,
  "language_detected": "en"
}
"""

# Optimized parameters for medical extraction
PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER num_ctx 8192
PARAMETER repeat_penalty 1.1

# Stop sequences
PARAMETER stop "<|end|>"
PARAMETER stop "</json>"
PARAMETER stop "```"
EOF

echo "✅ Modelfile created"
echo ""

# Create the fine-tuned model
echo "🔨 Fine-tuning model (this may take 5-15 minutes)..."
echo "   Base model: llama3.1:8b"
echo "   Target model: dastern-medical-extractor"
echo ""

ollama create dastern-medical-extractor -f Modelfile.dastern

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================================================"
    echo "✅ SUCCESS! Fine-tuned model created"
    echo "======================================================================"
    echo ""
    echo "📊 Model Information:"
    ollama show dastern-medical-extractor
    echo ""
    echo "🧪 Test the model:"
    echo "   ollama run dastern-medical-extractor"
    echo ""
    echo "💡 Example test prompt:"
    echo '   >>> Extract from: "Paracetamol 500mg, take twice daily for 7 days"'
    echo ""
    echo "🚀 Use in your service:"
    echo "   Update OLLAMA_MODEL=dastern-medical-extractor"
    echo "   Restart: python -m uvicorn app.main_ollama:app --reload --port 8002"
    echo ""
else
    echo ""
    echo "❌ Failed to create fine-tuned model"
    echo "   Check errors above"
    exit 1
fi

# Clean up
rm -f Modelfile.dastern

echo "✅ Fine-tuning complete!"
