What I completed
- Created and fixed:  
  data/training/comprehensive_dataset.jsonl
- Ensured UTF-8 Khmer text is correct (no corruption).
- Added 55 training examples (more than requested 50), including:
  - OCR error correction examples
  - Cambodian hospital prescription patterns
  - Common medicine examples
  - Khmer and mixed Khmer/English examples
  - Medical abbreviation examples
  - Mixed extraction tasks (full, medication-only, diagnosis-only, prescriber-only, duration-only)
Validation status
- Total lines: 55
- Invalid JSONL lines: 0
- Lines containing Khmer text: 52
---
How to train (beginner-friendly, exact commands)
Run from project root:
cd /home/rayu/das-tern/ai-llm-service
1) Start environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
2) Start Ollama (terminal 1)
ollama serve
3) Pull base model (terminal 2)
ollama pull llama3.1:8b
4) Use your new dataset for training
Your current training script uses:
data/training/finetuning_dataset.jsonl
So copy your new dataset into that file:
cp data/training/comprehensive_dataset.jsonl data/training/finetuning_dataset.jsonl
5) Train/create model
bash scripts/finetune_model.sh
6) Confirm model exists
ollama list
You should see:
- llama3.1:8b
- dastern-medical-extractor
7) Quick test the trained model
ollama run dastern-medical-extractor "Extract: paracetamo1 s00mg tab 1 tab BD x7 days"
8) Run your API with trained model
python -m uvicorn app.main_ollama:app --reload --port 8002
---
Important project note
Your README.md has a git merge conflict at the bottom (<<<<<<<, =======, >>>>>>>).  
That should be cleaned because it can confuse future setup/training steps.
Dataset is now ready for training and aligned to your AI prescription extraction service.