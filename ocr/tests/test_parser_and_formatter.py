from types import SimpleNamespace

from app.pipeline.formatter import build_dynamic_universal, build_extraction_summary
from app.pipeline.text_parser import parse_prescription, parse_table_medications


def test_parse_prescription_extracts_header_and_medication() -> None:
    lines = [
        SimpleNamespace(text="Name: Sok Dara Age: 42 Sex: M ID: AB1234", confidence=0.95, bbox=[0, 0, 10, 10]),
        SimpleNamespace(text="ថ្ងៃទី 22/06/2025", confidence=0.99, bbox=[0, 10, 10, 10]),
        SimpleNamespace(text="Amoxicillin 500mg cap 1-0-1 7 days", confidence=0.90, bbox=[0, 20, 10, 10]),
        SimpleNamespace(text="Dr. Heng Kimang", confidence=0.93, bbox=[0, 30, 10, 10]),
    ]

    parsed = parse_prescription("\n".join(line.text for line in lines), lines)

    assert parsed.patient_name == "Sok Dara"
    assert parsed.patient_age == 42
    assert parsed.patient_gender == "M"
    assert parsed.patient_id == "AB1234"
    assert parsed.issue_date == "2025-06-22"
    assert len(parsed.medications) == 1
    assert parsed.medications[0].name_full == "Amoxicillin"
    assert parsed.medications[0].strength_value == "500mg"
    assert parsed.medications[0].times_per_day == 2


def test_formatter_matches_backend_contract_subset() -> None:
    lines = [
        SimpleNamespace(text="Patient: Jane Doe Age: 30 Sex: F", confidence=0.91, bbox=[0, 0, 10, 10]),
        SimpleNamespace(text="Paracetamol 500mg tablet 3x1 5 days", confidence=0.88, bbox=[0, 10, 10, 10]),
    ]
    parsed = parse_prescription("\n".join(line.text for line in lines), lines)

    data = build_dynamic_universal(parsed, processing_time_ms=123.4, image_width=100, image_height=200)
    summary = build_extraction_summary(data, 123.4)
    prescription = data["prescription"]
    item = prescription["medications"]["items"][0]

    assert data["$schema"] == "cambodia-prescription-universal-v2.0"
    assert prescription["patient"]["personal_info"]["name"]["full_name"] == "Jane Doe"
    assert prescription["medications"]["summary"]["total_medications"] == 1
    assert item["medication"]["name"]["full_text"] == "Paracetamol"
    assert item["dosing"]["schedule"]["frequency"]["times_per_day"] == 3
    assert summary["total_medications"] == 1
    assert summary["processing_time_ms"] == 123.4


def test_parse_table_medications_handles_khmer_quantity_and_split_doses() -> None:
    rows = [
        ["11", "Buttylscopoliamine", "14គ្រាប់", "1", "11"],
        ["F21", "| Cellcoxx 100mg", "14គ្រាប់ស្រោប", "11", "11"],
        ["| Multivitamine", "21គ្រាប់", "11"],
    ]

    meds = parse_table_medications(rows)

    assert len(meds) == 3

    assert meds[0].name_full == "Buttylscopoliamine"
    assert meds[0].total_quantity == 14
    assert meds[0].morning_dose == 1.0
    assert meds[0].evening_dose == 1.0
    assert meds[0].times_per_day == 2
    assert meds[0].duration_days == 7

    assert meds[1].name_full == "Cellcoxx"
    assert meds[1].strength_value == "100mg"
    assert meds[1].form == "capsule"
    assert meds[1].total_quantity == 14
    assert meds[1].morning_dose == 1.0
    assert meds[1].evening_dose == 1.0

    assert meds[2].name_full == "Multivitamine"
    assert meds[2].total_quantity == 21
    assert meds[2].morning_dose == 1.0
    assert meds[2].times_per_day == 1
    assert meds[2].duration_days == 21


def test_parse_table_medications_skips_footer_like_rows() -> None:
    rows = [
        ["រាជធានីភ្នំពេញ,ថ្ងៃទី//2025 14:20"],
        ["គ្រពេទ្យព្យាបាល -"],
        ["Srikes"],
        ["| Omeprazzole 20mg", "14គ្រាប់", "1", "11"],
    ]

    meds = parse_table_medications(rows)

    assert len(meds) == 1
    assert meds[0].name_full == "Omeprazzole"
    assert meds[0].strength_value == "20mg"
    assert meds[0].total_quantity == 14