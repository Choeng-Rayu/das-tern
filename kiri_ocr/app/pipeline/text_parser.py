"""Parse raw OCR text lines into structured prescription data.

This module takes the raw lines from Kiri-OCR and extracts:
- Patient information (name, age, gender, ID)
- Medication table rows
- Prescriber info
- Dates and diagnoses
- Clinical information

It handles mixed Khmer/English text patterns common in Cambodian prescriptions.
The Kiri-OCR model returns per-region results; this parser works with both
the full_text (newline-joined) and the individual line_result dicts.
"""
import re
import logging
from dataclasses import dataclass, field
from typing import List, Optional

logger = logging.getLogger(__name__)

# --------------------------------------------------------------------------- #
# Patterns                                                                     #
# --------------------------------------------------------------------------- #

# Patient ID — alphanumeric codes like HAKF13541644
_PAT_CODE = re.compile(r'(?:លេខកូដ|កូដ|Code|ID|HN)\s*[:\.]?\s*([A-Z0-9]{4,})', re.IGNORECASE)

# Patient name — "ឈ្មោះអ្នកជំងឺ:" followed by name, stop before "អាយុ"
_PAT_NAME = re.compile(
    r'(?:ឈ្មោះអ្នកជំងឺ|ឈ្មោះ|Name|Patient)\s*[:\.]?\s*(.+?)(?:\s+អាយុ|\s+Age|\s*$)',
    re.IGNORECASE,
)

# Age
_PAT_AGE = re.compile(r'អាយុ\s*[:\.]?\s*(\d+)\s*(?:ឆ្នាំ)?|Age\s*[:\.]?\s*(\d+)', re.IGNORECASE)

# Gender
_PAT_GENDER = re.compile(r'ភេទ\s*[:\.]?\s*(ប្រុស|ស្រី)|Sex\s*[:\.]?\s*([MF])', re.IGNORECASE)

# Date — various Cambodian/international formats
_PAT_DATE_FULL = re.compile(r'ថ្ងៃទី\s*(\d{1,2})\s*/\s*(\d{1,2})\s*/\s*(\d{4})')
_PAT_DATE_PARTIAL = re.compile(r'ថ្ងៃទី\s*(\d{1,2})\s*/\s*(\d{4})')  # Missing day: "15/2025"
_PAT_DATE_ISO = re.compile(r'(\d{4})-(\d{1,2})-(\d{1,2})')
_PAT_DATE_SLASH = re.compile(r'(\d{1,2})/(\d{1,2})/(\d{4})')

# Prescriber
_PAT_DOCTOR = re.compile(
    r'(?:វេជ្ជបណ្ឌិត|បណ្ឌិត|Dr\.?)\s*(.+)',
    re.IGNORECASE,
)

# Diagnosis — "រោគវិនិច្ឆ័យ:" label
_PAT_DIAGNOSIS = re.compile(
    r'រោគវិនិច្ឆ័យ\s*[:\.]?\s*(.+)',
    re.IGNORECASE,
)

# Facility / hospital
_PAT_FACILITY = re.compile(
    r'(?:មន្ទីរពេទ្យ|Hospital|Clinic|មន្ទីរ)\s*[:\.]?\s*(.+)',
    re.IGNORECASE,
)

# Strength (e.g., "500mg", "100mg", "20mg")
_PAT_STRENGTH = re.compile(
    r'(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|iu|µg)',
    re.IGNORECASE,
)

# Quantity and form (e.g., "14 គ្រាប់", "21គ្រាប់", "14គ្រាប់ស្រោប")
_PAT_QUANTITY = re.compile(r'(\d+)\s*គ្រាប់')

# Duration: "5 ថ្ងៃ", "7 days"
_PAT_DURATION = re.compile(r'(\d+)\s*(?:ថ្ងៃ|days?|d\b)', re.IGNORECASE)

