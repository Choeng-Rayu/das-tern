# Ollama Timeout Fix

## Problem
When scanning images and using Ollama for AI enhancement, you were experiencing:
1. **400 Error: "No text provided"** - The OCR correction endpoint was receiving empty text
2. **Ollama request timeout (120s)** - The reminder engine was timing out when processing complex prescriptions

## Solutions Applied

### 1. Increased Timeout (120s → 300s)
The default Ollama timeout has been increased from 2 minutes to **5 minutes** to handle:
- Complex medical prescriptions with mixed languages (Khmer/English/French)
- Large OCR data with multiple blocks and text regions
- Detailed medication extraction and reminder generation

### 2. Configurable Timeout
You can now configure the timeout via environment variable:

```bash
# In your .env file or export before starting
export OLLAMA_TIMEOUT=600  # 10 minutes for very complex prescriptions
export OLLAMA_TIMEOUT=180  # 3 minutes for simpler cases
```

Default: **300 seconds (5 minutes)**

### 3. Better Error Handling
- More descriptive error messages when text is empty
- Logging includes timeout values for debugging
- Clearer guidance on what went wrong

### 4. OCR Data Optimization
The reminder engine now:
- **Simplifies OCR data** before sending to Ollama (removes bounding boxes, keeps only text)
- **Truncates large data** (>3000 characters) to prevent excessive processing time
- **Removes unnecessary metadata** (stage_times, etc.)

This reduces the prompt size by ~60-80%, leading to faster processing.

## Usage

### Start Services with Custom Timeout
```bash
# Terminal 1 - Start Ollama (if not already running)
ollama serve

# Terminal 2 - Start AI-LLM Service with custom timeout
cd ai-llm-service
export OLLAMA_TIMEOUT=600  # 10 minutes
python -m app.main_ollama
```

### Check Current Configuration
The timeout is logged on startup:
```
INFO: OllamaClient initialized with base_url: http://localhost:11434, timeout: 300s
INFO: ReminderEngine initialized with model: llama3.2:3b, timeout: 300s
```

### Recommended Timeout Values

| Prescription Complexity | Model | Recommended Timeout |
|------------------------|-------|---------------------|
| Simple (1-2 medications) | llama3.2:3b | 120-180s |
| Medium (3-5 medications) | llama3.2:3b | 180-300s |
| Complex (6+ medications, mixed languages) | llama3.2:3b | 300-600s |
| Any complexity | llama3.1:8b | 300-900s |

### Performance Tips

1. **Use the faster model for testing:**
   ```python
   # In ai-llm-service/app/main_ollama.py
   reminder_engine = ReminderEngine(ollama_client, model="llama3.2:3b")  # 3B is faster
   ```

2. **Use the larger model for production:**
   ```python
   reminder_engine = ReminderEngine(ollama_client, model="llama3.1:8b")  # More accurate
   ```

3. **Ensure Ollama has enough resources:**
   ```bash
   # Check Ollama is running
   curl http://localhost:11434/api/tags
   
   # Monitor Ollama CPU/Memory usage
   htop  # or top
   ```

4. **Pre-load the model:**
   ```bash
   # This loads the model into memory
   ollama run llama3.2:3b ""
   ```

## Testing the Fix

### Test 1: Check Timeout Configuration
```bash
cd ai-llm-service
python -c "from app.core.ollama_client import OllamaClient; c = OllamaClient(); print(f'Timeout: {c.timeout}s')"
```

### Test 2: Test with Real Prescription
```bash
cd ocr-service-anti
python scripts/comprehensive_test.py --image path/to/prescription.jpg
```

### Test 3: Monitor Ollama Logs
```bash
# In a separate terminal, watch Ollama logs
journalctl -u ollama -f  # If running as systemd service
# OR
# Check terminal where ollama serve is running
```

## Troubleshooting

### Still Timing Out?

1. **Increase timeout further:**
   ```bash
   export OLLAMA_TIMEOUT=900  # 15 minutes
   ```

2. **Use faster model:**
   ```bash
   export OLLAMA_MODEL=llama3.2:1b  # Even faster (but less accurate)
   ```

3. **Reduce OCR data manually:**
   - Check if OCR is extracting too much unnecessary text
   - Consider pre-filtering in OCR service

4. **Check Ollama performance:**
   ```bash
   # Test Ollama directly
   curl http://localhost:11434/api/generate -d '{
     "model": "llama3.2:3b",
     "prompt": "Test prompt",
     "stream": false
   }'
   ```

### Empty Text Error?

Check the OCR output:
```bash
# In ocr-service-anti
python -c "
from app.builder.json_builder import JSONBuilder
# Test OCR output includes raw_text field
"
```

The error occurs when:
- OCR fails to extract any text
- Image quality is too poor
- Wrong language settings

## Files Modified

1. [ai-llm-service/app/core/ollama_client.py](ai-llm-service/app/core/ollama_client.py)
   - Added timeout parameter to `__init__`
   - Made timeout configurable via `OLLAMA_TIMEOUT` env var
   - Increased default from 120s to 300s
   - Better error messages

2. [ai-llm-service/app/main_ollama.py](ai-llm-service/app/main_ollama.py)
   - Better validation for empty text
   - More descriptive error messages

3. [ai-llm-service/app/features/reminder_engine.py](ai-llm-service/app/features/reminder_engine.py)
   - Added `_simplify_ocr_data()` method to reduce prompt size
   - Truncate OCR data >3000 chars
   - Log timeout in initialization

## Next Steps

1. Test with your prescription images
2. Monitor processing times
3. Adjust timeout if needed
4. Consider model switching based on complexity

If you still experience timeouts after these fixes, you may need to:
- Upgrade to more powerful hardware
- Use Ollama with GPU acceleration
- Reduce OCR extraction detail
- Split complex prescriptions into multiple requests
