"""
API routes for fine-tuned prescription extraction
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict
import logging

from app.core.finetuned_extractor import FinetunedMedicalExtractor

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/extract", tags=["Fine-tuned Extraction"])


class ExtractionRequest(BaseModel):
    """Request for prescription extraction"""
    ocr_text: str
    user_id: Optional[str] = None
    language: Optional[str] = "en"


class ExtractionResponse(BaseModel):
    """Response with extracted prescription data"""
    success: bool
    extracted_data: Dict
    model_used: str
    confidence: float
    medications_found: int


@router.post("/complete", response_model=ExtractionResponse)
async def extract_complete_prescription(request: ExtractionRequest):
    """
    Extract complete prescription using fine-tuned model
    
    Extracts:
    - Medications (with all details)
    - Diagnosis
    - Prescriber information
    - Prescription date
    """
    try:
        extractor = FinetunedMedicalExtractor()
        
        logger.info(f"Extracting prescription for user: {request.user_id}")
        
        # Extract using fine-tuned model (synchronous call)
        result = extractor.extract_full_prescription(request.ocr_text)
        
        # Add user context
        if request.user_id:
            result['user_id'] = request.user_id
        
        return ExtractionResponse(
            success=True,
            extracted_data=result,
            model_used="dastern-medical-extractor",
            confidence=result.get('confidence_score', 0.9),
            medications_found=len(result.get('medications', []))
        )
        
    except Exception as e:
        logger.error(f"Extraction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/medications")
async def extract_medications(request: ExtractionRequest):
    """
    Extract only medications from prescription
    """
    try:
        extractor = FinetunedMedicalExtractor()
        medications = await extractor.extract_medications_only(request.ocr_text)
        
        return {
            "success": True,
            "medications": medications,
            "count": len(medications)
        }
        
    except Exception as e:
        logger.error(f"Medication extraction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/diagnosis")
async def extract_diagnosis(request: ExtractionRequest):
    """
    Extract only diagnosis from prescription
    """
    try:
        extractor = FinetunedMedicalExtractor()
        diagnosis = await extractor.extract_diagnosis(request.ocr_text)
        
        return {
            "success": True,
            "diagnosis": diagnosis,
            "count": len(diagnosis)
        }
        
    except Exception as e:
        logger.error(f"Diagnosis extraction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/prescriber")
async def extract_prescriber(request: ExtractionRequest):
    """
    Extract prescriber information
    """
    try:
        extractor = FinetunedMedicalExtractor()
        prescriber = await extractor.extract_prescriber_info(request.ocr_text)
        
        return {
            "success": True,
            **prescriber
        }
        
    except Exception as e:
        logger.error(f"Prescriber extraction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
