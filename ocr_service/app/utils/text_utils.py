"""Text processing utilities for Khmer/English OCR prescription text.

Provides functions for script detection, numeral conversion, medication
name parsing, duration/dose/route/date parsing, and general text
normalisation used throughout the OCR pipeline.
"""

import re
import unicodedata
from datetime import datetime
from typing import Dict, List, Optional, Union

# ---------------------------------------------------------------------------
# Unicode ranges
# ---------------------------------------------------------------------------
_KHMER_RANGE = range(0x1780, 0x1800)  # U+1780 .. U+17FF
_KHMER_DIGIT_START = 0x17E0           # ០ = U+17E0

# Khmer digit mapping  ០ ១ ២ ៣ ៤ ៥ ៦ ៧ ៨ ៩
_KHMER_TO_ARABIC: Dict[str, str] = {
    chr(_KHMER_DIGIT_START + i): str(i) for i in range(10)
}

# Fraction lookup (common prescription fractions)
_FRACTION_MAP: Dict[str, float] = {
    "1/2": 0.5,
    "1/4": 0.25,
    "3/4": 0.75,
    "1/3": 0.3333,
    "2/3": 0.6667,
    "\u00bd": 0.5,   # vulgar fraction one half
    "\u00bc": 0.25,  # vulgar fraction one quarter
    "\u00be": 0.75,  # vulgar fraction three quarters
    "\u2153": 0.3333,  # vulgar fraction one third
    "\u2154": 0.6667,  # vulgar fraction two thirds
}

# Route of administration patterns
_ROUTE_PATTERNS: List[Dict[str, str]] = [
    # Latin patterns
    {"pattern": r"\bPO\b",         "value": "PO",  "description": "Oral"},
    {"pattern": r"\boral\b",       "value": "PO",  "description": "Oral"},
    {"pattern": r"\bIV\b",         "value": "IV",  "description": "Intravenous"},
    {"pattern": r"\bintravenous\b","value": "IV",  "description": "Intravenous"},
    {"pattern": r"\bIM\b",         "value": "IM",  "description": "Intramuscular"},
    {"pattern": r"\bintramuscular\b", "value": "IM", "description": "Intramuscular"},
    {"pattern": r"\bSC\b",         "value": "SC",  "description": "Subcutaneous"},
    {"pattern": r"\bSQ\b",         "value": "SC",  "description": "Subcutaneous"},
    {"pattern": r"\bsubcutaneous\b", "value": "SC", "description": "Subcutaneous"},
    {"pattern": r"\bSL\b",         "value": "SL",  "description": "Sublingual"},
    {"pattern": r"\bsublingual\b", "value": "SL",  "description": "Sublingual"},
    {"pattern": r"\btopical\b",    "value": "TOP", "description": "Topical"},
    {"pattern": r"\bINH\b",        "value": "INH", "description": "Inhalation"},
    {"pattern": r"\binhalation\b", "value": "INH", "description": "Inhalation"},
    {"pattern": r"\bPR\b",         "value": "PR",  "description": "Rectal"},
    {"pattern": r"\brectal\b",     "value": "PR",  "description": "Rectal"},
    # Khmer patterns
    {"pattern": r"\u1799\u17b6\u179f\u17c6\u1794\u17c9\u17c1\u179f",
     "value": "PO",  "description": "Oral"},                        # យាសំបែស (oral medicine)
    {"pattern": r"\u179b\u17c1\u179b",
     "value": "PO",  "description": "Oral"},                        # លេល (swallow)
    {"pattern": r"\u1785\u17b6\u1780\u17cb",
     "value": "IM",  "description": "Intramuscular"},               # ចាក់ (inject)
    {"pattern": r"\u1785\u17b6\u1780\u17cb\u179f\u17c3\u179a",
     "value": "IV",  "description": "Intravenous"},                 # ចាក់សែរ (IV inject)
    {"pattern": r"\u1785\u17b6\u1780\u17cb\u179f\u17b6\u1785\u17cb",
     "value": "IM",  "description": "Intramuscular"},               # ចាក់សាច់ (IM inject)
    {"pattern": r"\u179b\u17b6\u1794",
     "value": "TOP", "description": "Topical"},                     # លាប (apply/topical)
    {"pattern": r"\u1780\u17d2\u179a\u17c4\u1798\u17a0\u17b7\u178f",
     "value": "TOP", "description": "Topical"},                     # ក្រោមហិត (under tongue variant)
    {"pattern": r"\u1780\u17d2\u179a\u17c4\u1798\u17a2\u178e\u17d2\u178f\u17b6\u178f",
     "value": "SL",  "description": "Sublingual"},                  # ក្រោមអណ្តាត (sublingual)
]

