"""Parse raw OCR text lines into structured prescription data.

This module extracts:
- Patient information (name, age, gender, ID)
- Medication table rows
- Prescriber info
- Dates and diagnoses
- Clinical information

It handles mixed Khmer/English text patterns common in Cambodian prescriptions.
"""
import re
import logging
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# --------------------------------------------------------------------------- #
# Patterns for header/metadata extraction
# --------------------------------------------------------------------------- #

# Patient ID — alphanumeric codes like HAKF13541644
_PAT_CODE = re.compile(r'(?:លេខកូដ|កូដ|Code|ID|HN)\s*[:\.]?\s*([A-Z0-9]{4,})', re.IGNORECASE)

# Patient name
_PAT_NAME = re.compile(
    r'(?:ឈ្មោះអ្នកជំងឺ|ឈ្មោះ|Name|Patient)\s*[:\.]?\s*(.+?)(?:\s+អាយុ|\s+Age|\s*$)',
    re.IGNORECASE,
)

# Age
_PAT_AGE = re.compile(r'អាយុ\s*[:\.]?\s*(\d+)\s*(?:ឆ្នាំ)?|Age\s*[:\.]?\s*(\d+)', re.IGNORECASE)

# Gender
_PAT_GENDER = re.compile(r'ភេទ\s*[:\.]?\s*(ប្រុស|ស្រី)|Sex\s*[:\.]?\s*([MF])', re.IGNORECASE)

# Date patterns
_PAT_DATE_FULL = re.compile(r'ថ្ងៃទី\s*(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(\d{4})')
_PAT_DATE_PARTIAL = re.compile(r'ថ្ងៃទី\s*(\d{1,2})\s*/\s*(\d{4})')
_PAT_DATE_ISO = re.compile(r'(\d{4})-(\d{1,2})-(\d{1,2})')
_PAT_DATE_SLASH = re.compile(r'(\d{1,2})/(\d{1,2})/(\d{4})')

# Prescriber
_PAT_DOCTOR = re.compile(r'(?:វេជ្ជបណ្ឌិត|បណ្ឌិត|Dr\.?)\s*(.+)', re.IGNORECASE)

# Diagnosis
_PAT_DIAGNOSIS = re.compile(r'រោគវិនិច្ឆ័យ\s*[:\.]?\s*(.+)', re.IGNORECASE)

# Facility
_PAT_FACILITY = re.compile(r'(?:មន្ទីរពេទ្យ|Hospital|Clinic|មន្ទីរ)\s*[:\.]?\s*(.+)', re.IGNORECASE)

# Medicine patterns
_PAT_STRENGTH = re.compile(r'(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|iu|µg)', re.IGNORECASE)
_PAT_QUANTITY = re.compile(r'(\d+)\s*គ្រាប់')
_PAT_DURATION = re.compile(r'(\d+)\s*(?:ថ្ងៃ|days?|d\b)', re.IGNORECASE)
_PAT_BEFORE_MEAL = re.compile(r'មុន\s*បាយ|before\s*meal|ac\b', re.IGNORECASE)
_PAT_AFTER_MEAL = re.compile(r'ក្រោយ\s*បាយ|after\s*meal|pc\b', re.IGNORECASE)
_PAT_MEDICINE_NAME = re.compile(
    r'([A-Za-z][A-Za-z\-]+(?:\s+[A-Za-z][A-Za-z\-]+)*)'
    r'(?:\s+(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg))?',
    re.IGNORECASE,
)

