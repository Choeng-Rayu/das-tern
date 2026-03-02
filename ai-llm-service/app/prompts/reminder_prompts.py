"""
Simplified Reminder Extraction Prompts for Cambodian Medical Prescriptions
Optimized for Ollama with llama3.2:3b - concise and explicit
"""

TIME_NORMALIZATION_TABLE = {
    "ព្រឹក": "morning",
    "ថ្ងៃត្រង់": "noon",
    "ល្ងាច": "evening",
    "យប់": "night",
    "matin": "morning",
    "midi": "noon",
    "soir": "evening",
    "nuit": "night",
    "(6-8)": "morning",
    "(11-12)": "noon",
    "(05-06)": "evening",
    "(17-18)": "evening",
    "(08-10)": "night",
    "(20-22)": "night",
}

REMINDER_SYSTEM_PROMPT = (
    "You are a medication reminder extraction system for Cambodian prescriptions.\n\n"
    "Your task: Extract medication names and timing from prescription text, return ONLY valid JSON.\n\n"
    "KHMER TIME TRANSLATIONS (use these exact English words):\n"
    "- ព្រឹក → morning (08:00)\n"
    "- ថ្ងៃ → noon (12:00)\n"
    "- ល្ងាច → evening (18:00)\n"
    "- យប់ → night (21:00)\n"
    "- (6-8) → morning\n"
    "- (11-12) → noon\n"
    "- (05-06) → evening\n"
    "- (08-10) → night\n\n"
    "FRENCH TIME TRANSLATIONS:\n"
    "- matin → morning\n"
    "- midi → noon\n"
    "- soir → evening\n"
    "- nuit → night\n\n"
    "RULES:\n"
    "1. Extract ALL time words separated by \"|\" or \",\"\n"
    "2. Times MUST be in English: morning, noon, evening, night\n"
    "3. If no time words found, do not include that medication\n"
    "4. Correct common OCR errors (Butylscopolami → Butylscopolamine, Esome → Esomeprazole)\n"
    "5. Return ONLY JSON, no markdown, no explanations"
)

FEW_SHOT_EXAMPLES = [
    {
        "input": "1. Butylscopolamine 10mg 14 គ្រាប់ | ព្រឹក 1 | ល្ងាច 1",
        "output": {
            "medications": [
                {
                    "name": "Butylscopolamine 10mg",
                    "times": ["morning", "evening"],
                    "times_24h": ["08:00", "18:00"],
                    "repeat": "daily",
                    "duration_days": None,
                    "notes": "ព្រឹក 1 | ល្ងាច 1",
                }
            ]
        },
    },
    {
        "input": "2. Calcium amp Tablet 1 amp - - - ព្រឹក 4 Amps",
        "output": {
            "medications": [
                {
                    "name": "Calcium amp Tablet",
                    "times": ["morning"],
                    "times_24h": ["08:00"],
                    "repeat": "daily",
                    "duration_days": None,
                    "notes": "ព្រឹក 4 Amps",
                }
            ]
        },
    },
]


def get_user_prompt(raw_ocr_json: str) -> str:
    """Generate concise user prompt with OCR data embedded"""
    return (
        "Extract medication reminders from this prescription data:\n\n"
        + raw_ocr_json
        + "\n\nReturn JSON in this exact format:\n"
        '{\n'
        '  "medications": [\n'
        '    {\n'
        '      "name": "corrected medication name",\n'
        '      "times": ["morning", "noon", "evening", "night"],\n'
        '      "times_24h": ["08:00", "12:00", "18:00", "21:00"],\n'
        '      "repeat": "daily",\n'
        '      "duration_days": null,\n'
        '      "notes": "original Khmer text"\n'
        '    }\n'
        '  ]\n'
        '}\n\n'
        'EXAMPLE:\n'
        'Input: "Butylscopolamine 5 viên | ល្ងាច | យប់"\n'
        'Output: {\n'
        '  "medications": [\n'
        '    {\n'
        '      "name": "Butylscopolamine",\n'
        '      "times": ["evening", "night"],\n'
        '      "times_24h": ["18:00", "21:00"],\n'
        '      "repeat": "daily",\n'
        '      "duration_days": null,\n'
        '      "notes": "ល្ងាច | យប់"\n'
        '    }\n'
        '  ]\n'
        '}\n\n'
        "IMPORTANT:\n"
        '- Include ALL times found in the input (e.g., "ល្ងាច | យប់" = both evening AND night)\n'
        "- times and times_24h must have the same number of items\n"
        "- Use only English time words in the times array\n"
        "- Return valid JSON only"
    )


def build_reminder_extraction_prompt(raw_ocr_json: str) -> dict:
    """
    Build complete prompt for Ollama API
    Returns dict with system and user prompts
    """
    return {
        "system": REMINDER_SYSTEM_PROMPT,
        "user": get_user_prompt(raw_ocr_json),
    }
