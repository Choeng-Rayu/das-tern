"""Medication name fuzzy matching against known drug lexicons."""
import os
from typing import Optional, Tuple, List, Dict
from rapidfuzz import fuzz, process


class MedLexicon:
    """Medication lexicon loader and fuzzy matcher."""

    def __init__(self, lexicon_dir: str, threshold: int = 85):
        self.threshold = threshold
        self.medications_en: List[str] = []
        self.medications_km: List[str] = []
        self.generic_map: Dict[str, str] = {}
        self.therapeutic_class_map: Dict[str, str] = {}
        self._load_lexicons(lexicon_dir)

    def _load_lexicons(self, lexicon_dir: str):
        """Load medication lexicons from text files."""
        en_path = os.path.join(lexicon_dir, "medications_en.txt")
        km_path = os.path.join(lexicon_dir, "medications_km.txt")

        if os.path.exists(en_path):
            with open(en_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    parts = line.split('|')
                    brand = parts[0].strip()
                    self.medications_en.append(brand)
                    if len(parts) > 1:
                        generic = parts[1].strip()
                        self.generic_map[brand.lower()] = generic
                    if len(parts) > 2:
                        therapeutic = parts[2].strip()
                        self.therapeutic_class_map[brand.lower()] = therapeutic

        if os.path.exists(km_path):
            with open(km_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    self.medications_km.append(line)

    def match_medication(self, name: str) -> Tuple[Optional[str], Optional[str], Optional[str], float]:
        """Match a medication name against the lexicon.

        Returns: (matched_name, generic_name, therapeutic_class, confidence_score)
        """
        if not name or not self.medications_en:
            return None, None, None, 0.0

        result = process.extractOne(
            name,
            self.medications_en,
            scorer=fuzz.ratio,
            score_cutoff=self.threshold
        )

        if result:
            matched_name, score, _ = result
            generic = self.generic_map.get(matched_name.lower())
            therapeutic = self.therapeutic_class_map.get(matched_name.lower())
            return matched_name, generic, therapeutic, score / 100.0

        return None, None, None, 0.0

    def get_generic_name(self, brand_name: str) -> Optional[str]:
        """Get generic name for a brand name."""
        return self.generic_map.get(brand_name.lower())

    def get_therapeutic_class(self, name: str) -> Optional[str]:
        """Get therapeutic class for a medication."""
        return self.therapeutic_class_map.get(name.lower())
