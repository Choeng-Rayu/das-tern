#!/usr/bin/env python3
"""
Test Suite: Khmer Instructions Module
Tests for Khmer instruction generation for medication reminders.
"""

import sys
import os

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import pytest


class TestKhmerNumbers:
    """Test Khmer number conversion."""
    
    def test_single_digit_numbers(self):
        """Test single digit conversions."""
        from app.features.prescription.khmer_instructions import number_to_khmer_numeral
        
        assert number_to_khmer_numeral(0) == "០"
        assert number_to_khmer_numeral(1) == "១"
        assert number_to_khmer_numeral(5) == "៥"
        assert number_to_khmer_numeral(9) == "៩"
    
    def test_multi_digit_numbers(self):
        """Test multi-digit number conversions."""
        from app.features.prescription.khmer_instructions import number_to_khmer_numeral
        
        assert number_to_khmer_numeral(10) == "១០"
        assert number_to_khmer_numeral(14) == "១៤"
        assert number_to_khmer_numeral(21) == "២១"
        assert number_to_khmer_numeral(100) == "១០០"


class TestKhmerUnits:
    """Test Khmer unit translations."""
    
    def test_tablet_translation(self):
        """Test tablet unit translations."""
        from app.features.prescription.khmer_instructions import get_khmer_unit
        
        assert get_khmer_unit("tablet") == "គ្រាប់"
        assert get_khmer_unit("Tablet") == "គ្រាប់"
        assert get_khmer_unit("tablets") == "គ្រាប់"
        assert get_khmer_unit("pill") == "គ្រាប់"
    
    def test_capsule_translation(self):
        """Test capsule unit translation."""
        from app.features.prescription.khmer_instructions import get_khmer_unit
        
        assert get_khmer_unit("capsule") == "គ្រាប់សំប៉ែត"
        assert get_khmer_unit("Capsule") == "គ្រាប់សំប៉ែត"
    
    def test_ampoule_translation(self):
        """Test ampoule unit translation."""
        from app.features.prescription.khmer_instructions import get_khmer_unit
        
        assert get_khmer_unit("ampoule") == "អំពូល"
        assert get_khmer_unit("amp") == "អំពូល"
    
    def test_fallback_unit(self):
        """Test fallback for unknown units."""
        from app.features.prescription.khmer_instructions import get_khmer_unit
        
        assert get_khmer_unit("unknown_unit") == "ដូស"


class TestKhmerInstructions:
    """Test complete Khmer instruction generation."""
    
    def test_simple_tablet_instruction(self):
        """Test basic tablet instruction."""
        from app.features.prescription.khmer_instructions import generate_khmer_instruction
        
        result = generate_khmer_instruction(1, "Tablet")
        assert result == "លេប ១ គ្រាប់"
    
    def test_multiple_tablets(self):
        """Test instruction with multiple tablets."""
        from app.features.prescription.khmer_instructions import generate_khmer_instruction
        
        result = generate_khmer_instruction(2, "Tablet")
        assert result == "លេប ២ គ្រាប់"
    
    def test_capsule_instruction(self):
        """Test capsule instruction."""
        from app.features.prescription.khmer_instructions import generate_khmer_instruction
        
        result = generate_khmer_instruction(1, "Capsule")
        assert result == "លេប ១ គ្រាប់សំប៉ែត"
    
    def test_ampoule_with_context(self):
        """Test ampoule instruction with after_meal context."""
        from app.features.prescription.khmer_instructions import generate_khmer_instruction
        
        result = generate_khmer_instruction(1, "Ampoule", context="after_meal")
        assert "អំពូល" in result
        assert "ក្រោយបាយ" in result
    
    def test_before_meal_context(self):
        """Test instruction with before meal context."""
        from app.features.prescription.khmer_instructions import generate_khmer_instruction
        
        result = generate_khmer_instruction(1, "Tablet", context="before_meal")
        assert "គ្រាប់" in result
        assert "មុនបាយ" in result


class TestTimeSlots:
    """Test time slot translations."""
    
    def test_khmer_time_slots(self):
        """Test Khmer time slot translations."""
        from app.features.prescription.khmer_instructions import get_khmer_time_slot
        
        assert get_khmer_time_slot("morning") == "ព្រឹក"
        assert get_khmer_time_slot("noon") == "ថ្ងៃត្រង់"
        assert get_khmer_time_slot("evening") == "ល្ងាច"
        assert get_khmer_time_slot("night") == "យប់"


class TestReminderInstruction:
    """Test the main API function."""
    
    def test_create_reminder_instruction(self):
        """Test the main API function for reminders."""
        from app.features.prescription.khmer_instructions import create_reminder_instruction
        
        result = create_reminder_instruction(1, "Tablet")
        assert result == "លេប ១ គ្រាប់"
        
        result_with_context = create_reminder_instruction(1, "Tablet", "after_meal")
        assert "ក្រោយបាយ" in result_with_context


# Run tests if executed directly
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