# Meal timing
_PAT_BEFORE_MEAL = re.compile(r'មុន\s*បាយ|before\s*meal|ac\b', re.IGNORECASE)
_PAT_AFTER_MEAL = re.compile(r'ក្រោយ\s*បាយ|after\s*meal|pc\b', re.IGNORECASE)

# Known medicine name pattern — English word(s) optionally with strength
_PAT_MEDICINE_NAME = re.compile(
    r'([A-Za-z][A-Za-z\-]+(?:\s+[A-Za-z][A-Za-z\-]+)*)'
    r'(?:\s+(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg))?',
    re.IGNORECASE,
)

# --------------------------------------------------------------------------- #
# Skip-detection: lines that are NOT medication data                           #
# --------------------------------------------------------------------------- #

# Lines that are purely table headers, footer text, or structural elements
_SKIP_PATTERNS = [
    re.compile(r'^ប្រល\.រ', re.IGNORECASE),  # "ល.រ" (item number header)
    re.compile(r'^ល\.រ', re.IGNORECASE),
    re.compile(r'^ឈ្មោះឱសថ'),  # medication name header
    re.compile(r'^ចំនួន'),  # quantity header
    re.compile(r'^វិធីប្រើ'),  # instructions header
    re.compile(r'^វេជ្ជបញ្ជា'),  # "prescription" title
    re.compile(r'^សូមយក'),  # "please return prescription"
    re.compile(r'គ្រពេទ្យព្យាបាល'),  # "treating doctor" label
    re.compile(r'^ព្រឹក(?:ក)?$'),  # "morning" standalone
    re.compile(r'^ថ្ងៃត្រង់$'),  # "midday" standalone
    re.compile(r'^ល្ងាច$'),  # "afternoon" standalone
    re.compile(r'^យប់$'),  # "evening" standalone
    re.compile(r'^\([\d\-]+\)$'),  # time ranges like "(6-8)" "(11-12)"
    re.compile(r'^\|\s*\([\d\-]+\)'),  # "| (05-06) ||"
    re.compile(r'^\|\s*ព្រឹក'),  # "| ព្រឹក"
    re.compile(r'^ប្រភេទបង់'),  # payment type
    re.compile(r'^ផ្នែក\s*:'),  # department
    re.compile(r'^រាជធានី'),  # "Phnom Penh" (location line)
    re.compile(r'^\(\s*អ្នកជំងឺ\s*\)'),  # "(patient)" label
    re.compile(r'^តាមចាប់'),  # payment note
    re.compile(r'^Subs$', re.IGNORECASE),  # signature fragment
    re.compile(r'^[|\[\]\-\s]{1,5}$'),  # table separators
    # Header/facility lines
    re.compile(r'Hospital|Clinic|Friendship|មន្ទីរ', re.IGNORECASE),
    re.compile(r'H-EQIP|EQIP', re.IGNORECASE),
    re.compile(r'រោគវិនិច្ឆ័យ'),  # diagnosis label line
    re.compile(r'Diagnosis|Chronic|Acute', re.IGNORECASE),  # diagnosis content
    re.compile(r'ឈ្មោះអ្នកជំងឺ'),  # patient name label
    re.compile(r'អាយុ.*ភេទ'),  # age/gender line
    re.compile(r'លេខកូដ'),  # code label
    re.compile(r'វេជ្ជបណ្ឌិត'),  # doctor name label
    re.compile(r'មូលនិធិ'),  # fund/payment
    re.compile(r'ថ្ងៃទី'),  # date line
]

# A line looks like a medication line if it contains an English drug name
# (at least one capitalized English word of 4+ chars) possibly with numbers
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
    """Return True if the line is a header, footer, or structural element."""
    text = text.strip()
    if len(text) < 2:
        return True
    for pat in _SKIP_PATTERNS:
        if pat.search(text):
            return True
    return False


