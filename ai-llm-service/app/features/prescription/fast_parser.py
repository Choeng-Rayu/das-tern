"""
Fast Rule-Based Prescription Parser
Extracts prescription data using regex patterns - no LLM required
Designed for fast, reliable extraction when LLM is slow or unavailable
"""

import re
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class FastPrescriptionParser:
    """Fast rule-based prescription parser using regex patterns"""
    
    def __init__(self):
        # Common medication patterns
        self.medication_patterns = [
            # Pattern: Drug Name Dosage Frequency
            r'(?P<name>[A-Za-z\u1780-\u17FF]+(?:\s+[A-Za-z\u1780-\u17FF]+)?)\s*'
            r'(?P<dosage>\d+(?:\.\d+)?\s*(?:mg|ml|g|mcg|iu|%)?)\s*'
            r'(?P<frequency>(?:\d+x|\d+\s*fois|BID|TID|QID|QD|prn|bid|tid|qid|qd|OD|[១២៣])?)',
            
            # Khmer medicine pattern
            r'(?P<name>[\u1780-\u17FF]+(?:\s+[\u1780-\u17FF]+)*)\s*'
            r'(?P<dosage>\d+)\s*(?:គ្រាប់|ថ្នាំ|ml)?',
        ]
        
        # Common time/frequency patterns
        self.frequency_map = {
            'bid': 'twice daily',
            '2x': 'twice daily', 
            'tid': 'three times daily',
            '3x': 'three times daily',
            'qid': 'four times daily',
            '4x': 'four times daily',
            'qd': 'once daily',
            'od': 'once daily',
            '1x': 'once daily',
            'prn': 'as needed',
            'matin': 'morning',
            'soir': 'evening',
            'midi': 'noon',
            'jour': 'daily',
            '១ថ្ងៃ': 'once daily',
            '២ដង': 'twice daily',
            '៣ដង': 'three times daily',
        }
        
        # Patient info patterns
        self.patient_patterns = {
            'name': [
                r'(?:patient|nom|ឈ្មោះ|នាម)[:\s]*([A-Za-z\u1780-\u17FF\s]+)',
                r'(?:mr\.|mrs\.|mme\.?|m\.)\s+([A-Za-z\s]+)',
            ],
            'age': [
                r'(?:age|âge|អាយុ)[:\s]*(\d+)',
                r'(\d+)\s*(?:ans|years|ឆ្នាំ)',
            ],
            'gender': [
                r'(?:sex|genre|ភេទ)[:\s]*(male|female|homme|femme|ប្រុស|ស្រី|m|f)',
            ],
            'dob': [
                r'(?:dob|naissance|កើត)[:\s]*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
            ],
        }
        
        # Common medication names (for detection)
        self.known_medications = [
            'paracetamol', 'amoxicillin', 'ibuprofen', 'omeprazole', 
            'metformin', 'amlodipine', 'atorvastatin', 'aspirin',
            'ciprofloxacin', 'azithromycin', 'cetirizine', 'loratadine',
            'metronidazole', 'vitamin', 'calcium', 'iron', 'zinc',
            'paracétamol', 'doliprane', 'efferalgan', 'dafalgan',
        ]
    
    def parse(self, raw_text: str) -> Dict[str, Any]:
        """
        Parse prescription text using rules and patterns
        
        Returns structured JSON matching the expected output format
        """
        logger.info(f"Fast parser processing {len(raw_text)} chars")
        
        try:
            # Clean text
            text = self._clean_text(raw_text)
            
            # Extract components
            patient_info = self._extract_patient_info(text)
            medications = self._normalize_medications(self._extract_medications(text))
            daily_reminders = self._generate_reminders(medications)
            
            result = {
                "patient_info": patient_info,
                "medical_info": {},  # Empty medical_info for now
                "medications": medications,
                "daily_reminders": daily_reminders,
                "summary": self._generate_summary(patient_info, medications),
                "confidence_score": self._calculate_confidence(patient_info, medications),
                "language_detected": self._detect_language(text),
                "warnings": self._extract_warnings(text),
                "extraction_method": "fast_rule_based",
                "raw_text": raw_text[:500]
            }
            
            logger.info(f"Fast parser extracted {len(medications)} medications")
            return result
            
        except Exception as e:
            logger.error(f"Fast parser error: {e}")
            return self._empty_result(raw_text, str(e))

    def _normalize_medications(self, medications: Any) -> List[Dict[str, Any]]:
        """Normalize medications list to ensure dict entries with proper schedule format"""
        if not isinstance(medications, list):
            return []

        normalized: List[Dict[str, Any]] = []
        for med in medications:
            if isinstance(med, dict):
                schedule = med.get("schedule")
                if not isinstance(schedule, dict):
                    # Infer a safe default schedule if missing or invalid
                    med = {**med}
                    med["schedule"] = self._infer_schedule(med.get("frequency", ""), med.get("instructions", ""))
                normalized.append(med)
                continue

            if isinstance(med, str):
                parsed = self._parse_medication_line(med)
                if parsed:
                    normalized.append(parsed)

        return normalized
    
    def _clean_text(self, text: str) -> str:
        """Clean and normalize text"""
        # Remove extra whitespace but preserve line breaks
        lines = text.split('\n')
        cleaned_lines = [re.sub(r'[ \t]+', ' ', line).strip() for line in lines]
        # Remove empty lines
        cleaned_lines = [line for line in cleaned_lines if line]
        return '\n'.join(cleaned_lines)
    
    def _extract_patient_info(self, text: str) -> Dict[str, Optional[str]]:
        """Extract patient information"""
        info = {
            "name": None,
            "age": None,
            "gender": None,
            "dob": None
        }
        
        text_lower = text.lower()
        
        # Try each pattern for each field
        for field, patterns in self.patient_patterns.items():
            for pattern in patterns:
                match = re.search(pattern, text_lower if field != 'name' else text, re.IGNORECASE)
                if match:
                    value = match.group(1).strip()
                    if field == 'age':
                        info[field] = int(value) if value.isdigit() else value
                    else:
                        info[field] = value
                    break
        
        return info
    
    def _extract_medications(self, text: str) -> List[Dict[str, Any]]:
        """Extract medication information"""
        medications = []
        lines = text.split('\n')
        
        # Also split by common separators
        all_lines = []
        for line in lines:
            all_lines.extend(re.split(r'[;،]', line))
        
        logger.debug(f"Processing {len(all_lines)} lines for medications")
        
        for line in all_lines:
            line = line.strip()
            if not line or len(line) < 3:
                continue
            
            # Check if line contains medication-like content
            med = self._parse_medication_line(line)
            if med and med.get('name'):
                logger.debug(f"Found medication: {med['name']} from line: {line[:50]}")
                medications.append(med)
        
        logger.debug(f"Total medications extracted: {len(medications)}")
        
        # If no medications found, try harder
        if not medications:
            medications = self._extract_medications_fallback(text)
        
        return medications
    
    def _parse_medication_line(self, line: str) -> Optional[Dict[str, Any]]:
        """Parse a single line for medication info"""
        # Check for known medications
        line_lower = line.lower()
        
        for med_name in self.known_medications:
            if med_name in line_lower:
                return self._build_medication(
                    name=self._extract_proper_name(line, med_name),
                    line=line
                )
        
        # Try regex patterns
        for pattern in self.medication_patterns:
            match = re.search(pattern, line, re.IGNORECASE)
            if match:
                groups = match.groupdict()
                if groups.get('name') and len(groups['name']) > 2:
                    return self._build_medication(
                        name=groups.get('name', '').strip(),
                        dosage=groups.get('dosage', ''),
                        frequency=groups.get('frequency', ''),
                        line=line
                    )
        
        # Check for dosage patterns (might indicate medication)
        dosage_match = re.search(r'(\d+(?:\.\d+)?)\s*(mg|ml|g|mcg|tablets?|គ្រាប់)', line, re.IGNORECASE)
        if dosage_match:
            # Get words before dosage as potential medication name
            words = line[:dosage_match.start()].strip().split()
            if words:
                return self._build_medication(
                    name=' '.join(words[-2:]) if len(words) > 1 else words[-1],
                    dosage=dosage_match.group(0),
                    line=line
                )
        
        return None
    
    def _extract_proper_name(self, line: str, known_name: str) -> str:
        """Extract proper medication name from line"""
        # Find the actual case in the original line
        idx = line.lower().find(known_name)
        if idx >= 0:
            # Look for word boundaries
            start = idx
            end = idx + len(known_name)
            
            # Extend to include brand name or full name
            words = line[max(0, idx-20):min(len(line), end+20)].split()
            for word in words:
                if known_name in word.lower():
                    return word.strip('.,;:')
        
        return known_name.title()
    
    def _build_medication(self, name: str, line: str = '', dosage: str = '', frequency: str = '') -> Dict:
        """Build medication dictionary"""
        # Extract or infer dosage
        if not dosage:
            dose_match = re.search(r'(\d+(?:\.\d+)?)\s*(mg|ml|g|mcg|iu|%|គ្រាប់)', line, re.IGNORECASE)
            if dose_match:
                dosage = dose_match.group(0)
        
        # Extract or infer frequency
        if not frequency:
            for pattern, meaning in self.frequency_map.items():
                if pattern in line.lower():
                    frequency = meaning
                    break
            if not frequency:
                freq_match = re.search(r'(\d+)\s*(?:x|fois|ដង|times)', line, re.IGNORECASE)
                if freq_match:
                    n = int(freq_match.group(1))
                    frequency = f"{n} times daily"
        
        # Default schedule based on frequency
        schedule = self._infer_schedule(frequency, line)
        
        # Extract duration in days
        duration_str = self._extract_duration(line)
        duration_days = self._parse_duration_to_days(duration_str)
        
        # Extract quantity (number of tablets/doses)
        quantity = self._extract_quantity(line)
        
        return {
            "name": name.strip(),
            "dosage": dosage.strip() if dosage else "as prescribed",
            "frequency": frequency if frequency else "as directed",
            "duration": duration_str,
            "duration_days": duration_days,
            "quantity": quantity,
            "instructions": self._extract_instructions(line),
            "schedule": schedule,
            "unit": "tablet"  # Default unit
        }
    
    def _infer_schedule(self, frequency: str, line: str) -> Dict:
        """Infer medication schedule from frequency - returns format expected by reminder_generator"""
        freq_lower = frequency.lower() if frequency else ''
        
        # Map frequency to time slots
        schedules = {
            'once daily': {"times": ["morning"], "times_24h": ["08:00"]},
            'twice daily': {"times": ["morning", "evening"], "times_24h": ["08:00", "20:00"]},
            'three times daily': {"times": ["morning", "afternoon", "evening"], "times_24h": ["08:00", "14:00", "20:00"]},
            'four times daily': {"times": ["morning", "noon", "evening", "night"], "times_24h": ["06:00", "12:00", "18:00", "22:00"]},
            'morning': {"times": ["morning"], "times_24h": ["08:00"]},
            'evening': {"times": ["evening"], "times_24h": ["20:00"]},
            'night': {"times": ["night"], "times_24h": ["21:00"]},
            'as needed': {"times": ["as needed"], "times_24h": ["08:00"]},
        }
        
        for key, schedule in schedules.items():
            if key in freq_lower:
                return schedule
        
        # Default to once daily
        return {"times": ["morning"], "times_24h": ["08:00"]}
    
    def _extract_duration(self, line: str) -> str:
        """Extract treatment duration from line"""
        patterns = [
            r'(\d+)\s*(?:days?|jours?|ថ្ងៃ)',
            r'(\d+)\s*(?:weeks?|semaines?|សប្ដាហ៍)',
            r'(\d+)\s*(?:months?|mois|ខែ)',
            r'(?:pendant|for|ក្នុង)\s*(\d+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, line, re.IGNORECASE)
            if match:
                num = match.group(1)
                if 'week' in line.lower() or 'semaine' in line.lower():
                    return f"{num} weeks"
                elif 'month' in line.lower() or 'mois' in line.lower():
                    return f"{num} months"
                else:
                    return f"{num} days"
        
        return "as prescribed"
    
    def _parse_duration_to_days(self, duration_str: str) -> Optional[int]:
        """Parse duration string to number of days"""
        if not duration_str or duration_str == "as prescribed":
            return 7  # Default 7 days
        
        # Extract number
        match = re.search(r'(\d+)', duration_str)
        if not match:
            return 7
        
        num = int(match.group(1))
        
        # Convert to days based on unit
        if 'week' in duration_str.lower():
            return num * 7
        elif 'month' in duration_str.lower():
            return num * 30
        else:  # Assume days
            return num
    
    def _extract_quantity(self, line: str) -> int:
        """Extract quantity (number of tablets/doses)"""
        # Look for quantity patterns
        patterns = [
            r'(\d+)\s*(?:tablets?|pills?|comprimés?|គ្រាប់)',
            r'(?:qty|quantity|quantité|ចំនួន)[:\s]*(\d+)',
            r'#\s*(\d+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, line, re.IGNORECASE)
            if match:
                return int(match.group(1))
        
        return 30  # Default to 30 doses
    
    def _extract_instructions(self, line: str) -> str:
        """Extract special instructions"""
        instructions = []
        
        # Common instruction patterns
        patterns = [
            (r'with\s+food|avec\s+repas|ជាមួយអាហារ', 'Take with food'),
            (r'before\s+meal|avant\s+repas|មុនអាហារ', 'Take before meals'),
            (r'after\s+meal|après\s+repas|ក្រោយអាហារ', 'Take after meals'),
            (r'empty\s+stomach|à\s+jeun', 'Take on empty stomach'),
            (r'with\s+water|avec\s+eau', 'Take with plenty of water'),
            (r'avoid\s+alcohol|éviter\s+alcool', 'Avoid alcohol'),
        ]
        
        for pattern, instruction in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                instructions.append(instruction)
        
        return '; '.join(instructions) if instructions else ''
    
    def _extract_medications_fallback(self, text: str) -> List[Dict]:
        """Fallback medication extraction"""
        medications = []
        
        # Look for any word followed by mg/ml
        pattern = r'([A-Za-z\u1780-\u17FF]+(?:\s+[A-Za-z\u1780-\u17FF]+)?)\s*(\d+\s*(?:mg|ml|g))'
        for match in re.finditer(pattern, text, re.IGNORECASE):
            name = match.group(1).strip()
            dosage = match.group(2).strip()
            
            # Skip common non-medication words
            skip_words = ['patient', 'age', 'date', 'doctor', 'hospital', 'clinic']
            if name.lower() not in skip_words:
                medications.append(self._build_medication(name=name, dosage=dosage, line=text))
        
        return medications
    
    def _generate_reminders(self, medications: List[Dict]) -> List[Dict]:
        """Generate daily reminder schedule from medications"""
        reminders_by_time = {}
        
        for med in medications:
            schedule = med.get('schedule', {})
            times = schedule.get('times', [])
            times_24h = schedule.get('times_24h', [])
            
            # Use times_24h for scheduling
            for i, time_24h in enumerate(times_24h):
                time_slot_name = times[i] if i < len(times) else 'unknown'
                
                if time_24h not in reminders_by_time:
                    reminders_by_time[time_24h] = {
                        "time": time_24h,
                        "time_slot": time_slot_name,
                        "medications": [],
                        "note": ""
                    }
                
                reminders_by_time[time_24h]["medications"].append({
                    "name": med.get('name'),
                    "dosage": med.get('dosage'),
                    "instructions": med.get('instructions', '')
                })
        
        # Sort by time and convert to list
        reminders = []
        for time in sorted(reminders_by_time.keys()):
            reminder = reminders_by_time[time]
            reminder["note"] = f"Take {len(reminder['medications'])} medication(s)"
            reminders.append(reminder)
        
        return reminders
    
    def _generate_summary(self, patient_info: Dict, medications: List) -> str:
        """Generate prescription summary"""
        parts = []
        
        if patient_info.get('name'):
            parts.append(f"Patient: {patient_info['name']}")
        
        if medications:
            med_names = [m.get('name', 'Unknown') for m in medications]
            parts.append(f"Medications: {', '.join(med_names)}")
            parts.append(f"Total medications: {len(medications)}")
        
        if not parts:
            parts.append("Prescription processed - details may need verification")
        
        return '. '.join(parts)
    
    def _calculate_confidence(self, patient_info: Dict, medications: List) -> float:
        """Calculate extraction confidence score"""
        score = 0.0
        
        # Patient info adds confidence
        if patient_info.get('name'):
            score += 0.2
        if patient_info.get('age'):
            score += 0.1
        
        # Medications add confidence
        if medications:
            score += min(0.5, len(medications) * 0.1)
            
            # Check medication quality
            for med in medications:
                if med.get('dosage') and med.get('dosage') != 'as prescribed':
                    score += 0.05
                if med.get('frequency') and med.get('frequency') != 'as directed':
                    score += 0.05
        
        return min(1.0, score)
    
    def _detect_language(self, text: str) -> str:
        """Detect primary language of text"""
        khmer_chars = len(re.findall(r'[\u1780-\u17FF]', text))
        french_words = len(re.findall(r'\b(le|la|les|de|du|des|et|ou|avec|pour|dans)\b', text, re.IGNORECASE))
        
        if khmer_chars > 10:
            return "km"  # Khmer
        elif french_words > 3:
            return "fr"  # French
        else:
            return "en"  # English default
    
    def _extract_warnings(self, text: str) -> List[str]:
        """Extract any warnings or precautions"""
        warnings = []
        
        patterns = [
            (r'allerg', 'Check for allergies'),
            (r'pregnant|enceinte|ផ្ទៃពោះ', 'Verify pregnancy status'),
            (r'interact', 'Check drug interactions'),
            (r'contre.?indiq', 'Check contraindications'),
        ]
        
        for pattern, warning in patterns:
            if re.search(pattern, text, re.IGNORECASE):
                warnings.append(warning)
        
        return warnings
    
    def _empty_result(self, raw_text: str, error: str) -> Dict[str, Any]:
        """Return empty result structure"""
        return {
            "patient_info": {"name": None, "age": None, "gender": None, "dob": None},
            "medical_info": {},  # Empty medical_info
            "medications": [],
            "daily_reminders": [],
            "summary": f"Could not parse prescription: {error}",
            "confidence_score": 0.0,
            "language_detected": "unknown",
            "warnings": ["Manual review required"],
            "extraction_method": "fast_rule_based",
            "raw_text": raw_text[:500]
        }

