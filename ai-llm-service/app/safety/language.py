"""
Language Validation Module
Validates and detects languages in input/output
Supports: English, Khmer, French
"""

import re
import logging
from typing import List, Tuple, Optional

logger = logging.getLogger(__name__)

# Language detection patterns
LANGUAGE_PATTERNS = {
    "kh": {
        "name": "Khmer",
        "unicode_range": (0x1780, 0x17FF),
        "sample_chars": "កខគឃង",
    },
    "en": {
        "name": "English",
        "pattern": r"^[a-zA-Z\s\d\.,!?;:\'\"-]+$",
    },
    "fr": {
        "name": "French",
        "special_chars": "àâäéèêëïîôùûüÿçœæ",
        "common_words": ["le", "la", "les", "de", "du", "des", "un", "une", "et", "ou", "avec"],
    }
}

SUPPORTED_LANGUAGES = ["en", "kh", "fr"]


def detect_language(text: str) -> str:
    """
    Detect primary language of text.

    Args:
        text: Input text

    Returns:
        Language code: "en", "kh", "fr", or "mixed"
    """
    if not text:
        return "unknown"

    # Check for Khmer characters
    khmer_count = sum(1 for c in text if 0x1780 <= ord(c) <= 0x17FF)

    # Check for French special characters
    french_chars = LANGUAGE_PATTERNS["fr"]["special_chars"]
    french_count = sum(1 for c in text.lower() if c in french_chars)

    # Check for French common words
    words = text.lower().split()
    french_words = sum(1 for w in words if w in LANGUAGE_PATTERNS["fr"]["common_words"])

    total_chars = len([c for c in text if c.isalpha()])

    if total_chars == 0:
        return "unknown"

    khmer_ratio = khmer_count / total_chars

    # Determine language
    if khmer_ratio > 0.5:
        return "kh"
    elif khmer_ratio > 0.1:
        return "mixed"
    elif french_count > 2 or french_words > 2:
        return "fr"
    else:
        return "en"


def detect_languages(text: str) -> List[str]:
    """
    Detect all languages present in text.

    Args:
        text: Input text

    Returns:
        List of language codes found
    """
    languages = set()

    # Check Khmer
    if any(0x1780 <= ord(c) <= 0x17FF for c in text):
        languages.add("kh")

    # Check French
    french_chars = LANGUAGE_PATTERNS["fr"]["special_chars"]
    if any(c in french_chars for c in text.lower()):
        languages.add("fr")

    # Check English (Latin alphabet without French special chars)
    if re.search(r"[a-zA-Z]", text):
        if "fr" not in languages:
            languages.add("en")
        else:
            # Could be both
            languages.add("en")

    return list(languages) if languages else ["unknown"]


def validate_language_support(text: str) -> Tuple[bool, str]:
    """
    Validate that text language is supported.

    Args:
        text: Input text

    Returns:
        Tuple of (is_supported, detected_language)
    """
    lang = detect_language(text)

    if lang == "unknown":
        return True, lang  # Allow unknown (might be numbers/symbols)

    if lang == "mixed":
        return True, lang  # Mixed is supported

    return lang in SUPPORTED_LANGUAGES, lang


def get_response_language(input_text: str, preferred: str = None) -> str:
    """
    Determine what language to respond in.

    Args:
        input_text: User's input
        preferred: User's preferred language

    Returns:
        Language code for response
    """
    if preferred and preferred in SUPPORTED_LANGUAGES:
        return preferred

    detected = detect_language(input_text)

    if detected in SUPPORTED_LANGUAGES:
        return detected

    return "en"  # Default to English


def translate_key_terms(text: str, from_lang: str, to_lang: str) -> str:
    """
    Translate key medical terms between languages.
    Note: This is a simplified version - would use proper translation API in production.

    Args:
        text: Input text
        from_lang: Source language
        to_lang: Target language

    Returns:
        Text with translated terms
    """
    # Key term translations (simplified)
    translations = {
        ("kh", "en"): {
            "ថ្នាំ": "medicine",
            "ព្រឹក": "morning",
            "ថ្ org": "noon",
            "ល្ org": "afternoon",
            "យប់": "night",
            "គ្រាប់": "tablets",
        },
        ("en", "kh"): {
            "medicine": "ថ្នាំ",
            "morning": "ព្រឹក",
            "noon": " org org org",
            "afternoon": "org org org",
            "night": "យប org",
            "tablets": "គ org org org",
        }
    }

    term_map = translations.get((from_lang, to_lang), {})

    result = text
    for source, target in term_map.items():
        result = result.replace(source, target)

    return result


def format_bilingual_instructions(
    text_en: str,
    text_kh: Optional[str] = None
) -> str:
    """
    Format instructions in bilingual format.

    Args:
        text_en: English text
        text_kh: Khmer text (optional)

    Returns:
        Formatted bilingual text
    """
    if text_kh:
        return f"🇬🇧 {text_en}\n🇰🇭 {text_kh}"
    return text_en