# Skip patterns - lines that are NOT medication data
_SKIP_PATTERNS = [
    re.compile(r'^ប្រល\.រ', re.IGNORECASE),
    re.compile(r'^ល\.រ', re.IGNORECASE),
    re.compile(r'^ឈ្មោះឱសថ'),
    re.compile(r'^ចំនួន'),
    re.compile(r'^វិធីប្រើ'),
    re.compile(r'^វេជ្ជបញ្ជា'),
    re.compile(r'^សូមយក'),
    re.compile(r'គ្រពេទ្យព្យាបាល'),
    re.compile(r'^ព្រឹក(?:ក)?$'),
    re.compile(r'^ថ្ងៃត្រង់$'),
    re.compile(r'^ល្ងាច$'),
    re.compile(r'^យប់$'),
    re.compile(r'^\([\d\-]+\)$'),
    re.compile(r'^\|\s*\([\d\-]+\)'),
    re.compile(r'^\|\s*ព្រឹក'),
    re.compile(r'^ប្រភេទបង់'),
    re.compile(r'^ផ្នែក\s*:'),
    re.compile(r'^រាជធានី'),
    re.compile(r'^\(\s*អ្នកជំងឺ\s*\)'),
    re.compile(r'^តាមចាប់'),
    re.compile(r'^Subs$', re.IGNORECASE),
    re.compile(r'^[|\[\]\-\s]{1,5}$'),
    re.compile(r'Hospital|Clinic|Friendship|មន្ទីរ', re.IGNORECASE),
    re.compile(r'H-EQIP|EQIP', re.IGNORECASE),
    re.compile(r'រោគវិនិច្ឆ័យ'),
    re.compile(r'Diagnosis|Chronic|Acute', re.IGNORECASE),
    re.compile(r'ឈ្មោះអ្នកជំងឺ'),
    re.compile(r'អាយុ.*ភេទ'),
    re.compile(r'លេខកូដ'),
    re.compile(r'វេជ្ជបណ្ឌិត'),
    re.compile(r'មូលនិធិ'),
    re.compile(r'ថ្ងៃទី'),
    re.compile(r'^Srikes$', re.IGNORECASE),
    re.compile(r'^\d{4}$'),  # Bare 4-digit number (year)
    re.compile(r'^\d{1,2}:\d{2}'),  # Time pattern
]

# A line looks like a medication line if it contains an English drug name
_PAT_HAS_DRUG_NAME = re.compile(r'[A-Za-z]{4,}')


@dataclass
class ParsedMedication:
    """A single parsed medication entry."""
    item_number: int = 0
    name_full: str = ""
    brand_name: Optional[str] = None
    generic_name: Optional[str] = None
    local_name: Optional[str] = None
    strength_value: Optional[str] = None
    strength_numeric: Optional[float] = None
    strength_unit: Optional[str] = None
    form: Optional[str] = None
    route: Optional[str] = None
    duration_days: Optional[int] = None
    duration_text: str = ""
    times_per_day: int = 1
    morning_dose: Optional[float] = None
    midday_dose: Optional[float] = None
    afternoon_dose: Optional[float] = None
    evening_dose: Optional[float] = None
    before_meal: Optional[bool] = None
    after_meal: Optional[bool] = None
    as_needed: bool = False
    instructions_text: str = ""
    total_quantity: Optional[int] = None
    confidence: float = 0.85
    bbox: List[int] = field(default_factory=list)


@dataclass
class ParsedPrescription:
    """Full structured prescription from OCR text."""
    patient_id: Optional[str] = None
    patient_name: Optional[str] = None
    patient_name_khmer: Optional[str] = None
    patient_age: Optional[int] = None
    patient_age_unit: str = "years"
    patient_gender: Optional[str] = None
    diagnoses: List[str] = field(default_factory=list)
    prescriber_name: Optional[str] = None
    facility_name: Optional[str] = None
    issue_date: Optional[str] = None
    medications: List[ParsedMedication] = field(default_factory=list)
    full_text: str = ""
    confidence: float = 0.85


def _should_skip_line(text: str) -> bool:
    """Check if a line should be skipped (header, label, etc.)."""
    text = text.strip()
    if not text or len(text) < 2:
        return True
    for pat in _SKIP_PATTERNS:
        if pat.search(text):
            return True
    return False


