"""Pydantic models for static bbox format (debug/internal use)."""
from pydantic import BaseModel, Field
from typing import Optional, List, Any, Dict


class FieldWithBBox(BaseModel):
    """A field value with bounding box and confidence."""
    value: Any = None
    bbox: Optional[List[int]] = None
    confidence: float = 0.0
    engine_used: str = "tesseract"


class StaticCell(BaseModel):
    """A table cell in static format."""
    row: int = 0
    col: int = 0
    text: str = ""
    bbox: Optional[List[int]] = None
    confidence: float = 0.0
    content_type: str = "unknown"


class StaticTableRow(BaseModel):
    """A row of cells in static table format."""
    cells: List[StaticCell] = Field(default_factory=list)


class StaticSection(BaseModel):
    """A section of the prescription in static format."""
    section_name: str = ""
    fields: Dict[str, FieldWithBBox] = Field(default_factory=dict)


class StaticPrescription(BaseModel):
    """Full static format prescription with bounding boxes."""
    schema_name: str = "cambodia-prescription-static-v1.0"
    header: StaticSection = Field(default_factory=lambda: StaticSection(section_name="header"))
    patient_info: StaticSection = Field(default_factory=lambda: StaticSection(section_name="patient_info"))
    clinical_info: StaticSection = Field(default_factory=lambda: StaticSection(section_name="clinical_info"))
    medication_table: List[StaticTableRow] = Field(default_factory=list)
    footer: StaticSection = Field(default_factory=lambda: StaticSection(section_name="footer"))