# Khmer duration unit mapping
_KHMER_DURATION_UNITS: Dict[str, str] = {
    "\u1790\u17d2\u1784\u17c3": "days",      # ថ្ងៃ
    "\u179f\u1794\u17d2\u178f\u17b6\u17a0\u17cd": "weeks",  # សប្តាហ៍
    "\u1781\u17c2": "months",                 # ខែ
    "\u1786\u17d2\u1793\u17b6\u17c6": "years", # ឆ្នាំ
    "\u1798\u17c9\u17c4\u1784": "hours",      # ម៉ោង
    "\u1793\u17b6\u1791\u17b8": "minutes",    # នាទី
}

# Khmer note keywords that may appear after duration units
_KHMER_DURATION_NOTES: Dict[str, str] = {
    "\u179a\u17bd\u179f\u17b6\u1794\u17cb": "until finished",  # រួសាប់
    "\u179a\u17c0\u179f\u17b6\u1794\u17cb": "until finished",  # រើសាប់ (variant spelling)
    "\u1794\u1793\u17d2\u178f": "continue",                     # បន្ត
}


# ---------------------------------------------------------------------------
# 1. is_khmer_text
# ---------------------------------------------------------------------------
def is_khmer_text(text: str) -> bool:
    """Return True if *text* contains at least one Khmer-script character.

    Khmer Unicode block: U+1780 -- U+17FF.
    """
    if not text:
        return False
    return any(ord(ch) in _KHMER_RANGE for ch in text)


# ---------------------------------------------------------------------------
# 2. is_latin_text
# ---------------------------------------------------------------------------
def is_latin_text(text: str) -> bool:
    """Return True if the text is primarily composed of ASCII / Latin characters.

    Whitespace and punctuation are ignored when calculating the ratio.
    Returns False for empty strings.
    """
    if not text:
        return False
    alpha_chars = [ch for ch in text if ch.isalpha()]
    if not alpha_chars:
        return False
    latin_count = sum(1 for ch in alpha_chars if ord(ch) < 0x0250)
    return (latin_count / len(alpha_chars)) > 0.5


# ---------------------------------------------------------------------------
# 3. detect_script
# ---------------------------------------------------------------------------
def detect_script(text: str) -> str:
    """Detect the dominant script in *text*.

    Returns
    -------
    str
        One of ``'khmer'``, ``'latin'``, ``'numeric'``, or ``'mixed'``.
    """
    if not text or not text.strip():
        return "mixed"

    has_khmer = False
    has_latin = False
    has_digit = False
    alpha_count = 0

    for ch in text:
        cp = ord(ch)
        if cp in _KHMER_RANGE:
            has_khmer = True
            alpha_count += 1
        elif ch.isalpha() and cp < 0x0250:
            has_latin = True
            alpha_count += 1
        elif ch.isdigit() or cp in range(_KHMER_DIGIT_START, _KHMER_DIGIT_START + 10):
            has_digit = True

    if has_khmer and has_latin:
        return "mixed"
    if has_khmer:
        return "khmer"
    if has_latin:
        return "latin"
    if has_digit and alpha_count == 0:
        return "numeric"
    return "mixed"