def _extract_patient_info(full_text: str, rx: ParsedPrescription) -> None:
    """Extract patient info from the full OCR text."""
    # Patient ID (alphanumeric code)
    m = _PAT_CODE.search(full_text)
    if m:
        rx.patient_id = m.group(1)

    # Patient name
    m = _PAT_NAME.search(full_text)
    if m:
        name = m.group(1).strip()
        # Remove trailing colon/punctuation
        name = re.sub(r'[:\s]+$', '', name).strip()
        if name:
            rx.patient_name = name
            if any('\u1780' <= c <= '\u17FF' for c in name):
                rx.patient_name_khmer = name

    # Age
    m = _PAT_AGE.search(full_text)
    if m:
        age_str = m.group(1) or m.group(2)
        if age_str:
            try:
                rx.patient_age = int(age_str)
            except ValueError:
                pass

    # Gender
    m = _PAT_GENDER.search(full_text)
    if m:
        raw = (m.group(1) or m.group(2) or "").strip()
        if raw in ('ស្រី', 'F', 'f'):
            rx.patient_gender = 'F'
        elif raw in ('ប្រុស', 'M', 'm'):
            rx.patient_gender = 'M'


def _extract_date(full_text: str, rx: ParsedPrescription) -> None:
    """Extract prescription issue date."""
    # Try full date: ថ្ងៃទី DD/MM/YYYY
    m = _PAT_DATE_FULL.search(full_text)
    if m:
        d, mo, y = m.group(1), m.group(2), m.group(3)
        rx.issue_date = f"{y}-{mo.zfill(2)}-{d.zfill(2)}"
        return

    # Try partial date: ថ្ងៃទី MM/YYYY (common OCR misread — month/year only)
    m = _PAT_DATE_PARTIAL.search(full_text)
    if m:
        mo_or_day, y = m.group(1), m.group(2)
        # "ថ្ងៃទី 15/2025" likely means day=15, but month is unknown
        # If the number <= 12, treat as month; if > 12, treat as day
        val = int(mo_or_day)
        if val > 12:
            # It's a day, month unknown — use day/01/year
            rx.issue_date = f"{y}-01-{str(val).zfill(2)}"
        else:
            rx.issue_date = f"{y}-{str(val).zfill(2)}-01"
        return

    # Try DD/MM/YYYY standalone
    m = _PAT_DATE_SLASH.search(full_text)
    if m:
        d, mo, y = m.group(1), m.group(2), m.group(3)
        rx.issue_date = f"{y}-{mo.zfill(2)}-{d.zfill(2)}"
        return

    # Try ISO format
    m = _PAT_DATE_ISO.search(full_text)
    if m:
        rx.issue_date = f"{m.group(1)}-{m.group(2).zfill(2)}-{m.group(3).zfill(2)}"


def _extract_diagnosis(full_text: str, rx: ParsedPrescription) -> None:
    """Extract diagnoses."""
    m = _PAT_DIAGNOSIS.search(full_text)
    if m:
        diag = m.group(1).strip()
        if diag:
            rx.diagnoses.append(diag)


def _extract_prescriber(full_text: str, rx: ParsedPrescription) -> None:
    """Extract prescriber name."""
    m = _PAT_DOCTOR.search(full_text)
    if m:
        rx.prescriber_name = m.group(1).strip()


def _extract_facility(full_text: str, rx: ParsedPrescription) -> None:
    """Extract healthcare facility name."""
    # Look for facility in first few lines
    lines = full_text.split('\n')[:5]
    for line in lines:
        m = _PAT_FACILITY.search(line)
        if m:
            rx.facility_name = m.group(1).strip()
            # Truncate at first label marker (លេខកូដ, ឈ្មោះ, etc.)
            for marker in ['លេខកូដ', 'ឈ្មោះ', 'អាយុ', 'H-EQIP', 'EQIP']:
                idx = rx.facility_name.find(marker)
                if idx > 0:
                    rx.facility_name = rx.facility_name[:idx].strip()
            return
        # Check for Hospital pattern in English (e.g., "Friendship Hospital")
        hm = re.search(r'([\w\s]+(?:Hospital|Clinic|Centre))', line, re.IGNORECASE)
        if hm:
            rx.facility_name = hm.group(1).strip()
            return