def _is_medication_line(text: str) -> bool:
    """Check if a line looks like it contains medication data."""
    text = text.strip()
    if _should_skip_line(text):
        return False
    if any([
        _PAT_NAME.search(text),
        _PAT_AGE.search(text),
        _PAT_GENDER.search(text),
        _PAT_CODE.search(text),
        _PAT_DOCTOR.search(text),
        _PAT_DATE_FULL.search(text),
        _PAT_DATE_ISO.search(text),
        _PAT_DATE_SLASH.search(text),
        _PAT_DIAGNOSIS.search(text),
        _PAT_FACILITY.search(text),
    ]):
        return False
    # Must contain at least one English drug name (4+ chars)
    if _PAT_HAS_DRUG_NAME.search(text):
        return True
    return False


def _extract_patient_info(lines: List[str]) -> dict:
    """Extract patient info from header lines."""
    result = {
        "id": None,
        "name": None,
        "name_khmer": None,
        "age": None,
        "gender": None,
    }

    text = " ".join(lines[:15])  # Search first 15 lines

    # Patient ID
    m = _PAT_CODE.search(text)
    if m:
        result["id"] = m.group(1)

    # Name
    m = _PAT_NAME.search(text)
    if m:
        name = m.group(1).strip()
        # Determine if Khmer or English
        if re.search(r'[\u1780-\u17FF]', name):
            result["name_khmer"] = name
        else:
            result["name"] = name

    # Age
    m = _PAT_AGE.search(text)
    if m:
        age_val = m.group(1) or m.group(2)
        if age_val:
            result["age"] = int(age_val)

    # Gender
    m = _PAT_GENDER.search(text)
    if m:
        g = m.group(1) or m.group(2)
        if g:
            g = g.strip().upper()
            if g in ("M", "ប្រុស"):
                result["gender"] = "M"
            elif g in ("F", "ស្រី"):
                result["gender"] = "F"

    return result


def _extract_prescriber(lines: List[str]) -> Optional[str]:
    """Extract prescriber name."""
    text = " ".join(lines[-10:])  # Search last 10 lines
    m = _PAT_DOCTOR.search(text)
    if m:
        return m.group(1).strip()
    return None


def _extract_facility(lines: List[str]) -> Optional[str]:
    """Extract facility name."""
    text = " ".join(lines[:10])  # Search first 10 lines
    m = _PAT_FACILITY.search(text)
    if m:
        return m.group(1).strip()
    return None


def _extract_date(lines: List[str]) -> Optional[str]:
    """Extract prescription date in ISO format."""
    text = " ".join(lines)

    # Try full date (dd/mm/yyyy)
    m = _PAT_DATE_FULL.search(text)
    if m:
        d, mo, y = m.group(1), m.group(2), m.group(3)
        return f"{y}-{int(mo):02d}-{int(d):02d}"

    # Try ISO format
    m = _PAT_DATE_ISO.search(text)
    if m:
        y, mo, d = m.group(1), m.group(2), m.group(3)
        return f"{y}-{int(mo):02d}-{int(d):02d}"

    # Try slash format
    m = _PAT_DATE_SLASH.search(text)
    if m:
        d, mo, y = m.group(1), m.group(2), m.group(3)
        return f"{y}-{int(mo):02d}-{int(d):02d}"

    return None


def _extract_diagnoses(lines: List[str]) -> List[str]:
    """Extract diagnosis lines."""
    diagnoses = []
    text = " ".join(lines[:20])  # Search first 20 lines
    m = _PAT_DIAGNOSIS.search(text)
    if m:
        diag = m.group(1).strip()
        if diag:
            diagnoses.append(diag)
    return diagnoses


