#!/bin/bash

echo "🚀 DasTern AI LLM Service - Live Demo"
echo "====================================="
echo ""

echo "📍 1. Showing Ollama Installation"
echo "--------------------------------"
echo "Ollama Version:"
ollama --version
echo ""
echo "Downloaded Models:"
ollama list
echo ""
echo "Service Status:"
ps aux | grep ollama | grep -v grep
echo ""

echo "📍 2. Testing Basic AI Generation" 
echo "--------------------------------"
echo "Testing: Extract patient name from prescription..."
ollama run llama3.1:8b "Extract patient name from: Dr. Smith, Patient: John Doe, Age: 30. Return only the name." | head -3
echo ""

echo "📍 3. Testing Code Integration"
echo "-----------------------------"
echo "Checking model connection..."
cd /Users/macbook/CADT/DasTern/ai-llm-service
OLLAMA_HOST=http://localhost:11434 /Users/macbook/CADT/DasTern/.venv/bin/python -c "
from app.core.model_loader import load_model, is_model_ready
print(f'✅ Model loaded: {load_model()}')
print(f'✅ Model ready: {is_model_ready()}')
"
echo ""

echo "📍 4. Testing Training Data"
echo "-------------------------"
echo "Training examples created:"
ls -la data/training/
echo ""
echo "Sample training data size:"
wc -l data/training/sample_prescriptions.jsonl
echo ""

echo "📍 5. Testing Simple Extraction"
echo "------------------------------"
echo "Running simple prescription test..."
OLLAMA_HOST=http://localhost:11434 /Users/macbook/CADT/DasTern/.venv/bin/python test_simple.py
echo ""

echo "📍 6. Project File Structure"
echo "---------------------------"
echo "AI LLM Service structure:"
tree -L 3 . 2>/dev/null || find . -type d -maxdepth 3 | head -20
echo ""

echo "📍 7. Key Achievements Summary"
echo "-----------------------------"
echo "✅ Ollama + LLaMA 3.1 8B installed locally"
echo "✅ Training data created (3 medical examples)"
echo "✅ Few-shot learning prescription enhancer built"
echo "✅ Multi-language support (Khmer/English/French)"
echo "✅ OCR error correction implemented"
echo "✅ Medical abbreviation expansion"
echo "✅ JSON structured output"
echo "✅ Testing framework created"
echo "✅ API-ready codebase"
echo ""

echo "🎯 Ready for Phase 3: API Integration!"
echo "======================================"