def _is_medication_line(text: str) -> bool:
    """Check if a line likely contains medication data."""
    # Must contain an English drug name (4+ alpha chars)
    if not _PAT_HAS_DRUG_NAME.search(text):
        return False
    # Should not be a known skip pattern
    if _should_skip_line(text):
        return False
    return True


def _parse_medication_from_text(text: str, item_num: int) -> Optional[ParsedMedication]:
    """Parse a medication entry from a text line."""
    med = ParsedMedication(item_number=item_num)

    # Clean leading pipe, bracket, and item number
    cleaned = re.sub(r'^[\|\[\]\(\)]+\s*', '', text.strip())
    cleaned = re.sub(r'^\d+\s*[\.\)\-]?\s*', '', cleaned).strip()
    # Also remove leading pipe/bracket from within
    cleaned = re.sub(r'^\|\s*', '', cleaned).strip()

    if not cleaned:
        return None

    med.name_full = cleaned

    # Extract English medicine name
    name_match = _PAT_MEDICINE_NAME.search(cleaned)
    if name_match:
        med.brand_name = name_match.group(1).strip()
        # If there's an inline strength like "Celcoxx 100mg"
        if name_match.group(2):
            med.strength_numeric = float(name_match.group(2))
            med.strength_unit = name_match.group(3).lower()
            med.strength_value = f"{name_match.group(2)}{name_match.group(3)}"

    # Also try standalone strength pattern
    if not med.strength_value:
        sm = _PAT_STRENGTH.search(cleaned)
        if sm:
            med.strength_numeric = float(sm.group(1))
            med.strength_unit = sm.group(2).lower()
            med.strength_value = sm.group(0)

    # Quantity (e.g., "14 គ្រាប់")
    qm = _PAT_QUANTITY.search(cleaned)
    if qm:
        med.total_quantity = int(qm.group(1))
        med.form = "tablet"
        med.route = "PO"

    # If "ស្រោប" (coated) is present, it's a coated tablet
    if 'ស្រោប' in cleaned:
        med.form = "tablet"
        med.route = "PO"

    # Duration
    dm = _PAT_DURATION.search(cleaned)
    if dm:
        med.duration_days = int(dm.group(1))
        med.duration_text = dm.group(0)

    # Meal timing
    if _PAT_BEFORE_MEAL.search(cleaned):
        med.before_meal = True
    elif _PAT_AFTER_MEAL.search(cleaned):
        med.after_meal = True

    return med


