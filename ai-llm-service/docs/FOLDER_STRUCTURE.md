# AI-LLM Service - Folder Structure

Last Updated: February 3, 2026

## 📁 Clean Organized Structure

```
ai-llm-service/
├── README.md                          # Main documentation
├── requirements.txt                   # Python dependencies
├── requirements_ollama.txt            # Ollama-specific requirements
├── Dockerfile                         # Docker configuration
│
├── app/                               # Main application code
│   ├── __init__.py
│   ├── main.py                        # MT5 model server
│   ├── main_ollama.py                 # Ollama server (recommended)
│   ├── schemas.py                     # Pydantic models
│   ├── chat_assistant.py              # Chat functionality
│   ├── ocr_corrector.py               # OCR correction
│   ├── confidence.py                  # Confidence scoring
│   ├── model_loader.py                # Model management
│   │
│   ├── core/                          # Core functionality
│   │   ├── generation.py              # Text generation
│   │   └── ollama_client.py           # Ollama API client
│   │
│   ├── features/                      # Feature modules
│   │   ├── reminder_engine.py         # Reminder generation
│   │   └── prescription/              # Prescription processing
│   │       ├── enhancer.py            # Data enhancement
│   │       ├── fast_parser.py         # Quick parsing
│   │       ├── processor.py           # Data processing
│   │       └── reminder_generator.py  # Reminder creation
│   │
│   └── prompts/                       # API prompt templates
│       ├── chatbot.txt                # Chatbot prompts
│       ├── medical_help.txt           # Medical assistance
│       └── ocr_fix.txt                # OCR correction
│
├── docs/                              # Documentation
│   ├── HOW_TO_RUN_AND_TEST.md        # Complete setup guide
│   ├── TIMEOUT_FIX.md                # Timeout troubleshooting
│   ├── FOLDER_STRUCTURE.md           # This file
│   └── examples/                      # Example outputs
│       └── correction_report_20260128_230033.json
│
├── data/                              # Data files
│   ├── ocr_result_20260128_215749.json
│   ├── ocr_test_image2_20260127_162549.json
│   │
│   ├── reports/                       # Generated reports (gitignored)
│   │   ├── .gitignore
│   │   ├── README.md
│   │   └── correction_report_20260128_204805.json
│   │
│   └── training/                      # Training examples
│       └── sample_prescriptions.jsonl
│
├── scripts/                           # Utility scripts
│   ├── setup_ollama.sh               # Initial Ollama setup
│   ├── test_ollama.sh                # Test Ollama connection
│   └── simple_ai_fallback.py         # Fallback processing
│
├── tools/                             # Development tools
│   ├── add_training_simple.py        # Add training examples
│   └── process_with_corrections.py   # Process OCR with AI
│
├── tests/                             # Test suite
│   ├── test_simple.py                # Basic functionality test
│   ├── test_real_ocr_data.py         # Real OCR data test
│   ├── test_phase2.py                # Advanced tests
│   └── demo_showcase.sh              # Demo script
│
└── prompts/                           # System prompts
    └── medical_system_prompt.py      # Medical AI instructions

```

## 🔄 Changes Made (February 3, 2026)

### Moved to `docs/`:
- ✅ `TIMEOUT_FIX.md` (troubleshooting guide)
- ✅ `correction_report_20260128_230033.json` → `docs/examples/`

### Moved to `scripts/`:
- ✅ `setup_ollama.sh` (setup utility)
- ✅ `test_ollama.sh` (test utility)
- ✅ `simple_ai_fallback.py` (fallback handler)

### Moved to `data/`:
- ✅ `reports/` folder → `data/reports/`
- ✅ All report files consolidated under `data/reports/`

### Removed:
- ✅ Empty `reports/` folder (merged into `data/reports/`)

## 📂 Folder Purpose

### `/app` - Application Code
Core FastAPI application with all business logic, AI features, and API endpoints.

### `/docs` - Documentation
All documentation files including setup guides, troubleshooting, and examples.

### `/data` - Data Files
- OCR test data
- Training examples
- Generated reports (gitignored for generated files)

### `/scripts` - Utility Scripts
Shell scripts and Python utilities for setup, testing, and maintenance tasks.

### `/tools` - Development Tools
Python scripts for data processing, training, and development workflows.

### `/tests` - Test Suite
Unit tests, integration tests, and demo scripts.

### `/prompts` - System Prompts
LLM system prompts and instruction templates used by the application.

## 🚀 Quick Access

- **Start here:** [docs/HOW_TO_RUN_AND_TEST.md](HOW_TO_RUN_AND_TEST.md)
- **Troubleshooting:** [docs/TIMEOUT_FIX.md](TIMEOUT_FIX.md)
- **Setup script:** [scripts/setup_ollama.sh](../scripts/setup_ollama.sh)
- **Run tests:** [tests/test_simple.py](../tests/test_simple.py)
- **Main server:** [app/main_ollama.py](../app/main_ollama.py)

## 📝 Notes

- `venv/` directory contains Python virtual environment (not tracked in git)
- `__pycache__/` directories contain Python bytecode (auto-generated)
- `.gitignore` in `data/reports/` prevents generated reports from being committed
- All paths in scripts and code have been verified to work with new structure