def _parse_medication_line(text: str, item_num: int, bbox: List[int] = None) -> Optional[ParsedMedication]:
    """Parse a single medication line into structured data."""
    if not _is_medication_line(text):
        return None

    med = ParsedMedication(item_number=item_num, bbox=bbox or [])

    # Extract medicine name (English)
    m = _PAT_MEDICINE_NAME.search(text)
    if m:
        med.name_full = m.group(1).strip()
        med.brand_name = med.name_full
        if m.group(2) and m.group(3):
            med.strength_numeric = float(m.group(2))
            med.strength_unit = m.group(3).lower()
            med.strength_value = f"{m.group(2)}{m.group(3)}"

    # If no name found, skip
    if not med.name_full:
        return None

    # Extract strength if not already found
    if not med.strength_value:
        m = _PAT_STRENGTH.search(text)
        if m:
            med.strength_numeric = float(m.group(1))
            med.strength_unit = m.group(2).lower()
            med.strength_value = f"{m.group(1)}{m.group(2)}"

    # Extract duration
    m = _PAT_DURATION.search(text)
    if m:
        med.duration_days = int(m.group(1))
        med.duration_text = f"{m.group(1)} days"

    # Extract quantity
    m = _PAT_QUANTITY.search(text)
    if m:
        med.total_quantity = int(m.group(1))

    # Meal timing
    if _PAT_BEFORE_MEAL.search(text):
        med.before_meal = True
    if _PAT_AFTER_MEAL.search(text):
        med.after_meal = True

    # Detect form from common patterns
    text_lower = text.lower()
    if "tab" in text_lower or "tablet" in text_lower:
        med.form = "tablet"
        med.route = "PO"
    elif "cap" in text_lower or "capsule" in text_lower:
        med.form = "capsule"
        med.route = "PO"
    elif "syrup" in text_lower or "susp" in text_lower:
        med.form = "syrup"
        med.route = "PO"
    elif "inj" in text_lower:
        med.form = "injection"
        med.route = "IV"
    elif "cream" in text_lower or "ointment" in text_lower:
        med.form = "cream"
        med.route = "TOPICAL"
    else:
        med.form = "tablet"  # Default
        med.route = "PO"

    # Extract dosing schedule from common patterns
    # Look for patterns like "1-1-1", "1-0-1", "2x1", etc.
    dose_match = re.search(r'(\d+)-(\d+)-(\d+)(?:-(\d+))?', text)
    if dose_match:
        med.morning_dose = float(dose_match.group(1)) if dose_match.group(1) != "0" else None
        med.midday_dose = float(dose_match.group(2)) if dose_match.group(2) != "0" else None
        med.afternoon_dose = float(dose_match.group(3)) if dose_match.group(3) != "0" else None
        if dose_match.group(4):
            med.evening_dose = float(dose_match.group(4)) if dose_match.group(4) != "0" else None
        med.times_per_day = sum(1 for d in [med.morning_dose, med.midday_dose, med.afternoon_dose, med.evening_dose] if d)
    else:
        # Look for "2x1", "3x1" patterns
        times_match = re.search(r'(\d+)\s*[xX]\s*(\d+)', text)
        if times_match:
            med.times_per_day = int(times_match.group(1))

    med.instructions_text = text.strip()
    return med


def _parse_dose_cell(text: str) -> Optional[float]:
    """Parse a dose cell value from table text.

    Handles: "1", "1.5", "2", blank/dash → None, checkmarks/dots → 1.0
    """
    text = text.strip()
    if not text or text in ("-", "—", "–", "0", "|"):
        return None
    # Numeric dose
    m = re.match(r'^(\d+(?:\.\d+)?)$', text)
    if m:
        return float(m.group(1))
    # Checkmark-like characters or single dots → 1
    if text in ("✓", "✔", "√", "·", "•", "V", "v", "x", "X"):
        return 1.0
    # Try to extract leading number
    m = re.match(r'(\d+(?:\.\d+)?)', text)
    if m:
        return float(m.group(1))
    return None


