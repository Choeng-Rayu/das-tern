"""
Reminder Engine - Extracts medication reminders from OCR data using LLaMA via Ollama

This module implements the AI-only flow:
RAW OCR JSON → Normalization Prompt → LLaMA 8B → Strict JSON Output → Reminder Engine

Enhanced with comprehensive logging for debugging the OCR-to-AI flow.
"""
import json
import re
import time
from typing import Dict, List, Optional, Any

try:
    from ..core.logging_config import get_logger, truncate_for_log
except ImportError:
    import logging
    def get_logger(name): return logging.getLogger(name)
    def truncate_for_log(data, max_length=200):
        return data[:max_length] + "..." if len(data) > max_length else data

from ..schemas import ReminderRequest, ReminderResponse, MedicationInfo
from ..prompts.reminder_prompts import build_reminder_extraction_prompt, REMINDER_SYSTEM_PROMPT

logger = get_logger(__name__)


class ReminderEngine:
    """
    Engine for extracting medication reminders from raw OCR data.
    
    Uses LLaMA via Ollama to interpret Khmer/English/French medical prescriptions
    and output structured reminder JSON.
    """
    
    # Valid time values
    VALID_TIMES = {"morning", "noon", "evening", "night"}
    VALID_24H = {"08:00", "12:00", "18:00", "21:00"}
    
    # Time mapping for validation
    TIME_TO_24H = {
        "morning": "08:00",
        "noon": "12:00", 
        "evening": "18:00",
        "night": "21:00"
    }
    
    def __init__(self, ollama_client, model: str = "llama3.1:8b"):
        """
        Initialize ReminderEngine.
        
        Args:
            ollama_client: OllamaClient instance for API calls
            model: Ollama model to use (default: llama3.2:3b for faster processing)
                   Use llama3.1:8b for better accuracy on complex prescriptions
        """
        self.ollama_client = ollama_client
        self.model = model
        self.max_retries = 2
        logger.info(f"ReminderEngine initialized with model: {model}, timeout: {getattr(ollama_client, 'timeout', 300)}s")
    
    def extract_reminders(self, request: ReminderRequest) -> ReminderResponse:
        """
        Extract medication reminders from raw OCR JSON.
        
        Args:
            request: ReminderRequest with raw_ocr_json
            
        Returns:
            ReminderResponse with medications list
        """
        start_time = time.time()
        logger.info("[REMINDER-START] Beginning reminder extraction from OCR data")
        
        try:
            # Get raw OCR data
            raw_ocr = request.raw_ocr_json
            logger.debug(f"[REMINDER-INPUT] OCR data type: {type(raw_ocr).__name__}")
            
            # Convert to JSON string for prompt
            if isinstance(raw_ocr, dict):
                # Reduce size by removing unnecessary fields
                simplified_ocr = self._simplify_ocr_data(raw_ocr)
                raw_ocr_str = json.dumps(simplified_ocr, ensure_ascii=False, indent=2)
                logger.info(f"[REMINDER-SIMPLIFY] Simplified OCR: {len(str(raw_ocr))} -> {len(raw_ocr_str)} chars")
            else:
                raw_ocr_str = str(raw_ocr)
            
            # Truncate if too large (reduced from 3000 to 2000 for faster processing)
            if len(raw_ocr_str) > 2000:
                logger.warning(f"[REMINDER-TRUNCATE] OCR data too large ({len(raw_ocr_str)} chars), truncating to 2000")
                raw_ocr_str = raw_ocr_str[:2000] + "\n... (truncated)"
            
            logger.debug(f"[REMINDER-OCR-PREVIEW] {truncate_for_log(raw_ocr_str, 300)}")
            
            # Build prompts
            prompts = build_reminder_extraction_prompt(raw_ocr_str)
            
            # Call Ollama with retries
            response_text = None
            last_error = None
            
            for attempt in range(self.max_retries):
                try:
                    response_text = self._call_ollama(
                        system_prompt=prompts["system"],
                        user_prompt=prompts["user"]
                    )
                    
                    # Try to parse response
                    medications = self._parse_response(response_text)
                    
                    # Validate structure (STEP 7)
                    validated_meds = self._validate_medications(medications)
                    
                    if validated_meds:
                        logger.info(f"Successfully extracted {len(validated_meds)} medications")
                        return ReminderResponse(
                            medications=validated_meds,
                            success=True,
                            error=None,
                            metadata={
                                "model": self.model,
                                "attempts": attempt + 1,
                                "raw_response": response_text[:500] if response_text else None
                            }
                        )
                    else:
                        logger.warning(f"Attempt {attempt + 1}: No valid medications found, retrying...")
                        last_error = "No valid medications extracted"
                        
                except json.JSONDecodeError as e:
                    logger.warning(f"Attempt {attempt + 1}: JSON parse error: {e}")
                    last_error = f"JSON parse error: {str(e)}"
                except Exception as e:
                    logger.warning(f"Attempt {attempt + 1}: Error: {e}")
                    last_error = str(e)
            
            # All retries failed
            logger.error(f"Failed after {self.max_retries} attempts: {last_error}")
            return ReminderResponse(
                medications=[],
                success=False,
                error=f"Extraction failed: {last_error}",
                metadata={
                    "model": self.model,
                    "attempts": self.max_retries,
                    "raw_response": response_text[:500] if response_text else None
                }
            )
            
        except Exception as e:
            logger.error(f"ReminderEngine error: {e}")
            return ReminderResponse(
                medications=[],
                success=False,
                error=str(e),
                metadata={"model": self.model}
            )
    
    def _simplify_ocr_data(self, ocr_data: Dict) -> Dict:
        """
        Simplify OCR data to reduce prompt size and processing time.
        Keep only essential fields: raw_text, blocks with text, remove bounding boxes.
        """
        simplified = {}
        
        # Keep raw_text if present
        if "raw_text" in ocr_data:
            simplified["raw_text"] = ocr_data["raw_text"]
        
        # Simplify blocks - keep only text content
        if "blocks" in ocr_data and isinstance(ocr_data["blocks"], list):
            simplified_blocks = []
            for block in ocr_data["blocks"]:
                if isinstance(block, dict):
                    block_text = []
                    if "lines" in block:
                        for line in block["lines"]:
                            if isinstance(line, dict) and "text" in line:
                                block_text.append(line["text"])
                    if block_text:
                        simplified_blocks.append({"text": " ".join(block_text)})
            if simplified_blocks:
                simplified["blocks"] = simplified_blocks
        
        # Keep meta if present (but remove stage_times)
        if "meta" in ocr_data:
            meta = ocr_data["meta"].copy() if isinstance(ocr_data["meta"], dict) else {}
            meta.pop("stage_times", None)
            simplified["meta"] = meta
        
        return simplified if simplified else ocr_data
    
    def _call_ollama(self, system_prompt: str, user_prompt: str) -> str:
        """
        Call Ollama API with proper settings for reminder extraction.
        Optimized for 10-20s response time with reduced context and prediction limits.
        """
        logger.info(f"[REMINDER-OLLAMA] Calling Ollama with model: {self.model}")
        
        # Build the combined prompt for Ollama
        combined_prompt = f"""{system_prompt}

{user_prompt}"""
        
        prompt_len = len(combined_prompt)
        logger.debug(f"[REMINDER-PROMPT-SIZE] {prompt_len} chars (system: {len(system_prompt)}, user: {len(user_prompt)})")
        
        # Optimized options for faster response (10-20s target)
        # Reduced num_ctx: 2048 -> 1024, num_predict: 500 -> 300
        payload = {
            "model": self.model,
            "prompt": combined_prompt,
            "stream": False,
            "options": {
                "temperature": 0.2,
                "top_p": 0.9,
                "num_ctx": 1024,     # Reduced from 2048 for faster processing
                "num_predict": 300   # Reduced from 500 for shorter responses
            }
        }
        
        response = self.ollama_client.generate_response(payload)
        logger.info(f"[REMINDER-OLLAMA-DONE] Response length: {len(response)} chars")
        logger.debug(f"[REMINDER-RESPONSE-PREVIEW] {truncate_for_log(response, 300)}")
        return response
    
    def _parse_response(self, response_text: str) -> List[Dict[str, Any]]:
        """
        Parse LLM response to extract medications JSON.
        
        Handles various response formats:
        - Clean JSON
        - JSON wrapped in markdown code blocks
        - JSON with extra text before/after
        """
        if not response_text:
            return []
        
        # Clean the response
        text = response_text.strip()
        
        # Remove markdown code blocks if present
        if "```json" in text:
            match = re.search(r'```json\s*(.*?)\s*```', text, re.DOTALL)
            if match:
                text = match.group(1)
        elif "```" in text:
            match = re.search(r'```\s*(.*?)\s*```', text, re.DOTALL)
            if match:
                text = match.group(1)
        
        # Try to find JSON object
        json_match = re.search(r'\{[\s\S]*\}', text)
        if json_match:
            text = json_match.group(0)
        
        # Parse JSON
        data = json.loads(text)
        
        # Extract medications array
        if isinstance(data, dict):
            medications = data.get("medications", [])
        elif isinstance(data, list):
            medications = data
        else:
            medications = []
        
        return medications
    
    def _validate_medications(self, medications: List[Dict[str, Any]]) -> List[MedicationInfo]:
        """
        Validate and sanitize medication data.
        
        STEP 7: Reject response if:
        - times empty
        - times_24h mismatch length
        - Invalid time values
        """
        validated = []
        
        for med in medications:
            try:
                name = med.get("name", "").strip()
                if not name:
                    logger.warning("Skipping medication with empty name")
                    continue
                
                times = med.get("times", [])
                times_24h = med.get("times_24h", [])
                
                # Skip if no times (STEP 2: If no time word → do not generate reminder)
                if not times:
                    logger.warning(f"Skipping {name}: no times specified")
                    continue
                
                # Validate times are from allowed set
                valid_times = []
                valid_24h = []
                for t in times:
                    t_lower = t.lower().strip()
                    if t_lower in self.VALID_TIMES:
                        valid_times.append(t_lower)
                        valid_24h.append(self.TIME_TO_24H[t_lower])
                
                if not valid_times:
                    logger.warning(f"Skipping {name}: no valid times after filtering")
                    continue
                
                # Build validated medication
                # Handle case where repeat is explicitly set to null
                repeat_value = med.get("repeat", "daily")
                if repeat_value is None:
                    repeat_value = "daily"
                
                validated_med = MedicationInfo(
                    name=name,
                    dosage=med.get("dosage", ""),
                    times=valid_times,
                    times_24h=valid_24h,
                    repeat=repeat_value,
                    duration_days=med.get("duration_days"),
                    notes=med.get("notes", "")
                )
                
                validated.append(validated_med)
                logger.debug(f"Validated medication: {name} at {valid_times}")
                
            except Exception as e:
                logger.warning(f"Error validating medication: {e}")
                continue
        
        return validated


# ============================================================
# Utility functions for direct use
# ============================================================

def extract_reminders_from_ocr(
    raw_ocr_data: Dict[str, Any],
    ollama_client,
    model: str = "llama3.1:8b"
) -> ReminderResponse:
    """
    Convenience function to extract reminders from OCR data.
    
    Args:
        raw_ocr_data: Raw OCR output as dictionary
        ollama_client: OllamaClient instance
        model: Ollama model to use
        
    Returns:
        ReminderResponse with extracted medications
    """
    engine = ReminderEngine(ollama_client, model=model)
    request = ReminderRequest(raw_ocr_json=raw_ocr_data)
    return engine.extract_reminders(request)
