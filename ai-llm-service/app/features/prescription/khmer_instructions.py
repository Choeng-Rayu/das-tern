"""
Khmer Instructions Generator Module
Generates Khmer language instructions for medication reminders.

This module provides functionality to create accurate Khmer instructions
like "លេប ១ គ្រាប់" (take 1 tablet) based on dosage, unit, and timing.
"""

from typing import Optional

# Khmer numerals mapping
KHMER_NUMBERS = {
    0: "០", 1: "១", 2: "២", 3: "៣", 4: "៤",
    5: "៥", 6: "៦", 7: "៧", 8: "៨", 9: "៩"
}

# Khmer words for common numbers (for natural language)
KHMER_NUMBER_WORDS = {
    1: "មួយ",    # one
    2: "ពីរ",    # two
    3: "បី",     # three
    4: "បួន",    # four
    5: "ប្រាំ",   # five
    6: "ប្រាំមួយ", # six
    7: "ប្រាំពីរ", # seven
    8: "ប្រាំបី",  # eight
    9: "ប្រាំបួន", # nine
    10: "ដប់",   # ten
}

# Khmer unit translations
KHMER_UNITS = {
    # Tablets and pills
    "tablet": "គ្រាប់",
    "tablets": "គ្រាប់",
    "pill": "គ្រាប់",
    "pills": "គ្រាប់",
    "គ្រាប់": "គ្រាប់",
    
    # Capsules
    "capsule": "គ្រាប់សំប៉ែត",
    "capsules": "គ្រាប់សំប៉ែត",
    "គ្រាប់សំប៉ែត": "គ្រាប់សំប៉ែត",
    
    # Ampoules/Injections
    "ampoule": "អំពូល",
    "ampoules": "អំពូល",
    "amp": "អំពូល",
    "អំពូល": "អំពូល",
    
    # Liquid measurements
    "ml": "មីលីលីត្រ",
    "milliliter": "មីលីលីត្រ",
    "spoon": "ស្លាបព្រា",
    "teaspoon": "ស្លាបព្រាតូច",
    "tablespoon": "ស្លាបព្រាធំ",
    
    # Drops
    "drop": "ដំណក់",
    "drops": "ដំណក់",
    
    # Patches/external
    "patch": "បិទភ្ជាប់",
    "sachet": "កញ្ចប់",
    
    # Default fallback
    "dose": "ដូស",
}

# Khmer action verbs
KHMER_VERBS = {
    "oral": "លេប",          # swallow/take orally
    "take": "លេប",          # take (generic)
    "inject": "ចាក់",       # inject
    "apply": "ប្រើ",        # use/apply
    "use": "ប្រើ",          # use
    "inhale": "ស្រូប",       # inhale
    "drink": "ផឹក",         # drink
}

# Khmer time context phrases
KHMER_TIME_CONTEXT = {
    "before_meal": "មុនបាយ",       # before meal
    "after_meal": "ក្រោយបាយ",      # after meal
    "with_meal": "ពេលបាយ",         # with meal
    "empty_stomach": "ពោះទទេ",    # empty stomach
    "before_sleep": "មុនគេង",      # before sleep
    "every_day": "រាល់ថ្ងៃ",       # every day
}

# Time slot translations
KHMER_TIME_SLOTS = {
    "morning": "ព្រឹក",
    "noon": "ថ្ងៃត្រង់",
    "afternoon": "រសៀល",
    "evening": "ល្ងាច",
    "night": "យប់",
}


def number_to_khmer_numeral(number: int) -> str:
    """
    Convert an integer to Khmer numerals.
    
    Args:
        number: Integer to convert (e.g., 14)
        
    Returns:
        Khmer numeral string (e.g., "១៤")
    """
    if number < 0:
        return "-" + number_to_khmer_numeral(abs(number))
    
    result = ""
    for digit in str(number):
        result += KHMER_NUMBERS.get(int(digit), digit)
    return result


def get_khmer_unit(unit: str) -> str:
    """
    Get Khmer translation for a medication unit.
    
    Args:
        unit: English unit name (e.g., "Tablet", "Capsule")
        
    Returns:
        Khmer unit translation (e.g., "គ្រាប់")
    """
    unit_lower = unit.lower().strip()
    return KHMER_UNITS.get(unit_lower, KHMER_UNITS.get("dose", "ដូស"))