# ---------------------------------------------------------------------------
# 4. khmer_numerals_to_arabic
# ---------------------------------------------------------------------------
def khmer_numerals_to_arabic(text: str) -> str:
    """Replace Khmer digit characters (U+17E0..U+17E9) with ASCII digits."""
    if not text:
        return text
    return "".join(_KHMER_TO_ARABIC.get(ch, ch) for ch in text)


# ---------------------------------------------------------------------------
# 5. normalize_text
# ---------------------------------------------------------------------------
_ZERO_WIDTH_RE = re.compile(
    "[\u200b\u200c\u200d\u200e\u200f\ufeff\u00ad\u034f\u061c"
    "\u115f\u1160\u17b4\u17b5\u180e\u2000-\u200f\u202a-\u202e"
    "\u2060-\u2064\u2066-\u206f\ufff9-\ufffb]"
)


def normalize_text(text: str) -> str:
    """Normalise OCR output text.

    * Strip leading/trailing whitespace
    * Collapse consecutive whitespace into single spaces
    * Apply Unicode NFC normalisation
    * Remove zero-width / invisible formatting characters
    """
    if not text:
        return ""
    text = unicodedata.normalize("NFC", text)
    text = _ZERO_WIDTH_RE.sub("", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


# ---------------------------------------------------------------------------
# 6. parse_medication_name
# ---------------------------------------------------------------------------
_MED_NAME_RE = re.compile(
    r"^(.+?)\s+(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|IU|%)$",
    re.IGNORECASE,
)


def parse_medication_name(text: str) -> Optional[Dict[str, str]]:
    """Parse a medication string into name, strength value, and unit.

    Examples
    --------
    >>> parse_medication_name("Butylscopolamine 10mg")
    {'name': 'Butylscopolamine', 'strength_value': '10',
     'strength_unit': 'mg', 'full_text': 'Butylscopolamine 10mg'}
    """
    if not text:
        return None
    text = normalize_text(text)
    m = _MED_NAME_RE.match(text)
    if not m:
        return None
    return {
        "name": m.group(1).strip(),
        "strength_value": m.group(2),
        "strength_unit": m.group(3).lower() if m.group(3) != "IU" else "IU",
        "full_text": text,
    }


# ---------------------------------------------------------------------------
# 7. parse_duration
# ---------------------------------------------------------------------------
def parse_duration(text: str) -> Optional[Dict[str, Optional[Union[int, str]]]]:
    """Parse a duration string in Khmer or English.

    Supported formats::

        "14 \u1790\u17d2\u1784\u17c3"          -> 14 days
        "14 \u1790\u17d2\u1784\u17c3\u179a\u17bd\u179f\u17b6\u1794\u17cb"    -> 14 days (until finished)
        "21 days"            -> 21 days
        "2 weeks"            -> 2 weeks
        "3 \u1781\u17c2"              -> 3 months

    Returns
    -------
    dict or None
        Keys: ``value``, ``unit``, ``text_original``, ``khmer_text``, ``note``.
    """
    if not text:
        return None

    original = text
    text = normalize_text(text)
    # Convert any Khmer numerals first
    text_converted = khmer_numerals_to_arabic(text)

    # Try to extract numeric value from start
    num_match = re.match(r"(\d+(?:\.\d+)?)\s*(.+)", text_converted)
    if not num_match:
        return None

    value = int(float(num_match.group(1))) if "." not in num_match.group(1) else int(float(num_match.group(1)))
    remainder = num_match.group(2).strip()

    # Try English units first
    english_units = {
        "day": "days", "days": "days",
        "week": "weeks", "weeks": "weeks",
        "month": "months", "months": "months",
        "year": "years", "years": "years",
        "hour": "hours", "hours": "hours",
        "minute": "minutes", "minutes": "minutes",
    }

    lower_remainder = remainder.lower()
    for eng_key, eng_unit in english_units.items():
        if lower_remainder == eng_key or lower_remainder.startswith(eng_key):
            return {
                "value": value,
                "unit": eng_unit,
                "text_original": original,
                "khmer_text": None,
                "note": None,
            }

    # Try Khmer units
    matched_unit: Optional[str] = None
    khmer_unit_text: Optional[str] = None
    note: Optional[str] = None

    for khmer_unit, eng_unit in _KHMER_DURATION_UNITS.items():
        if khmer_unit in remainder:
            matched_unit = eng_unit
            khmer_unit_text = khmer_unit
            # Check for trailing note keyword
            after_unit = remainder[remainder.index(khmer_unit) + len(khmer_unit):].strip()
            for note_kh, note_en in _KHMER_DURATION_NOTES.items():
                if note_kh in after_unit:
                    note = f"{note_kh} ({note_en})"
                    break
            break

    if matched_unit is None:
        return None

    return {
        "value": value,
        "unit": matched_unit,
        "text_original": original,
        "khmer_text": original if is_khmer_text(original) else None,
        "note": note,
    }


# ---------------------------------------------------------------------------
# 8. parse_dose_value
# ---------------------------------------------------------------------------
def parse_dose_value(text: str) -> Optional[Dict[str, Union[str, float, bool]]]:
    """Parse a dose value token from a prescription grid.

    Returns
    -------
    dict or None
        Keys: ``value`` (str), ``numeric`` (float), ``enabled`` (bool).

    Examples
    --------
    >>> parse_dose_value("1")
    {'value': '1', 'numeric': 1.0, 'enabled': True}
    >>> parse_dose_value("-")
    {'value': '-', 'numeric': 0.0, 'enabled': False}
    >>> parse_dose_value("1/2")
    {'value': '1/2', 'numeric': 0.5, 'enabled': True}
    """
    if text is None:
        return None

    text = normalize_text(text)
    if not text:
        return None

    # Convert Khmer numerals
    converted = khmer_numerals_to_arabic(text)

    # Disabled / empty markers
    if converted in ("-", "--", "0", "x", "X", ""):
        return {"value": text, "numeric": 0.0, "enabled": False}

    # Check fraction map (vulgar fractions)
    if converted in _FRACTION_MAP:
        return {"value": text, "numeric": _FRACTION_MAP[converted], "enabled": True}

    # Slash-style fraction (e.g. "1/2")
    frac_match = re.match(r"^(\d+)/(\d+)$", converted)
    if frac_match:
        numerator = int(frac_match.group(1))
        denominator = int(frac_match.group(2))
        if denominator != 0:
            return {
                "value": text,
                "numeric": round(numerator / denominator, 4),
                "enabled": True,
            }

    # Plain numeric
    num_match = re.match(r"^(\d+(?:\.\d+)?)$", converted)
    if num_match:
        return {
            "value": text,
            "numeric": float(num_match.group(1)),
            "enabled": float(num_match.group(1)) > 0,
        }

    # Mixed number (e.g. "1 1/2")
    mixed_match = re.match(r"^(\d+)\s+(\d+)/(\d+)$", converted)
    if mixed_match:
        whole = int(mixed_match.group(1))
        numerator = int(mixed_match.group(2))
        denominator = int(mixed_match.group(3))
        if denominator != 0:
            return {
                "value": text,
                "numeric": round(whole + numerator / denominator, 4),
                "enabled": True,
            }

    return None


# ---------------------------------------------------------------------------
# 9. detect_route
# ---------------------------------------------------------------------------
def detect_route(text: str) -> Optional[Dict[str, str]]:
    """Detect the route of administration from free text.

    Returns
    -------
    dict or None
        Keys: ``value`` (abbreviation), ``description`` (human-readable).
    """
    if not text:
        return None

    text_norm = normalize_text(text)

    for route in _ROUTE_PATTERNS:
        if re.search(route["pattern"], text_norm, re.IGNORECASE):
            return {"value": route["value"], "description": route["description"]}

    return None


# ---------------------------------------------------------------------------
# 10. parse_date
# ---------------------------------------------------------------------------
_DATE_PATTERNS = [
    # DD/MM/YYYY
    (re.compile(r"^(\d{1,2})/(\d{1,2})/(\d{4})$"), "dmy", "/"),
    # DD-MM-YYYY
    (re.compile(r"^(\d{1,2})-(\d{1,2})-(\d{4})$"), "dmy", "-"),
    # YYYY-MM-DD (ISO)
    (re.compile(r"^(\d{4})-(\d{1,2})-(\d{1,2})$"), "ymd", "-"),
    # YYYY/MM/DD
    (re.compile(r"^(\d{4})/(\d{1,2})/(\d{1,2})$"), "ymd", "/"),
    # DD.MM.YYYY
    (re.compile(r"^(\d{1,2})\.(\d{1,2})\.(\d{4})$"), "dmy", "."),
]


def parse_date(text: str) -> Optional[Dict[str, str]]:
    """Parse a date string into ISO-8601 date (YYYY-MM-DD).

    Supported input formats::

        15/06/2025   (DD/MM/YYYY)
        15-06-2025   (DD-MM-YYYY)
        2025-06-15   (YYYY-MM-DD)
        2025/06/15   (YYYY/MM/DD)
        15.06.2025   (DD.MM.YYYY)

    Returns
    -------
    dict or None
        Keys: ``value`` (ISO date str), ``original_format`` (input str).
    """
    if not text:
        return None

    text = normalize_text(text)
    text = khmer_numerals_to_arabic(text)

    for pattern, order, _sep in _DATE_PATTERNS:
        m = pattern.match(text)
        if not m:
            continue
        try:
            if order == "dmy":
                day, month, year = int(m.group(1)), int(m.group(2)), int(m.group(3))
            else:  # ymd
                year, month, day = int(m.group(1)), int(m.group(2)), int(m.group(3))

            dt = datetime(year, month, day)
            return {
                "value": dt.strftime("%Y-%m-%d"),
                "original_format": text,
            }
        except (ValueError, OverflowError):
            continue

    return None


# ---------------------------------------------------------------------------
# 11. parse_datetime
# ---------------------------------------------------------------------------
_DATETIME_PATTERNS = [
    # DD/MM/YYYY HH:MM[:SS]
    (re.compile(
        r"^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$"
    ), "dmy"),
    # DD-MM-YYYY HH:MM[:SS]
    (re.compile(
        r"^(\d{1,2})-(\d{1,2})-(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$"
    ), "dmy"),
    # YYYY-MM-DD HH:MM[:SS]
    (re.compile(
        r"^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$"
    ), "ymd"),
    # YYYY/MM/DD HH:MM[:SS]
    (re.compile(
        r"^(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$"
    ), "ymd"),
    # DD.MM.YYYY HH:MM[:SS]
    (re.compile(
        r"^(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$"
    ), "dmy"),
]


def parse_datetime(text: str) -> Optional[Dict[str, str]]:
    """Parse a date-time string and return an ISO-8601 representation.

    Supported input formats::

        15/06/2025 14:20
        2025-06-15 14:20:30
        15.06.2025 08:00

    Returns
    -------
    dict or None
        Keys: ``value`` (ISO-8601 datetime str), ``original_format`` (input str).
    """
    if not text:
        return None

    text = normalize_text(text)
    text = khmer_numerals_to_arabic(text)

    for pattern, order in _DATETIME_PATTERNS:
        m = pattern.match(text)
        if not m:
            continue
        try:
            if order == "dmy":
                day, month, year = int(m.group(1)), int(m.group(2)), int(m.group(3))
                hour, minute = int(m.group(4)), int(m.group(5))
            else:  # ymd
                year, month, day = int(m.group(1)), int(m.group(2)), int(m.group(3))
                hour, minute = int(m.group(4)), int(m.group(5))

            second = int(m.group(6)) if m.group(6) else 0
            dt = datetime(year, month, day, hour, minute, second)
            return {
                "value": dt.isoformat(),
                "original_format": text,
            }
        except (ValueError, OverflowError):
            continue

    return None
