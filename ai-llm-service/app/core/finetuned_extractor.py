"""
Fine-tuned Medical Extractor Client
Uses dastern-medical-extractor model for prescription keyword extraction
"""
import json
import logging
from typing import Dict, List, Optional
from fastapi import HTTPException
from app.core.ollama_client import OllamaClient

logger = logging.getLogger(__name__)


class FinetunedMedicalExtractor:
    """
    Client for fine-tuned DasTern medical extraction model
    Specialized in extracting prescription keywords
    """
    
    def __init__(self, model: str = "dastern-medical-extractor"):
        self.client = OllamaClient()
        self.model = model
        
        logger.info(f"FinetunedMedicalExtractor initialized with fine-tuned model: {self.model}")
    
    def extract_full_prescription(
        self, 
        ocr_text: str
    ) -> Dict:
        """
        Extract complete prescription data using fine-tuned model
        
        Args:
            ocr_text: Raw OCR text from prescription
            
        Returns:
            Dictionary with extracted prescription data
        """
        prompt = self._create_extraction_prompt(ocr_text)
        
        try:
            logger.info(f"Extracting prescription with fine-tuned model: {self.model}")
            
            # Use the synchronous generate_response method
            payload = {
                "model": self.model,
                "prompt": prompt,
                "options": {
                    "temperature": 0.1,
                    "top_p": 0.9
                }
            }
            
            response = self.client.generate_response(payload)
            
            # Parse JSON response
            extracted = self._parse_response(response)
            
            # Validate extracted data
            validated = self._validate_extraction(extracted)
            
            logger.info(f"✅ Extraction successful. Found {len(validated.get('medications', []))} medications")
            
            return validated
            
        except Exception as e:
            logger.error(f"❌ Extraction failed: {e}")
            raise
    
    async def extract_medications_only(self, ocr_text: str) -> List[Dict]:
        """
        Extract only medication information
        """
        prompt = f"""Extract ONLY medications from this prescription text:

{ocr_text}

Return JSON array of medications with: medication_name, strength, dosage, frequency, duration.
"""
        
        try:
            response = await self.client.generate(
                model=self.model,
                prompt=prompt,
                temperature=0.1
            )
            
            result = self._parse_response(response)
            return result.get('medications', [])
            
        except Exception as e:
            logger.error(f"Medication extraction failed: {e}")
            return []
    
    async def extract_diagnosis(self, ocr_text: str) -> List[str]:
        """
        Extract diagnosis using fine-tuned model
        """
        prompt = f"""Extract ONLY the medical diagnoses from this prescription:

{ocr_text}

Return JSON: {{"diagnosis": ["Diagnosis 1", "Diagnosis 2"]}}
Look for numbered lists or "Diagnosis:" sections.
"""
        
        try:
            response = await self.client.generate(
                model=self.model,
                prompt=prompt,
                temperature=0.1
            )
            
            result = self._parse_response(response)
            diagnosis = result.get('diagnosis', [])
            
            # Clean up diagnosis list
            return [d.strip() for d in diagnosis if d and len(d.strip()) > 2]
            
        except Exception as e:
            logger.error(f"Diagnosis extraction failed: {e}")
            return []
    
    async def extract_prescriber_info(self, ocr_text: str) -> Dict:
        """
        Extract prescriber information
        """
        prompt = f"""Extract prescriber information from this prescription:

{ocr_text}

Return JSON: {{
  "prescriber_name": "Dr. Name",
  "prescriber_facility": "Hospital Name",
  "prescriber_contact": "Phone or null"
}}
"""
        
        try:
            response = await self.client.generate(
                model=self.model,
                prompt=prompt,
                temperature=0.1
            )
            
            result = self._parse_response(response)
            
            return {
                "prescriber_name": result.get('prescriber_name'),
                "prescriber_facility": result.get('prescriber_facility'),
                "prescriber_contact": result.get('prescriber_contact')
            }
            
        except Exception as e:
            logger.error(f"Prescriber extraction failed: {e}")
            return {
                "prescriber_name": None,
                "prescriber_facility": None,
                "prescriber_contact": None
            }
    
    def _create_extraction_prompt(self, ocr_text: str) -> str:
        """
        Create optimized prompt for full extraction
        """
        return f"""Extract complete prescription data from this OCR text:

{ocr_text}

Return structured JSON with:
- medications (array with full details)
- diagnosis (array of conditions)
- prescriber_name
- prescriber_facility
- prescription_date
- language_detected

Remember to:
1. Fix OCR errors (1→l, 0→O, etc.)
2. Extract duration information
3. Include Khmer instructions if present
4. Return valid JSON only
"""
    
    def _parse_response(self, response: str) -> Dict:
        """
        Parse JSON response from model
        """
        # Remove markdown code blocks if present
        response = response.strip()
        if response.startswith('```'):
            # Remove ```json or ``` at start
            response = response.split('\n', 1)[1] if '\n' in response else response[3:]
        if response.endswith('```'):
            response = response.rsplit('\n', 1)[0] if '\n' in response else response[:-3]
        
        response = response.strip()
        
        try:
            return json.loads(response)
        except json.JSONDecodeError as e:
            logger.warning(f"JSON parse error: {e}")
            logger.warning(f"Response was: {response[:200]}")
            
            # Try to extract JSON from text
            import re
            json_match = re.search(r'\{.*\}', response, re.DOTALL)
            if json_match:
                try:
                    return json.loads(json_match.group(0))
                except:
                    pass
            
            # Return minimal valid structure
            return {
                "medications": [],
                "diagnosis": [],
                "prescriber_name": None,
                "prescriber_facility": None,
                "error": "Failed to parse response"
            }
    
    def _validate_extraction(self, extracted: Dict) -> Dict:
        """
        Validate and clean extracted data
        """
        # Ensure required fields exist
        if 'medications' not in extracted:
            extracted['medications'] = []
        
        if 'diagnosis' not in extracted:
            extracted['diagnosis'] = []
        
        # Validate medications
        valid_medications = []
        for med in extracted.get('medications', []):
            if isinstance(med, dict) and med.get('medication_name'):
                # Ensure required medication fields
                validated_med = {
                    'medication_name': med.get('medication_name'),
                    'strength': med.get('strength'),
                    'form': med.get('form', 'tablet'),
                    'dosage': med.get('dosage'),
                    'frequency': med.get('frequency'),
                    'frequency_times': med.get('frequency_times'),
                    'duration': med.get('duration'),
                    'duration_days': med.get('duration_days'),
                    'instructions_english': med.get('instructions_english'),
                    'instructions_khmer': med.get('instructions_khmer')
                }
                valid_medications.append(validated_med)
        
        extracted['medications'] = valid_medications
        
        # Clean diagnosis list
        if isinstance(extracted.get('diagnosis'), list):
            extracted['diagnosis'] = [
                d.strip() for d in extracted['diagnosis'] 
                if d and isinstance(d, str) and len(d.strip()) > 2
            ]
        
        return extracted
