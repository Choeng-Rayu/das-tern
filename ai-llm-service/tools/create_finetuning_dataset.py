"""
Create fine-tuning dataset from correction reports
Converts existing OCR corrections into training data for keyword extraction
"""
import json
import re
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional


class FinetuningDatasetCreator:
    """
    Convert correction reports into fine-tuning dataset
    Focus: Extract medications, diagnosis, prescriber info
    """
    
    def __init__(self):
        self.reports_dir = Path("data/reports")
        self.examples_dir = Path("docs/examples")
        self.output_file = Path("data/training/finetuning_dataset.jsonl")
        self.stats = {
            "total_examples": 0,
            "medication_examples": 0,
            "diagnosis_examples": 0,
            "prescriber_examples": 0,
            "duration_examples": 0
        }
    
    def create_dataset(self):
        """
        Main function: Create complete fine-tuning dataset
        """
        print("🎓 Creating Fine-tuning Dataset for DasTern Medical Extractor")
        print("=" * 70)
        
        training_examples = []
        
        # Process all correction reports
        report_files = list(self.reports_dir.glob("correction_*.json"))
        report_files.extend(self.examples_dir.glob("correction_*.json"))
        
        print(f"\n📁 Found {len(report_files)} correction reports")
        
        for report_file in report_files:
            print(f"\n📄 Processing: {report_file.name}")
            with open(report_file, encoding='utf-8') as f:
                report = json.load(f)
            
            examples = self.extract_training_examples(report)
            training_examples.extend(examples)
            print(f"   ✅ Generated {len(examples)} training examples")
        
        # Add synthetic examples for edge cases
        synthetic = self.create_synthetic_examples()
        training_examples.extend(synthetic)
        print(f"\n🔬 Added {len(synthetic)} synthetic examples")
        
        # Save dataset
        self.save_dataset(training_examples)
        
        # Print statistics
        self.print_statistics()
    
    def extract_training_examples(self, report: Dict) -> List[Dict]:
        """
        Extract multiple training examples from one correction report
        """
        examples = []
        
        raw_text = report.get('ocr_input', {}).get('raw_text', '')
        ai_output = report.get('ai_enhanced_output', {})
        
        if not raw_text:
            return examples
        
        # Example Type 1: Full prescription extraction
        full_example = self.create_full_extraction_example(raw_text, ai_output)
        if full_example:
            examples.append(full_example)
            self.stats["total_examples"] += 1
        
        # Example Type 2: Medication-specific extraction
        for med in ai_output.get('medications', []):
            med_example = self.create_medication_example(raw_text, med)
            if med_example:
                examples.append(med_example)
                self.stats["medication_examples"] += 1
                self.stats["total_examples"] += 1
        
        # Example Type 3: Diagnosis extraction
        diagnosis = self.extract_diagnosis_from_raw(raw_text)
        if diagnosis:
            diag_example = self.create_diagnosis_example(raw_text, diagnosis)
            examples.append(diag_example)
            self.stats["diagnosis_examples"] += 1
            self.stats["total_examples"] += 1
        
        # Example Type 4: Prescriber information
        if ai_output.get('prescriber_facility'):
            prescriber_example = self.create_prescriber_example(raw_text, ai_output)
            examples.append(prescriber_example)
            self.stats["prescriber_examples"] += 1
            self.stats["total_examples"] += 1
        
        # Example Type 5: Duration extraction (when found)
        for med in ai_output.get('medications', []):
            if self.has_duration_hint(raw_text):
                duration_example = self.create_duration_example(raw_text, med)
                if duration_example:
                    examples.append(duration_example)
                    self.stats["duration_examples"] += 1
                    self.stats["total_examples"] += 1
        
        return examples
    
    def create_full_extraction_example(self, raw_text: str, ai_output: Dict) -> Optional[Dict]:
        """
        Create example for complete prescription extraction
        """
        diagnosis = self.extract_diagnosis_from_raw(raw_text)
        
        response_data = {
            "medications": ai_output.get('medications', []),
            "diagnosis": diagnosis,
            "prescriber_name": ai_output.get('prescriber_name'),
            "prescriber_facility": ai_output.get('prescriber_facility'),
            "prescription_date": ai_output.get('date'),
            "language_detected": ai_output.get('language_detected', 'en')
        }
        
        return {
            "prompt": f"Extract complete prescription data from this OCR text:\n\n{raw_text}\n\nReturn structured JSON with medications, diagnosis, prescriber info, and date.",
            "response": json.dumps(response_data, ensure_ascii=False)
        }
    
    def create_medication_example(self, raw_text: str, medication: Dict) -> Optional[Dict]:
        """
        Create example for medication extraction
        """
        med_name = medication.get('medication_name', '')
        if not med_name:
            return None
        
        # Find medication context in raw text
        context = self.find_medication_context(raw_text, med_name)
        
        return {
            "prompt": f"Extract medication details from:\n\n{context}\n\nReturn JSON with medication_name, strength, dosage, frequency, form, and instructions.",
            "response": json.dumps(medication, ensure_ascii=False)
        }
    
    def create_diagnosis_example(self, raw_text: str, diagnosis: List[str]) -> Dict:
        """
        Create example for diagnosis extraction
        """
        diagnosis_section = self.find_diagnosis_section(raw_text)
        
        return {
            "prompt": f"Extract all medical diagnoses from:\n\n{diagnosis_section}\n\nReturn JSON array of diagnosis names.",
            "response": json.dumps({"diagnosis": diagnosis}, ensure_ascii=False)
        }
    
    def create_prescriber_example(self, raw_text: str, ai_output: Dict) -> Dict:
        """
        Create example for prescriber information extraction
        """
        prescriber_context = self.find_prescriber_context(raw_text)
        
        response = {
            "prescriber_name": ai_output.get('prescriber_name'),
            "prescriber_facility": ai_output.get('prescriber_facility'),
            "prescriber_contact": ai_output.get('prescriber_contact')
        }
        
        return {
            "prompt": f"Extract prescriber information from:\n\n{prescriber_context}\n\nReturn JSON with prescriber_name and prescriber_facility.",
            "response": json.dumps(response, ensure_ascii=False)
        }
    
    def create_duration_example(self, raw_text: str, medication: Dict) -> Optional[Dict]:
        """
        Create example for duration extraction
        """
        med_context = self.find_medication_context(raw_text, medication.get('medication_name', ''))
        
        # Try to extract duration from context
        duration_info = self.extract_duration_from_text(med_context)
        
        if duration_info['duration']:
            return {
                "prompt": f"Extract medication duration from:\n\n{med_context}\n\nReturn JSON with duration and duration_days.",
                "response": json.dumps(duration_info, ensure_ascii=False)
            }
        
        return None
    
    def extract_diagnosis_from_raw(self, raw_text: str) -> List[str]:
        """
        Extract diagnosis from raw OCR text
        """
        diagnoses = []
        
        # Pattern 1: Numbered diagnoses (e.g., "1. Chronic Cystitis")
        pattern1 = r'\d+\.\s*([A-Z][A-Za-z\s]+(?:itis|osis|emia|pathy|Cystitis|Hypertension|Diabetes|Fever|Infection))'
        matches = re.findall(pattern1, raw_text)
        for match in matches:
            clean = match.strip()
            if len(clean) > 3:
                diagnoses.append(clean)
        
        # Pattern 2: After "Diagnosis:" or "Dx:"
        if re.search(r'diagnosis[:：]|dx[:：]', raw_text, re.IGNORECASE):
            parts = re.split(r'diagnosis[:：]|dx[:：]', raw_text, flags=re.IGNORECASE)
            if len(parts) > 1:
                section = parts[1].split('\n')[0:3]
                for line in section:
                    clean = line.strip()
                    if clean and len(clean) > 3 and not re.match(r'^\d+$', clean):
                        diagnoses.append(clean)
        
        # Remove duplicates and clean
        seen = set()
        cleaned = []
        for d in diagnoses:
            d_clean = re.sub(r'\s+', ' ', d).strip()
            if d_clean.lower() not in seen and len(d_clean) > 3:
                seen.add(d_clean.lower())
                cleaned.append(d_clean)
        
        return cleaned
    
    def find_diagnosis_section(self, raw_text: str) -> str:
        """
        Find diagnosis section in raw text
        """
        lines = raw_text.split('\n')
        diagnosis_lines = []
        
        in_diagnosis = False
        for line in lines:
            # Start of diagnosis section
            if re.match(r'^\d+\.', line) or 'diagnosis' in line.lower():
                in_diagnosis = True
                diagnosis_lines.append(line)
            elif in_diagnosis:
                if line.strip() and not re.match(r'^[A-Z][a-z]+:', line):
                    diagnosis_lines.append(line)
                elif not line.strip() or re.match(r'^[A-Z][a-z]+:', line):
                    break
        
        return '\n'.join(diagnosis_lines) if diagnosis_lines else raw_text[:300]
    
    def find_medication_context(self, raw_text: str, med_name: str) -> str:
        """
        Find context around medication name
        """
        if not med_name:
            return raw_text[:200]
        
        lines = raw_text.split('\n')
        med_prefix = med_name[:4].lower()
        
        for i, line in enumerate(lines):
            if med_prefix in line.lower():
                start = max(0, i - 1)
                end = min(len(lines), i + 4)
                return '\n'.join(lines[start:end])
        
        return raw_text[:200]
    
    def find_prescriber_context(self, raw_text: str) -> str:
        """
        Find prescriber information context
        """
        lines = raw_text.split('\n')
        
        # Look for hospital/clinic names or Dr. pattern
        prescriber_lines = []
        for i, line in enumerate(lines):
            if 'hospital' in line.lower() or 'clinic' in line.lower() or 'dr.' in line.lower():
                start = max(0, i - 2)
                end = min(len(lines), i + 3)
                prescriber_lines.extend(lines[start:end])
        
        return '\n'.join(prescriber_lines) if prescriber_lines else raw_text[:200]
    
    def has_duration_hint(self, text: str) -> bool:
        """
        Check if text contains duration information
        """
        duration_keywords = ['day', 'week', 'month', 'for', '×', 'duration', 'continue']
        return any(kw in text.lower() for kw in duration_keywords)
    
    def extract_duration_from_text(self, text: str) -> Dict:
        """
        Extract duration from text
        """
        patterns = [
            r'for\s+(\d+)\s*(day|week|month)s?',
            r'×\s*(\d+)\s*(day|week|month)s?',
            r'continue\s+(\d+)\s*(day|week|month)s?',
            r'(\d+)\s*(day|week|month)s?\s*(?:duration|course)',
            r'(\d+)\s*d(?:\s|$)',  # 7d
            r'(\d+)\s*wk',  # 2wk
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                number = int(match.group(1))
                unit = match.group(2) if len(match.groups()) > 1 else 'day'
                unit = unit.lower()
                
                # Convert to days
                days_map = {"day": 1, "d": 1, "week": 7, "wk": 7, "month": 30}
                duration_days = number * days_map.get(unit, 1)
                
                return {
                    "duration": f"{number} {unit}{'s' if number > 1 and unit in ['day', 'week', 'month'] else ''}",
                    "duration_days": duration_days
                }
        
        return {"duration": None, "duration_days": None}
    
    def create_synthetic_examples(self) -> List[Dict]:
        """
        Create synthetic training examples for edge cases
        """
        examples = []
        
        # Synthetic diagnosis examples
        examples.extend([
            {
                "prompt": "Extract all medical diagnoses from:\n\n1. Chronic Cystitis\n2. Hypertension\n\nReturn JSON array of diagnosis names.",
                "response": '{"diagnosis": ["Chronic Cystitis", "Hypertension"]}'
            },
            {
                "prompt": "Extract all medical diagnoses from:\n\nDiagnosis: Type 2 Diabetes Mellitus\n\nReturn JSON array of diagnosis names.",
                "response": '{"diagnosis": ["Type 2 Diabetes Mellitus"]}'
            },
            {
                "prompt": "Extract all medical diagnoses from:\n\n1. Upper Respiratory Tract Infection\n2. Acute Bronchitis\n3. Fever\n\nReturn JSON array of diagnosis names.",
                "response": '{"diagnosis": ["Upper Respiratory Tract Infection", "Acute Bronchitis", "Fever"]}'
            }
        ])
        
        # Synthetic duration examples
        examples.extend([
            {
                "prompt": "Extract medication duration from:\n\nAmoxicillin 500mg, take for 7 days\n\nReturn JSON with duration and duration_days.",
                "response": '{"duration": "7 days", "duration_days": 7}'
            },
            {
                "prompt": "Extract medication duration from:\n\nPrednisolone 5mg × 2 weeks\n\nReturn JSON with duration and duration_days.",
                "response": '{"duration": "2 weeks", "duration_days": 14}'
            },
            {
                "prompt": "Extract medication duration from:\n\nCiprofloxacin continue for 10 days\n\nReturn JSON with duration and duration_days.",
                "response": '{"duration": "10 days", "duration_days": 10}'
            }
        ])
        
        # Synthetic prescriber examples
        examples.extend([
            {
                "prompt": "Extract prescriber information from:\n\nDr. Sok Vantha\nCalmette Hospital\n\nReturn JSON with prescriber_name and prescriber_facility.",
                "response": '{"prescriber_name": "Dr. Sok Vantha", "prescriber_facility": "Calmette Hospital", "prescriber_contact": null}'
            },
            {
                "prompt": "Extract prescriber information from:\n\nFriendship Hospital\nDr. Chan Sopheak\n023-123456\n\nReturn JSON with prescriber_name and prescriber_facility.",
                "response": '{"prescriber_name": "Dr. Chan Sopheak", "prescriber_facility": "Friendship Hospital", "prescriber_contact": "023-123456"}'
            }
        ])
        
        # Synthetic medication examples with Khmer
        examples.extend([
            {
                "prompt": "Extract medication details from:\n\nថ្នាំ Paracetamol 500mg\nផឹក 2 គ្រាប់ ពីរដង ក្នុងមួយថ្ងៃ\n\nReturn JSON with medication_name, strength, dosage, frequency, form, and instructions.",
                "response": '{"medication_name": "Paracetamol", "strength": "500mg", "form": "tablet", "dosage": "2 tablets", "frequency": "twice daily", "frequency_times": 2, "instructions_english": "Take 2 tablets twice daily", "instructions_khmer": "ផឹកថ្នាំ ២គ្រាប់ ២ដង ក្នុងមួយថ្ងៃ"}'
            }
        ])
        
        return examples
    
    def save_dataset(self, examples: List[Dict]):
        """
        Save training dataset to JSONL file
        """
        self.output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(self.output_file, 'w', encoding='utf-8') as f:
            for example in examples:
                f.write(json.dumps(example, ensure_ascii=False) + '\n')
        
        print(f"\n✅ Dataset saved to: {self.output_file}")
        print(f"📊 Total examples: {len(examples)}")
    
    def print_statistics(self):
        """
        Print dataset statistics
        """
        print("\n" + "=" * 70)
        print("📊 FINE-TUNING DATASET STATISTICS")
        print("=" * 70)
        print(f"Total training examples:     {self.stats['total_examples']}")
        print(f"  - Medication examples:     {self.stats['medication_examples']}")
        print(f"  - Diagnosis examples:      {self.stats['diagnosis_examples']}")
        print(f"  - Prescriber examples:     {self.stats['prescriber_examples']}")
        print(f"  - Duration examples:       {self.stats['duration_examples']}")
        print("=" * 70)
        print("\n🎯 Next step: Run fine-tuning script")
        print("   bash scripts/finetune_model.sh")


if __name__ == "__main__":
    creator = FinetuningDatasetCreator()
    creator.create_dataset()