_PAT_KHMER_QTY = re.compile(r'(\d+)\s*(?:គ្រាប់|ស្រោប|កញ្ចប់|ដប|បន្ទះ|ml|tab)', re.IGNORECASE)
_PAT_SIMPLE_DOSE = re.compile(r'^[|\]\[\s]*(\d+(?:\.\d+)?)[|\]\[\s]*$')
_PAT_ROW_NUMBER = re.compile(r'^[|\]\[\sF]*(\d{1,2})[|\]\[\s]*$')


def _classify_cell(text: str) -> str:
    """Classify a cell's content type: 'name', 'quantity', 'dose', 'number', or 'unknown'."""
    text = text.strip().lstrip('|][ ')

    if not text:
        return "unknown"

    # Khmer quantity (e.g., "14គ្រាប់", "21គ្រាប់ស្រោប")
    if _PAT_KHMER_QTY.search(text):
        return "quantity"

    # Medication name: contains English words ≥3 chars, but not skip-listed
    if _PAT_MEDICINE_NAME.search(text):
        english_part = _PAT_MEDICINE_NAME.search(text).group(1)
        if len(english_part) >= 3 and not _should_skip_line(text):
            return "name"

    # Simple dose value (single digit or small number)
    if _PAT_SIMPLE_DOSE.match(text):
        val = float(_PAT_SIMPLE_DOSE.match(text).group(1))
        if val <= 10:
            return "dose"

    # Row number (1-2 digits, possibly with leading pipe/bracket)
    if _PAT_ROW_NUMBER.match(text):
        return "number"

    return "unknown"


def parse_table_medications(
    rows: list,
    header_labels: Optional[list] = None,
) -> List[ParsedMedication]:
    """Parse medications from structured table rows using content-based cell detection.

    Instead of relying on fixed column positions, each cell is classified by its
    content (name, quantity, dose, row number) to handle variable column counts
    and merged/split header rows common in Cambodian prescriptions.
    """
    if not rows:
        return []

    medications: List[ParsedMedication] = []
    for row in rows:
        if not row or len(row) < 2:
            continue

        # Skip header-like rows
        row_text = " ".join(str(c) for c in row)
        if _should_skip_line(row_text):
            continue

        med = _parse_table_row_by_content(row, item_num=len(medications) + 1)
        if med is not None:
            _fill_default_time_slots(med)
            medications.append(med)

    return medications


