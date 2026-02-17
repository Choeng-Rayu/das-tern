"""Text normalization and utility functions for Khmer/English text."""
import re
from typing import Optional, Tuple

# Khmer numeral mapping
KHMER_DIGITS = {
    '០': '0', '១': '1', '២': '2', '៣': '3', '៤': '4',
    '៥': '5', '៦': '6', '៧': '7', '៨': '8', '៩': '9'
}

# Unicode ranges
KHMER_RANGE = (0x1780, 0x17FF)
ASCII_RANGE = (0x0020, 0x007F)


def is_khmer_text(text: str) -> bool:
    """Check if text contains Khmer script characters."""
    for ch in text:
        if KHMER_RANGE[0] <= ord(ch) <= KHMER_RANGE[1]:
            return True
    return False


def is_english_text(text: str) -> bool:
    """Check if text is predominantly ASCII/English."""
    ascii_count = sum(1 for ch in text if ASCII_RANGE[0] <= ord(ch) <= ASCII_RANGE[1])
    return ascii_count > len(text) * 0.5 if text else False


def is_mixed_text(text: str) -> bool:
    """Check if text contains both Khmer and English."""
    return is_khmer_text(text) and is_english_text(text)


def detect_language(text: str) -> str:
    """Detect dominant language in text. Returns 'khmer', 'english', or 'mixed'."""
    if not text or not text.strip():
        return "english"
    if is_mixed_text(text):
        return "mixed"
    if is_khmer_text(text):
        return "khmer"
    return "english"


def convert_khmer_numerals(text: str) -> str:
    """Convert Khmer numerals to Arabic numerals."""
    result = text
    for khmer, arabic in KHMER_DIGITS.items():
        result = result.replace(khmer, arabic)
    return result


def normalize_text(text: str) -> str:
    """Normalize text: strip whitespace, fix common OCR errors."""
    if not text:
        return ""
    text = text.strip()
    text = re.sub(r'\s+', ' ', text)
    text = convert_khmer_numerals(text)
    return text


def parse_dose_value(text: str) -> Tuple[float, bool]:
    """Parse dose value from text. Returns (numeric_value, is_enabled).

    Examples: "1" -> (1.0, True), "-" -> (0.0, False), "1/2" -> (0.5, True), "½" -> (0.5, True)
    """
    text = text.strip()
    if not text or text in ('-', '—', '_', '0', ''):
        return 0.0, False

    # Handle fraction characters
    fraction_map = {'½': 0.5, '¼': 0.25, '¾': 0.75, '⅓': 0.333, '⅔': 0.667}
    if text in fraction_map:
        return fraction_map[text], True

    # Handle "1/2" style fractions
    frac_match = re.match(r'^(\d+)\s*/\s*(\d+)$', text)
    if frac_match:
        num, den = int(frac_match.group(1)), int(frac_match.group(2))
        if den > 0:
            return round(num / den, 3), True

    # Handle "1 1/2" style mixed fractions
    mixed_match = re.match(r'^(\d+)\s+(\d+)\s*/\s*(\d+)$', text)
    if mixed_match:
        whole = int(mixed_match.group(1))
        num = int(mixed_match.group(2))
        den = int(mixed_match.group(3))
        if den > 0:
            return round(whole + num / den, 3), True

    # Try simple numeric
    try:
        val = float(text)
        return val, val > 0
    except ValueError:
        # Try extracting digits
        digits = re.findall(r'[\d.]+', text)
        if digits:
            try:
                val = float(digits[0])
                return val, val > 0
            except ValueError:
                pass
    return 0.0, False


def parse_medication_name(text: str) -> Tuple[str, Optional[str], Optional[str]]:
    """Parse medication text into (name, strength_value, strength_unit).

    Examples:
        "Butylscopolamine 10mg" -> ("Butylscopolamine", "10", "mg")
        "Omeprazole 20mg" -> ("Omeprazole", "20", "mg")
        "Multivitamine" -> ("Multivitamine", None, None)
    """
    text = normalize_text(text)
    if not text:
        return "", None, None

    # Pattern: name followed by strength (e.g., "10mg", "100 mg", "0.5g")
    pattern = r'^(.+?)\s+(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|IU|%|mEq|mmol|units?)$'
    match = re.match(pattern, text, re.IGNORECASE)
    if match:
        name = match.group(1).strip()
        strength_val = match.group(2)
        strength_unit = match.group(3)
        return name, strength_val, strength_unit

    return text, None, None


def parse_duration(text: str) -> Tuple[Optional[int], str, Optional[str]]:
    """Parse duration text. Returns (days, unit, note).

    Examples:
        "14 ថ្ងៃ" -> (14, "days", None)
        "14 ថ្ងៃរួសាប់" -> (14, "days", "រួសាប់ (until finished)")
        "21 days" -> (21, "days", None)
    """
    text = convert_khmer_numerals(normalize_text(text))
    if not text:
        return None, "days", None

    note = None
    if 'រួសាប់' in text:
        note = "រួសាប់ (until finished)"

    # Extract number
    num_match = re.search(r'(\d+)', text)
    if not num_match:
        return None, "days", note

    value = int(num_match.group(1))

    # Detect unit
    unit = "days"
    if re.search(r'(weeks?|សប្ដាហ៍)', text, re.IGNORECASE):
        unit = "weeks"
        value = value * 7  # Convert to days
    elif re.search(r'(months?|ខែ)', text, re.IGNORECASE):
        unit = "months"

    return value, unit, note


def parse_date(text: str) -> Optional[str]:
    """Parse date from various formats to ISO format (YYYY-MM-DD).

    Supports: DD/MM/YYYY, DD-MM-YYYY, YYYY/MM/DD, YYYY-MM-DD
    """
    text = convert_khmer_numerals(normalize_text(text))

    # DD/MM/YYYY or DD-MM-YYYY
    match = re.match(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})', text)
    if match:
        day, month, year = match.group(1), match.group(2), match.group(3)
        return f"{year}-{month.zfill(2)}-{day.zfill(2)}"

    # YYYY/MM/DD or YYYY-MM-DD
    match = re.match(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})', text)
    if match:
        return f"{match.group(1)}-{match.group(2).zfill(2)}-{match.group(3).zfill(2)}"

    return None


def parse_datetime(text: str) -> Optional[str]:
    """Parse datetime string to ISO format."""
    text = convert_khmer_numerals(normalize_text(text))

    # DD/MM/YYYY HH:MM
    match = re.match(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})\s+(\d{1,2}):(\d{2})', text)
    if match:
        day, month, year = match.group(1), match.group(2), match.group(3)
        hour, minute = match.group(4), match.group(5)
        return f"{year}-{month.zfill(2)}-{day.zfill(2)}T{hour.zfill(2)}:{minute}:00+07:00"

    return None
