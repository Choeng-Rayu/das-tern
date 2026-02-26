"""
Simple Prescription Processor
Enhances OCR accuracy and generates clean JSON for mobile app integration
"""

import json
import logging
from typing import Dict, Any, Optional, List
from ...core.ollama_client import OllamaClient

logger = logging.getLogger(__name__)

class PrescriptionProcessor:
    """Process prescription OCR data into structured format for reminders"""
    
    SYSTEM_PROMPT = """You are an expert medical prescription AI for healthcare reminders.

TASK: Extract prescription information for mobile app reminder generation.

LANGUAGE SUPPORT:
- Khmer: ឈ្មោះ (name), អាយុ (age), ភេទ (gender), ថ្ងៃ (day)
- French: matin, soir, nuit, comprimé
- English: morning, evening, night, tablet

TIME NORMALIZATION:
ព្រឹក/matin/morning → ["morning"] → ["08:00"]
ល្ងាច/soir/evening → ["evening"] → ["18:00"]
យប់/nuit/night → ["night"] → ["21:00"]

MEDICATION EXTRACTION:
- Extract ALL medications with dosage and timing
- Parse times: "2x daily", "before meals", "after food"
- Duration: "7 days", "2 weeks"

OUTPUT JSON ONLY:
{
  "patient_info": {"name": "", "id": "", "age": null, "gender": "", "hospital_code": ""},
  "medical_info": {"diagnosis": "", "doctor": "", "date": "", "department": ""},
  "medications": [{"name": "", "dosage": "", "times": [], "times_24h": [], "repeat": "", "duration_days": null, "notes": ""}]
}

RULES: Extract ONLY visible text. Use empty strings for missing data. NO EXPLANATIONS."""

    def __init__(self, ollama_client: OllamaClient):
        self.ollama_client = ollama_client
    
    def process_prescription(self, raw_ocr_json: Dict[str, Any]) -> Dict[str, Any]:
        """Main processing function for prescription data"""
        try:
            # Extract text from OCR data
            raw_text = self._extract_text_from_ocr(raw_ocr_json)
            
            if not raw_text or len(raw_text.strip()) < 10:
                return {
                    "patient_info": {"name": "", "id": "", "age": None, "gender": "", "hospital_code": ""},
                    "medical_info": {"diagnosis": "", "doctor": "", "date": "", "department": ""},
                    "medications": [],
                    "success": False,
                    "error": "No readable text found in OCR data"
                }
            
            # Process with AI
            user_prompt = f"Extract structured data from this prescription:\n\n{raw_text}"
            
            response = self._call_ai(user_prompt)
            parsed_data = self._parse_json_response(response)
            
            if not parsed_data:
                return {
                    "patient_info": {"name": "", "id": "", "age": None, "gender": "", "hospital_code": ""},
                    "medical_info": {"diagnosis": "", "doctor": "", "date": "", "department": ""},
                    "medications": [],
                    "success": False,
                    "error": "Failed to parse AI response"
                }
            
            return {
                **parsed_data,
                "success": True,
                "metadata": {
                    "model": "llama3.2:3b",
                    "raw_text_length": len(raw_text),
                    "language": "mixed_kh_en_fr"
                }
            }
            
        except Exception as e:
            logger.error(f"Prescription processing failed: {str(e)}")
            return {
                "patient_info": {"name": "", "id": "", "age": None, "gender": "", "hospital_code": ""},
                "medical_info": {"diagnosis": "", "doctor": "", "date": "", "department": ""},
                "medications": [],
                "success": False,
                "error": str(e)
            }
    
    def _extract_text_from_ocr(self, ocr_data: Dict[str, Any]) -> str:
        """Extract raw text from various OCR formats"""
        if isinstance(ocr_data, str):
            return ocr_data
        
        # Try common OCR output keys
        for key in ["raw_text", "text", "content", "ocr_text"]:
            if key in ocr_data and ocr_data[key]:
                return str(ocr_data[key])
        
        # Handle structured data
        if "structured_data" in ocr_data:
            structured = ocr_data["structured_data"]
            if isinstance(structured, dict):
                text_parts = []
                for key, value in structured.items():
                    if value:
                        text_parts.append(f"{key}: {value}")
                return "\n".join(text_parts)
        
        return ""
    
    def _call_ai(self, user_prompt: str) -> str:
        """Call AI model for processing"""
        payload = {
            "model": "llama3.1:8b",
            "system": self.SYSTEM_PROMPT,
            "prompt": user_prompt,
            "stream": False,
            "options": {
                "temperature": 0.1,
                "top_p": 0.9,
                "top_k": 40,
                "max_tokens": 500
            }
        }
        
        return self.ollama_client.generate_response(payload)
    
    def _parse_json_response(self, response: str) -> Optional[Dict]:
        """Parse JSON response from AI with robust error handling"""
        try:
            # Clean response
            json_str = response.strip()
            
            # Remove markdown code blocks
            while json_str.startswith("```"):
                json_str = json_str[3:]
                if json_str.startswith("json"):
                    json_str = json_str[4:]
                json_str = json_str.lstrip()
            
            while json_str.endswith("```"):
                json_str = json_str[:-3].rstrip()
            
            # Find JSON object boundaries
            start_idx = json_str.find('{')
            if start_idx == -1:
                logger.warning("No JSON object found in response")
                return None
                
            # Find matching closing brace
            brace_count = 0
            end_idx = start_idx
            for i, char in enumerate(json_str[start_idx:], start_idx):
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        end_idx = i + 1
                        break
            
            if brace_count != 0:
                logger.warning("Incomplete JSON object - unmatched braces")
                return None
            
            # Extract JSON block
            json_block = json_str[start_idx:end_idx]
            
            # Parse and validate structure
            parsed = json.loads(json_block)
            
            # Validate required structure
            if not isinstance(parsed, dict):
                logger.warning("Parsed JSON is not an object")
                return None
                
            # Ensure required top-level keys exist
            required_keys = ['patient_info', 'medical_info', 'medications']
            for key in required_keys:
                if key not in parsed:
                    parsed[key] = {} if key != 'medications' else []
            
            # Validate nested structures
            if not isinstance(parsed.get('medications'), list):
                parsed['medications'] = []
            
            # Ensure medication fields exist
            for med in parsed.get('medications', []):
                if isinstance(med, dict):
                    med.setdefault('name', '')
                    med.setdefault('dosage', '')
                    med.setdefault('times', [])
                    med.setdefault('times_24h', [])
                    med.setdefault('repeat', 'daily')
                    med.setdefault('duration_days', None)
                    med.setdefault('notes', '')
            
            # Ensure patient_info fields
            for key in ['name', 'id', 'gender', 'hospital_code']:
                parsed.setdefault('patient_info', {}).setdefault(key, '')
            parsed.setdefault('patient_info', {}).setdefault('age', None)
            
            # Ensure medical_info fields
            for key in ['diagnosis', 'doctor', 'date', 'department']:
                parsed.setdefault('medical_info', {}).setdefault(key, '')
            
            logger.info("Successfully parsed and validated JSON response")
            return parsed
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            return None
        except Exception as e:
            logger.error(f"JSON parsing failed: {str(e)}")
            return None