def _assign_doses_from_line_results(
    medications: List[ParsedMedication],
    line_results: list,
) -> None:
    """Assign dose values to medications based on nearby dose-cell results.

    The OCR results include small regions with just "1", "11", etc. that
    correspond to dose columns. We match them to medications based on
    vertical position (y-coordinate overlap).
    """
    if not medications or not line_results:
        return

    # Separate dose-cell results (short numeric text) from medication results
    # Also map medication y-ranges from line_results
    med_y_ranges = []  # (med_index, y_min, y_max) from nearby line results

    # Collect all numeric-only results (likely dose cells)
    dose_cells = []
    for lr in line_results:
        txt = lr.text.strip() if hasattr(lr, 'text') else str(lr).strip()
        bbox = lr.bbox if hasattr(lr, 'bbox') else []
        if not bbox or len(bbox) < 4:
            continue
        x, y, w, h = bbox[0], bbox[1], bbox[2], bbox[3]
        # Dose cells: short numeric text (1-2 digits), small width
        if re.match(r'^\d{1,2}$', txt) and w < 80:
            dose_cells.append({
                'text': txt,
                'value': float(txt) if txt.isdigit() else 0,
                'x': x, 'y': y, 'w': w, 'h': h,
                'cx': x + w / 2, 'cy': y + h / 2,
            })

    if not dose_cells:
        return

    # For each medication, find dose cells in the same vertical band
    # We use the y-position of the medication name result to find matching dose cells
    for med in medications:
        if not med.bbox:
            continue
        med_y = med.bbox[1] if len(med.bbox) >= 2 else 0
        med_h = med.bbox[3] if len(med.bbox) >= 4 else 40
        med_cy = med_y + med_h / 2

        # Find dose cells within vertical tolerance
        tolerance = max(med_h, 30) * 1.5
        nearby = [d for d in dose_cells if abs(d['cy'] - med_cy) < tolerance]

        # Sort by x-position (left to right = morning, midday, afternoon, evening)
        nearby.sort(key=lambda d: d['x'])

        # Assign doses based on position
        if len(nearby) >= 4:
            med.morning_dose = nearby[0]['value']
            med.midday_dose = nearby[1]['value']
            med.afternoon_dose = nearby[2]['value']
            med.evening_dose = nearby[3]['value']
        elif len(nearby) == 3:
            med.morning_dose = nearby[0]['value']
            med.midday_dose = nearby[1]['value']
            med.evening_dose = nearby[2]['value']
        elif len(nearby) == 2:
            med.morning_dose = nearby[0]['value']
            med.evening_dose = nearby[1]['value']
        elif len(nearby) == 1:
            med.morning_dose = nearby[0]['value']

        active_doses = sum(1 for d in [
            med.morning_dose, med.midday_dose, med.afternoon_dose, med.evening_dose
        ] if d and d > 0)
        med.times_per_day = max(active_doses, 1)

        # Calculate duration from quantity and times_per_day if not set
        if not med.duration_days and med.total_quantity and med.times_per_day:
            med.duration_days = med.total_quantity // med.times_per_day


def parse_prescription(full_text: str, line_results: list) -> ParsedPrescription:
    """Parse raw OCR output into structured prescription data.

    Args:
        full_text: Complete OCR text output.
        line_results: List of LineResult objects from OCR engine.

    Returns:
        ParsedPrescription with extracted structured data.
    """
    rx = ParsedPrescription(full_text=full_text)
    confidences = []

    if line_results:
        for lr in line_results:
            if hasattr(lr, 'confidence'):
                confidences.append(lr.confidence)

    # Extract header information from full text
    _extract_patient_info(full_text, rx)
    _extract_date(full_text, rx)
    _extract_diagnosis(full_text, rx)
    _extract_prescriber(full_text, rx)
    _extract_facility(full_text, rx)

    # Extract medications from individual lines
    lines = full_text.split('\n') if full_text else []
    item_counter = 0

    for line in lines:
        text = line.strip()
        if not text:
            continue

        # Skip non-medication lines
        if _should_skip_line(text):
            continue

        # Check if the line looks like it contains a medication
        if not _is_medication_line(text):
            continue

        item_counter += 1
        med = _parse_medication_from_text(text, item_counter)
        if med and med.brand_name:
            # Try to find bbox from line_results
            for lr in line_results:
                lr_text = lr.text if hasattr(lr, 'text') else ''
                if med.brand_name and med.brand_name in lr_text:
                    med.bbox = lr.bbox if hasattr(lr, 'bbox') else []
                    med.confidence = lr.confidence if hasattr(lr, 'confidence') else 0.85
                    break
            rx.medications.append(med)

    # Assign dose values from nearby cells in OCR results
    _assign_doses_from_line_results(rx.medications, line_results)

    # Calculate overall confidence
    if confidences:
        rx.confidence = sum(confidences) / len(confidences)
    elif rx.medications:
        rx.confidence = 0.75
    else:
        rx.confidence = 0.5

    logger.info(
        f"Parsed prescription: {len(rx.medications)} medications, "
        f"patient={rx.patient_name or 'unknown'}, "
        f"confidence={rx.confidence:.2f}"
    )

    return rx
