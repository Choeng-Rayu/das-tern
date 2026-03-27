# Local Qwen2.5-0.5B Model Setup Guide

## Table of Contents
- [Overview](#overview)
- [Setup Instructions](#setup-instructions)
- [Configuration](#configuration)
- [Fine-Tuning Guide](#fine-tuning-guide)
- [Testing and Evaluation](#testing-and-evaluation)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Why Switch from OpenRouter API to Local Model?

Previously, this service used OpenRouter API (with models like `google/gemma-3-4b-it:free`) for LLM inference. We've migrated to a **local model setup** using Ollama for several important reasons:

| Aspect | OpenRouter API | Local Model (Ollama) |
|--------|---------------|---------------------|
| **Cost** | API credits (may incur costs) | Completely free |
| **Privacy** | Data sent to external servers | All data stays local |
| **Latency** | Network round-trip required | Direct local inference |
| **Fine-tuning** | Not possible | Full control to customize |
| **Offline Use** | Requires internet | Works offline |
| **Rate Limits** | Subject to API limits | No limits |

### Why Qwen2.5-0.5B-Instruct?

We chose **Qwen2.5-0.5B-Instruct** as our base model for the following reasons:

1. **Small & Fast**: Only 500M parameters - runs efficiently on CPU or minimal GPU
2. **Instruction-tuned**: Pre-trained for following instructions (chat/completion tasks)
3. **Fine-tunable**: Small enough to fine-tune on consumer hardware
4. **Good Performance**: Despite its size, performs well on structured extraction tasks
5. **GGUF Quantized**: Q4_K_M quantization reduces size while maintaining quality
6. **Qwen Architecture**: Modern architecture with good multilingual support

**Model Specifications:**
- Parameters: 0.5 billion
- Quantization: Q4_K_M (4-bit)
- Context Window: 2048 tokens (configured)
- File Size: ~350MB
- Memory Usage: ~500MB RAM during inference

---

## Setup Instructions

### Prerequisites

1. **Ollama Installed**
   ```bash
   # Check if Ollama is installed
   ollama --version
   
   # If not installed, install via:
   curl -fsSL https://ollama.com/install.sh | sh
   
   # Or on Ubuntu/Debian:
   sudo apt install ollama
   ```

2. **Ollama Running**
   ```bash
   # Start Ollama server (usually runs as a service)
   ollama serve
   
   # Verify it's running
   curl http://localhost:11434/api/tags
   ```

### Model Download

The GGUF model file was downloaded from HuggingFace:

```bash
# Download location
cd /home/rayu/das-tern/ai-llm-service/models

# Download command used
wget https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf \
  -O Qwen2.5-0.5B-Instruct-Q4_K_M.gguf
```

**Model Location:**
```
/home/rayu/das-tern/ai-llm-service/models/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf
```

### Modelfile Configuration

The Modelfile defines how Ollama should use the model. Located at:
```
/home/rayu/das-tern/ai-llm-service/models/Modelfile.qwen-prescription
```

**Current Modelfile contents:**
```dockerfile
# Ollama Modelfile for Qwen2.5-0.5B-Instruct optimized for prescription OCR enhancement
FROM /home/rayu/das-tern/ai-llm-service/models/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf

# Parameters optimized for fast inference on small model
# Low temperature for accuracy and consistency in medical data
PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1
PARAMETER num_ctx 2048
PARAMETER num_predict 1024
PARAMETER stop "<|im_end|>"
PARAMETER stop "<|im_start|>"

# Concise system prompt optimized for 0.5B model
SYSTEM """Extract prescription data as JSON. Include: patient (name, age, gender), medications (name, dose, form, frequency), doctor, date. Fix OCR errors in drug names. Output valid JSON only."""

# Qwen2.5 ChatML template with im_start/im_end tokens
TEMPLATE """<|im_start|>system
{{ .System }}<|im_end|>
<|im_start|>user
{{ .Prompt }}<|im_end|>
<|im_start|>assistant
"""
```

**Parameter Explanation:**
| Parameter | Value | Purpose |
|-----------|-------|---------|
| `temperature` | 0.1 | Low for deterministic, accurate outputs |
| `top_p` | 0.9 | Nucleus sampling threshold |
| `top_k` | 40 | Limits vocabulary during sampling |
| `repeat_penalty` | 1.1 | Prevents repetitive output |
| `num_ctx` | 2048 | Context window size |
| `num_predict` | 1024 | Max tokens to generate |

### Creating the Ollama Model

Run this command from the models directory:

```bash
cd /home/rayu/das-tern/ai-llm-service/models

# Create the custom model
ollama create qwen-prescription -f Modelfile.qwen-prescription
```

**Verify the model was created:**
```bash
ollama list
# Should show: qwen-prescription
```

---

## Configuration

### Environment Variables

The `.env` file controls which LLM provider to use:

**For Local Model (Default):**
```env
# Provider selection
LLM_PROVIDER=ollama

# Ollama settings
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen-prescription
OLLAMA_FAST_MODEL=qwen-prescription
OLLAMA_TIMEOUT=60
```

**To Switch Back to OpenRouter:**
```env
# Provider selection
LLM_PROVIDER=openrouter

# OpenRouter settings
OPENROUTER_API_KEY=sk-or-v1-your_api_key_here
OPENROUTER_MODEL=google/gemma-3-4b-it:free
OPENROUTER_TIMEOUT=60
```

### Switching Between Providers

1. **Edit `.env` file:**
   ```bash
   nano /home/rayu/das-tern/ai-llm-service/.env
   ```

2. **Change `LLM_PROVIDER`:**
   - `ollama` - Use local model
   - `openrouter` - Use OpenRouter API

3. **Restart the service:**
   ```bash
   # If using uvicorn directly
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8002
   
   # Or restart your service manager
   systemctl restart ai-llm-service
   ```

---

## Fine-Tuning Guide

Since Qwen2.5-0.5B is small enough to fine-tune on consumer hardware, you can customize it for better prescription extraction performance.

### Option 1: LoRA Fine-Tuning with Unsloth (Recommended)

**Unsloth** is the recommended approach for fine-tuning small models like Qwen2.5-0.5B. It's 2-5x faster and uses 70% less memory than standard methods.

#### Installation

```bash
# Create a separate virtual environment for fine-tuning
python3 -m venv venv-finetune
source venv-finetune/bin/activate

# Install unsloth (choose based on your GPU)
# For NVIDIA GPUs with CUDA 12.1:
pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git"
pip install --no-deps "xformers<0.0.27" trl peft accelerate bitsandbytes

# For CPU-only or AMD:
pip install unsloth
```

#### Prepare Training Data

Create a JSONL file with prescription examples:

**File:** `data/training/prescription_examples.jsonl`
```jsonl
{"messages": [{"role": "system", "content": "Extract prescription data as JSON."}, {"role": "user", "content": "Patient: John Doe, Age 45, Male\nRx: Paracetamol 500mg\nTake 2 tablets twice daily for 3 days\nDr. Smith, 15/03/2026"}, {"role": "assistant", "content": "{\"patient\": {\"name\": \"John Doe\", \"age\": 45, \"gender\": \"Male\"}, \"medications\": [{\"name\": \"Paracetamol\", \"dose\": \"500mg\", \"form\": \"tablet\", \"quantity\": \"2\", \"frequency\": \"twice daily\", \"duration\": \"3 days\"}], \"doctor\": \"Dr. Smith\", \"date\": \"15/03/2026\"}"}]}
{"messages": [{"role": "system", "content": "Extract prescription data as JSON."}, {"role": "user", "content": "ឈ្មោះ: សុខ សារី អាយុ 30 ស្រី\nថ្នាំ: Amoxicillin 500mg\nញុំា 1 គ្រាប់ ៣ដងក្នុង១ថ្ងៃ រយៈពេល 7 ថ្ងៃ\nពេទ្យ: បណ្ឌិត ចាន់ថា"}, {"role": "assistant", "content": "{\"patient\": {\"name\": \"សុខ សារី\", \"age\": 30, \"gender\": \"ស្រី\"}, \"medications\": [{\"name\": \"Amoxicillin\", \"dose\": \"500mg\", \"form\": \"capsule\", \"quantity\": \"1\", \"frequency\": \"3 times daily\", \"duration\": \"7 days\"}], \"doctor\": \"បណ្ឌិត ចាន់ថា\", \"date\": null}"}]}
```

#### Fine-Tuning Script

Create `tools/finetune_qwen_unsloth.py`:

```python
#!/usr/bin/env python3
"""
Fine-tune Qwen2.5-0.5B-Instruct for prescription extraction using Unsloth.
"""

from unsloth import FastLanguageModel
from datasets import load_dataset
from trl import SFTTrainer
from transformers import TrainingArguments
import torch

# Configuration
MAX_SEQ_LENGTH = 2048
DTYPE = None  # Auto-detect
LOAD_IN_4BIT = True

# 1. Load the base model
print("Loading Qwen2.5-0.5B-Instruct...")
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="Qwen/Qwen2.5-0.5B-Instruct",
    max_seq_length=MAX_SEQ_LENGTH,
    dtype=DTYPE,
    load_in_4bit=LOAD_IN_4BIT,
)

# 2. Add LoRA adapters
print("Adding LoRA adapters...")
model = FastLanguageModel.get_peft_model(
    model,
    r=16,  # LoRA rank - higher = more capacity, more memory
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_alpha=16,
    lora_dropout=0,  # Optimized - no dropout
    bias="none",
    use_gradient_checkpointing="unsloth",  # Memory optimization
    random_state=42,
)

# 3. Load training data
print("Loading training data...")
dataset = load_dataset(
    "json",
    data_files="data/training/prescription_examples.jsonl",
    split="train"
)

# 4. Format for chat template
def formatting_prompts_func(examples):
    texts = []
    for messages in examples["messages"]:
        text = tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=False
        )
        texts.append(text)
    return {"text": texts}

dataset = dataset.map(formatting_prompts_func, batched=True)

# 5. Training arguments
training_args = TrainingArguments(
    output_dir="./outputs/qwen-prescription-finetuned",
    per_device_train_batch_size=2,
    gradient_accumulation_steps=4,
    warmup_steps=5,
    max_steps=100,  # Increase for more training
    learning_rate=2e-4,
    fp16=not torch.cuda.is_bf16_supported(),
    bf16=torch.cuda.is_bf16_supported(),
    logging_steps=10,
    optim="adamw_8bit",
    weight_decay=0.01,
    lr_scheduler_type="linear",
    seed=42,
)

# 6. Create trainer
trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=MAX_SEQ_LENGTH,
    args=training_args,
)

# 7. Train!
print("Starting fine-tuning...")
trainer.train()

# 8. Save the model
print("Saving model...")
model.save_pretrained("./outputs/qwen-prescription-lora")
tokenizer.save_pretrained("./outputs/qwen-prescription-lora")

# 9. Export to GGUF for Ollama
print("Exporting to GGUF format...")
model.save_pretrained_gguf(
    "models/qwen-prescription-finetuned",
    tokenizer,
    quantization_method="q4_k_m"
)

print("Done! GGUF model saved to: models/qwen-prescription-finetuned-Q4_K_M.gguf")
```

#### Run Fine-Tuning

```bash
# Activate fine-tuning environment
source venv-finetune/bin/activate

# Run the script
python tools/finetune_qwen_unsloth.py
```

#### Import Fine-Tuned Model into Ollama

After fine-tuning, update the Modelfile to use the new GGUF:

```bash
# Create new Modelfile
cat > models/Modelfile.qwen-prescription-finetuned << 'EOF'
FROM /home/rayu/das-tern/ai-llm-service/models/qwen-prescription-finetuned-Q4_K_M.gguf

PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER num_ctx 2048
PARAMETER num_predict 1024
PARAMETER stop "<|im_end|>"

SYSTEM """Extract prescription data as JSON. Include: patient (name, age, gender), medications (name, dose, form, frequency), doctor, date. Fix OCR errors in drug names. Output valid JSON only."""

TEMPLATE """<|im_start|>system
{{ .System }}<|im_end|>
<|im_start|>user
{{ .Prompt }}<|im_end|>
<|im_start|>assistant
"""
EOF

# Create the Ollama model
ollama create qwen-prescription-finetuned -f models/Modelfile.qwen-prescription-finetuned

# Test it
ollama run qwen-prescription-finetuned "Patient: Test User, Age 25\nRx: Ibuprofen 400mg, 1 tablet 3x daily"
```

### Option 2: Full Fine-Tuning with Transformers

For users with more GPU VRAM (8GB+), you can do full fine-tuning:

```python
#!/usr/bin/env python3
"""
Full fine-tuning using HuggingFace Transformers + PEFT.
Requires more GPU memory but can achieve better results.
"""

from transformers import (
    AutoModelForCausalLM,
    AutoTokenizer,
    TrainingArguments,
    Trainer,
    DataCollatorForLanguageModeling,
)
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from datasets import load_dataset
import torch

# Load model and tokenizer
model_name = "Qwen/Qwen2.5-0.5B-Instruct"

tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.float16,
    device_map="auto",
)

# Configure LoRA
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)

model = get_peft_model(model, lora_config)
model.print_trainable_parameters()

# Load and preprocess dataset
dataset = load_dataset(
    "json",
    data_files="data/training/prescription_examples.jsonl",
    split="train"
)

def preprocess(examples):
    texts = []
    for messages in examples["messages"]:
        text = tokenizer.apply_chat_template(messages, tokenize=False)
        texts.append(text)
    
    tokenized = tokenizer(
        texts,
        truncation=True,
        max_length=2048,
        padding="max_length",
    )
    tokenized["labels"] = tokenized["input_ids"].copy()
    return tokenized

tokenized_dataset = dataset.map(preprocess, batched=True, remove_columns=dataset.column_names)

# Training
training_args = TrainingArguments(
    output_dir="./outputs/qwen-prescription-full",
    num_train_epochs=3,
    per_device_train_batch_size=1,
    gradient_accumulation_steps=8,
    learning_rate=1e-4,
    fp16=True,
    logging_steps=10,
    save_steps=100,
    warmup_ratio=0.1,
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=tokenized_dataset,
    data_collator=DataCollatorForLanguageModeling(tokenizer, mlm=False),
)

trainer.train()

# Save
model.save_pretrained("./outputs/qwen-prescription-full-lora")
```

### Training Data Format

#### Expected JSONL Structure

Each line should be a JSON object with a `messages` array following the chat format:

```jsonl
{"messages": [{"role": "system", "content": "SYSTEM_PROMPT"}, {"role": "user", "content": "INPUT"}, {"role": "assistant", "content": "EXPECTED_OUTPUT"}]}
```

#### Example Training Data

**File Location:** `data/training/prescription_examples.jsonl`

```jsonl
{"messages": [{"role": "system", "content": "Extract prescription data as JSON."}, {"role": "user", "content": "Patient: Mary Johnson, Age 62, Female\nMedications:\n1. Metformin 500mg - Take 1 tablet twice daily with meals\n2. Lisinopril 10mg - Take 1 tablet once daily in the morning\nDiagnosis: Type 2 Diabetes, Hypertension\nPrescribed by: Dr. Robert Chen\nDate: 20/03/2026"}, {"role": "assistant", "content": "{\"patient\": {\"name\": \"Mary Johnson\", \"age\": 62, \"gender\": \"Female\"}, \"medications\": [{\"name\": \"Metformin\", \"dose\": \"500mg\", \"form\": \"tablet\", \"quantity\": \"1\", \"frequency\": \"twice daily\", \"instructions\": \"with meals\"}, {\"name\": \"Lisinopril\", \"dose\": \"10mg\", \"form\": \"tablet\", \"quantity\": \"1\", \"frequency\": \"once daily\", \"instructions\": \"in the morning\"}], \"diagnosis\": [\"Type 2 Diabetes\", \"Hypertension\"], \"doctor\": \"Dr. Robert Chen\", \"date\": \"20/03/2026\"}"}]}
{"messages": [{"role": "system", "content": "Extract prescription data as JSON."}, {"role": "user", "content": "Pt: David Lee, 8yo, M\nRx: Amox 250mg/5ml susp\nSig: 5ml PO TID x 10d\nDx: Acute otitis media\nDr. Sarah Kim, MD"}, {"role": "assistant", "content": "{\"patient\": {\"name\": \"David Lee\", \"age\": 8, \"gender\": \"Male\"}, \"medications\": [{\"name\": \"Amoxicillin\", \"dose\": \"250mg/5ml\", \"form\": \"suspension\", \"quantity\": \"5ml\", \"frequency\": \"three times daily\", \"duration\": \"10 days\", \"route\": \"oral\"}], \"diagnosis\": [\"Acute otitis media\"], \"doctor\": \"Dr. Sarah Kim, MD\", \"date\": null}"}]}
{"messages": [{"role": "system", "content": "Extract prescription data as JSON."}, {"role": "user", "content": "OCR TEXT (may contain errors):\nPaticnt: Jhon Smth Age: 55 M\nParacetamlo 500mg\n2 tab BID x 3 days\nIbuprofn 400mg PRN\nDr Wilsn"}, {"role": "assistant", "content": "{\"patient\": {\"name\": \"John Smith\", \"age\": 55, \"gender\": \"Male\"}, \"medications\": [{\"name\": \"Paracetamol\", \"dose\": \"500mg\", \"form\": \"tablet\", \"quantity\": \"2\", \"frequency\": \"twice daily\", \"duration\": \"3 days\"}, {\"name\": \"Ibuprofen\", \"dose\": \"400mg\", \"form\": \"tablet\", \"frequency\": \"as needed\"}], \"doctor\": \"Dr. Wilson\", \"date\": null}"}]}
```

#### Creating More Training Examples

1. **Collect Real Prescriptions**: Use actual (anonymized) prescription data
2. **Include OCR Errors**: Add examples with common OCR mistakes
3. **Vary Formats**: Include different prescription layouts
4. **Include Khmer**: Add bilingual examples
5. **Edge Cases**: PRN medications, complex dosing, multiple medications

**Recommended Dataset Size:**
| Dataset Size | Expected Accuracy | Training Time |
|-------------|-------------------|---------------|
| 50 examples | ~85% | ~5 minutes |
| 200 examples | ~92% | ~15 minutes |
| 500 examples | ~95% | ~30 minutes |
| 1000+ examples | ~97%+ | ~1 hour |

---

## Testing and Evaluation

### Manual Testing with Ollama

```bash
# Interactive test
ollama run qwen-prescription

# Single query test
ollama run qwen-prescription "Patient: Test User, Age 30, Male
Rx: Amoxicillin 500mg
Take 1 capsule three times daily for 7 days
Dr. Johnson, 25/03/2026"
```

### API Endpoint Testing

```bash
# Test via the service API
curl -X POST http://localhost:8002/api/v1/enhance \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Patient: Jane Doe, Age 45, Female\nRx: Metformin 500mg\n1 tab BD with meals\nDr. Smith"
  }'
```

### Automated Evaluation Script

Create `tools/evaluate_model.py`:

```python
#!/usr/bin/env python3
"""Evaluate model accuracy on test cases."""

import json
import time
import requests

TEST_CASES = [
    {
        "input": "Patient: John Doe, Age 30, Male\nRx: Paracetamol 500mg\n2 tablets twice daily for 3 days\nDr. Smith",
        "expected": {
            "patient_name": "John Doe",
            "medication": "Paracetamol",
            "dose": "500mg"
        }
    },
    # Add more test cases...
]

def evaluate():
    correct = 0
    total = len(TEST_CASES)
    total_time = 0
    
    for case in TEST_CASES:
        start = time.time()
        response = requests.post(
            "http://localhost:8002/api/v1/enhance",
            json={"text": case["input"]}
        )
        elapsed = time.time() - start
        total_time += elapsed
        
        try:
            result = response.json()
            # Check expected fields
            if all(k in str(result) for k in case["expected"].values()):
                correct += 1
                print(f"PASS ({elapsed:.2f}s)")
            else:
                print(f"FAIL: Expected {case['expected']}")
        except:
            print(f"ERROR: Invalid response")
    
    print(f"\n=== Results ===")
    print(f"Accuracy: {correct}/{total} ({100*correct/total:.1f}%)")
    print(f"Avg Time: {total_time/total:.2f}s per request")

if __name__ == "__main__":
    evaluate()
```

### Metrics to Track

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Accuracy** | >95% | Correct field extraction rate |
| **Latency** | <2s | Response time per request |
| **JSON Validity** | 100% | Parse success rate |
| **OCR Correction** | >90% | Drug name correction accuracy |
| **Memory Usage** | <1GB | Monitor during inference |

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Model Not Found

```
Error: model 'qwen-prescription' not found
```

**Solution:**
```bash
# Check available models
ollama list

# Recreate the model
cd /home/rayu/das-tern/ai-llm-service/models
ollama create qwen-prescription -f Modelfile.qwen-prescription
```

#### 2. Ollama Connection Refused

```
Error: connection refused at localhost:11434
```

**Solution:**
```bash
# Check if Ollama is running
pgrep ollama

# Start Ollama
ollama serve

# Or restart the service
sudo systemctl restart ollama
```

#### 3. Model Timeout Issues

```
Error: request timed out after 60s
```

**Solutions:**
1. Increase timeout in `.env`:
   ```env
   OLLAMA_TIMEOUT=120
   ```

2. Reduce context size in Modelfile:
   ```
   PARAMETER num_ctx 1024
   PARAMETER num_predict 512
   ```

3. Check system resources:
   ```bash
   htop  # Check CPU/memory usage
   ```

#### 4. Out of Memory

```
Error: CUDA out of memory / OOM Killed
```

**Solutions:**
1. Use CPU inference (no GPU required for 0.5B model)
2. Reduce batch size during fine-tuning
3. Use quantized model (Q4_K_M)
4. Close other applications

#### 5. Invalid JSON Output

**Solutions:**
1. Lower temperature for more deterministic output:
   ```
   PARAMETER temperature 0.05
   ```

2. Add explicit JSON instruction in prompt:
   ```
   Output ONLY valid JSON, no explanations.
   ```

3. Implement JSON validation in your code:
   ```python
   import json
   try:
       result = json.loads(response)
   except json.JSONDecodeError:
       # Fallback or retry
   ```

#### 6. Poor Extraction Quality

**Solutions:**
1. Fine-tune with more domain-specific examples
2. Add examples similar to failing cases
3. Improve system prompt specificity
4. Use few-shot examples in prompts

#### 7. Slow Inference

**Solutions:**
1. Enable GPU acceleration if available:
   ```bash
   # Check GPU
   nvidia-smi
   
   # Ollama uses GPU automatically if available
   ```

2. Reduce context window:
   ```
   PARAMETER num_ctx 1024
   ```

3. Use streaming for better UX:
   ```python
   # Enable streaming in API calls
   response = ollama.generate(model="qwen-prescription", prompt=text, stream=True)
   ```

### Log Locations

- Ollama logs: `journalctl -u ollama -f`
- Service logs: Check your application logs
- Training logs: `./outputs/` directory

### Getting Help

1. Check Ollama documentation: https://ollama.com/docs
2. Qwen model card: https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct
3. Unsloth documentation: https://github.com/unslothai/unsloth

---

## Quick Reference

### Key Paths

| Item | Path |
|------|------|
| GGUF Model | `/home/rayu/das-tern/ai-llm-service/models/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf` |
| Modelfile | `/home/rayu/das-tern/ai-llm-service/models/Modelfile.qwen-prescription` |
| Training Data | `/home/rayu/das-tern/ai-llm-service/data/training/` |
| Environment | `/home/rayu/das-tern/ai-llm-service/.env` |

### Key Commands

```bash
# Create/update model
ollama create qwen-prescription -f models/Modelfile.qwen-prescription

# Test model
ollama run qwen-prescription "Your test input here"

# Check model info
ollama show qwen-prescription

# Remove model
ollama rm qwen-prescription

# List all models
ollama list
```

### Environment Variables

```env
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=qwen-prescription
OLLAMA_FAST_MODEL=qwen-prescription
OLLAMA_TIMEOUT=60
```

---

**Last Updated:** March 2026  
**Model:** Qwen2.5-0.5B-Instruct (Q4_K_M quantized)  
**Ollama Model Name:** qwen-prescription