def get_khmer_verb(action: str = "oral") -> str:
    """
    Get Khmer verb for medication action.
    
    Args:
        action: Action type (e.g., "oral", "inject", "apply")
        
    Returns:
        Khmer verb (e.g., "លេប")
    """
    action_lower = action.lower().strip()
    return KHMER_VERBS.get(action_lower, KHMER_VERBS["take"])


def generate_khmer_instruction(
    quantity: int,
    unit: str,
    action: str = "oral",
    context: Optional[str] = None
) -> str:
    """
    Generate a complete Khmer instruction for medication reminder.
    
    Args:
        quantity: Number of units to take (e.g., 1, 2)
        unit: Unit type (e.g., "Tablet", "Capsule", "Ampoule")
        action: Action verb type (e.g., "oral", "inject")
        context: Optional context (e.g., "after_meal", "before_sleep")
        
    Returns:
        Complete Khmer instruction (e.g., "លេប ១ គ្រាប់ ក្រោយបាយ")
        
    Examples:
        >>> generate_khmer_instruction(1, "Tablet")
        'លេប ១ គ្រាប់'
        
        >>> generate_khmer_instruction(2, "Capsule", context="after_meal")
        'លេប ២ គ្រាប់សំប៉ែត ក្រោយបាយ'
        
        >>> generate_khmer_instruction(1, "Ampoule", action="inject")
        'ប្រើ ១ អំពូល'
    """
    # Get verb
    verb = get_khmer_verb(action)
    
    # Convert quantity to Khmer numeral
    khmer_quantity = number_to_khmer_numeral(quantity)
    
    # Get unit translation
    khmer_unit = get_khmer_unit(unit)
    
    # Build base instruction
    instruction = f"{verb} {khmer_quantity} {khmer_unit}"
    
    # Add context if provided
    if context:
        context_lower = context.lower().replace(" ", "_")
        khmer_context = KHMER_TIME_CONTEXT.get(context_lower, "")
        if khmer_context:
            instruction += f" {khmer_context}"
    
    return instruction


def get_khmer_time_slot(time_slot: str) -> str:
    """
    Get Khmer translation for a time slot.
    
    Args:
        time_slot: English time slot (e.g., "Morning", "Evening")
        
    Returns:
        Khmer time slot (e.g., "ព្រឹក")
    """
    return KHMER_TIME_SLOTS.get(time_slot.lower(), time_slot)


def generate_full_reminder_text(
    medication_name: str,
    quantity: int,
    unit: str,
    time_slot: str,
    context: Optional[str] = None
) -> str:
    """
    Generate a complete reminder notification text in Khmer.
    
    Args:
        medication_name: Name of medication
        quantity: Dosage quantity
        unit: Dosage unit
        time_slot: Time of day (Morning, Noon, Evening, Night)
        context: Optional context (after_meal, etc.)
        
    Returns:
        Full reminder text in Khmer
        
    Example:
        >>> generate_full_reminder_text("Omeprazole 20mg", 1, "Tablet", "Morning", "before_meal")
        'ពេល ព្រឹក៖ លេប ១ គ្រាប់ Omeprazole 20mg មុនបាយ'
    """
    khmer_time = get_khmer_time_slot(time_slot)
    instruction = generate_khmer_instruction(quantity, unit, context=context)
    
    return f"ពេល {khmer_time}៖ {instruction} {medication_name}"


# Convenience function for API use
def create_reminder_instruction(
    dosage_quantity: int,
    dosage_unit: str,
    meal_context: Optional[str] = None
) -> str:
    """
    API-friendly function to create reminder instruction.
    
    This is the main function called by the reminder generator.
    
    Args:
        dosage_quantity: Number of units
        dosage_unit: Unit type
        meal_context: Optional meal timing context
        
    Returns:
        Khmer instruction string
    """
    return generate_khmer_instruction(
        quantity=dosage_quantity,
        unit=dosage_unit,
        context=meal_context
    )