def _parse_table_row_by_content(
    cells: list, item_num: int
) -> Optional[ParsedMedication]:
    """Parse a table row by classifying each cell's content type.

    This approach is robust to varying column counts and doesn't require
    a fixed column mapping.
    """
    # Classify each cell
    classified: List[tuple] = []  # [(index, type, text), ...]
    for i, cell_text in enumerate(cells):
        text = str(cell_text).strip()
        ctype = _classify_cell(text)
        classified.append((i, ctype, text))

    # Find the name cell
    name_cells = [(i, t) for i, ct, t in classified if ct == "name"]
    if not name_cells:
        return None

    name_idx, name_text = name_cells[0]
    # Clean leading pipe/bracket chars from name
    clean_name = re.sub(r'^[|\]\[\sF\d]+', '', name_text).strip()

    # Extract medication name and strength
    m = _PAT_MEDICINE_NAME.search(clean_name)
    if not m:
        if len(clean_name) >= 3 and not _should_skip_line(clean_name):
            med = ParsedMedication(item_number=item_num, name_full=clean_name, brand_name=clean_name)
        else:
            return None
    else:
        med = ParsedMedication(
            item_number=item_num,
            name_full=m.group(1).strip(),
            brand_name=m.group(1).strip(),
        )
        if m.group(2) and m.group(3):
            med.strength_numeric = float(m.group(2))
            med.strength_unit = m.group(3).lower()
            med.strength_value = f"{m.group(2)}{m.group(3)}"

    # Strength from name cell if not already found
    if not med.strength_value:
        sm = _PAT_STRENGTH.search(name_text)
        if sm:
            med.strength_numeric = float(sm.group(1))
            med.strength_unit = sm.group(2).lower()
            med.strength_value = f"{sm.group(1)}{sm.group(2)}"

    # Extract quantity (Khmer or numeric)
    qty_cells = [(i, t) for i, ct, t in classified if ct == "quantity"]
    if qty_cells:
        qty_text = qty_cells[0][1]
        qm = re.search(r'(\d+)', qty_text)
        if qm:
            med.total_quantity = int(qm.group(1))
        # Detect form from Khmer quantity unit
        if 'ស្រោប' in qty_text:
            med.form = "capsule"
        elif 'កញ្ចប់' in qty_text:
            med.form = "packet"
        elif 'ដប' in qty_text:
            med.form = "bottle"
            med.route = "PO"

    # Extract dose values: any numeric cell AFTER the name that is not
    # the quantity cell. In OCR output, dose cells may be classified as
    # "dose", "number", or even "unknown" due to OCR artifacts (e.g. "11"
    # instead of "1").
    qty_indices = {i for i, ct, t in classified if ct == "quantity"}
    dose_values = []
    for i, ctype, text in classified:
        if i <= name_idx:
            continue  # skip cells before/at the name
        if i in qty_indices:
            continue  # skip quantity cells
        # Accept cells classified as dose or number (small numeric values)
        clean = text.strip().lstrip('|][ ')
        num_match = re.match(r'^(\d+(?:\.\d+)?)$', clean)
        if num_match:
            val = float(num_match.group(1))
            # Handle OCR duplicate digit artifacts: "11" → 1, "44" → 4
            if val >= 10 and len(clean) == 2 and clean[0] == clean[1]:
                val = float(clean[0])
            if val <= 10:
                dose_values.append(val)
            continue
        # Also try _parse_dose_cell for checkmarks etc.
        dv = _parse_dose_cell(text)
        if dv is not None:
            dose_values.append(dv)

    # Assign dose values to time slots based on position count
    # Common patterns: [morning, evening] or [morning, midday, afternoon, evening]
    if len(dose_values) >= 4:
        med.morning_dose = dose_values[0]
        med.midday_dose = dose_values[1]
        med.afternoon_dose = dose_values[2]
        med.evening_dose = dose_values[3]
    elif len(dose_values) == 3:
        med.morning_dose = dose_values[0]
        med.midday_dose = dose_values[1]
        med.evening_dose = dose_values[2]
    elif len(dose_values) == 2:
        med.morning_dose = dose_values[0]
        med.evening_dose = dose_values[1]
    elif len(dose_values) == 1:
        med.morning_dose = dose_values[0]

    med.times_per_day = sum(1 for d in [med.morning_dose, med.midday_dose, med.afternoon_dose, med.evening_dose] if d)

    # Duration: try to find from any cell that has "days" or "ថ្ងៃ" pattern
    all_text = " ".join(str(c) for c in cells)
    dur_match = re.search(r'(\d+)\s*(?:ថ្ងៃ|days?|d\b|jour)', all_text, re.IGNORECASE)
    if dur_match:
        med.duration_days = int(dur_match.group(1))
        med.duration_text = f"{dur_match.group(1)} days"

    # If no duration but we have quantity and times_per_day, calculate it
    if not med.duration_days and med.total_quantity and med.times_per_day:
        total_dose_per_day = sum(d for d in [med.morning_dose, med.midday_dose, med.afternoon_dose, med.evening_dose] if d)
        if total_dose_per_day > 0:
            med.duration_days = int(med.total_quantity / total_dose_per_day)
            med.duration_text = f"{med.duration_days} days (calculated)"

    # Default form if not set
    if not med.form:
        name_lower = name_text.lower()
        if "cap" in name_lower or "capsule" in name_lower:
            med.form = "capsule"
        elif "syrup" in name_lower or "susp" in name_lower:
            med.form = "syrup"
        elif "inj" in name_lower:
            med.form = "injection"
            med.route = "IV"
        else:
            med.form = "tablet"
    if not med.route:
        med.route = "PO"

    # Meal timing
    if _PAT_BEFORE_MEAL.search(all_text):
        med.before_meal = True
    if _PAT_AFTER_MEAL.search(all_text):
        med.after_meal = True

    med.instructions_text = " | ".join(str(c) for c in cells if str(c).strip())
    return med


def _fill_default_time_slots(med: ParsedMedication) -> None:
    """Backfill basic schedule slots from times_per_day when explicit slots were not parsed."""
    explicit_doses = [med.morning_dose, med.midday_dose, med.afternoon_dose, med.evening_dose]
    if any(d is not None for d in explicit_doses):
        return

    if med.times_per_day <= 0:
        med.times_per_day = 1

    if med.times_per_day >= 1:
        med.morning_dose = 1.0
    if med.times_per_day >= 2:
        med.evening_dose = 1.0
    if med.times_per_day >= 3:
        med.midday_dose = 1.0
    if med.times_per_day >= 4:
        med.afternoon_dose = 1.0


def parse_prescription(full_text: str, line_results: List[Any]) -> ParsedPrescription:
    """Parse OCR output into a structured prescription object.

    The parser is intentionally heuristic-based and general-purpose:
    it extracts metadata from header/footer lines and medication rows from
    OCR line items without assuming a single fixed layout.
    """
    lines = [getattr(line, "text", "").strip() for line in line_results if getattr(line, "text", "").strip()]
    if not lines and full_text:
        lines = [part.strip() for part in full_text.splitlines() if part.strip()]

    patient = _extract_patient_info(lines)
    diagnoses = _extract_diagnoses(lines)

    rx = ParsedPrescription(
        patient_id=patient["id"],
        patient_name=patient["name"],
        patient_name_khmer=patient["name_khmer"],
        patient_age=patient["age"],
        patient_gender=patient["gender"],
        diagnoses=diagnoses,
        prescriber_name=_extract_prescriber(lines),
        facility_name=_extract_facility(lines),
        issue_date=_extract_date(lines),
        full_text=full_text.strip(),
    )

    medications: List[ParsedMedication] = []
    for idx, line in enumerate(line_results, start=1):
        text = getattr(line, "text", "").strip()
        if not text:
            continue
        med = _parse_medication_line(
            text,
            item_num=len(medications) + 1,
            bbox=getattr(line, "bbox", []) or [],
        )
        if med is None:
            continue

        line_conf = getattr(line, "confidence", None)
        if isinstance(line_conf, (int, float)):
            med.confidence = max(0.0, min(1.0, float(line_conf)))
        _fill_default_time_slots(med)
        medications.append(med)

    # Fallback: if no line-level meds were parsed, scan raw text lines.
    if not medications and full_text:
        for raw_line in full_text.splitlines():
            text = raw_line.strip()
            if not text:
                continue
            med = _parse_medication_line(text, item_num=len(medications) + 1)
            if med is None:
                continue
            _fill_default_time_slots(med)
            medications.append(med)

    rx.medications = medications

    confidences = [m.confidence for m in medications if isinstance(m.confidence, (int, float))]
    if confidences:
        rx.confidence = round(sum(confidences) / len(confidences), 4)
    else:
        line_confidences = [
            float(getattr(line, "confidence", 0.0))
            for line in line_results
            if isinstance(getattr(line, "confidence", None), (int, float))
        ]
        rx.confidence = round(sum(line_confidences) / len(line_confidences), 4) if line_confidences else 0.0

    logger.info(
        "Parsed prescription: %s medications, patient=%s, doctor=%s, date=%s",
        len(rx.medications),
        rx.patient_name or rx.patient_name_khmer,
        rx.prescriber_name,
        rx.issue_date,
    )
    return rx
