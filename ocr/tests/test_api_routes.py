from io import BytesIO
from types import SimpleNamespace

from fastapi import FastAPI
from fastapi.testclient import TestClient
from PIL import Image

from app.api.routes import router, set_engine, set_orchestrator


class StubEngine:
    """Stub OCR engine for testing (legacy fallback path)."""
    def extract(self, image_bytes: bytes):
        lines = [
            SimpleNamespace(text="Name: Test Patient Age: 40 Sex: M", confidence=0.95, bbox=[0, 0, 10, 10]),
            SimpleNamespace(text="Paracetamol 500mg tablet 1-0-1 5 days", confidence=0.90, bbox=[0, 10, 10, 10]),
            SimpleNamespace(text="Dr. Demo", confidence=0.92, bbox=[0, 20, 10, 10]),
        ]
        return "\n".join(line.text for line in lines), lines


def make_png_bytes() -> bytes:
    image = Image.new("RGB", (120, 60), "white")
    buffer = BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def build_client(use_orchestrator: bool = False) -> TestClient:
    """Build a test client. When use_orchestrator=False, uses legacy engine path."""
    app = FastAPI()
    app.include_router(router)
    set_engine(StubEngine())
    set_orchestrator(None)  # Force legacy path for unit tests (no real model)
    return TestClient(app)


def teardown():
    set_engine(None)
    set_orchestrator(None)


def test_health_and_config_routes() -> None:
    with build_client() as client:
        health = client.get("/api/v1/health")
        config = client.get("/api/v1/config")

    teardown()

    assert health.status_code == 200
    assert health.json()["status"] == "healthy"
    assert health.json()["models_loaded"] is True
    assert config.status_code == 200
    assert config.json()["ocr_engine"] == "kiri-ocr"


def test_extract_route_returns_backend_contract_subset() -> None:
    files = {"file": ("prescription.png", make_png_bytes(), "image/png")}

    with build_client() as client:
        response = client.post("/api/v1/extract", files=files)

    teardown()

    body = response.json()
    prescription = body["data"]["prescription"]

    assert response.status_code == 200
    assert body["success"] is True
    assert body["data"]["$schema"] == "cambodia-prescription-universal-v2.0"
    assert prescription["patient"]["personal_info"]["age"]["value"] == 40
    assert prescription["medications"]["summary"]["total_medications"] == 1
    assert body["extraction_summary"]["engines_used"] == ["kiri-ocr"]


def test_extract_route_rejects_unsupported_format() -> None:
    files = {"file": ("notes.txt", b"not-an-image", "text/plain")}

    with build_client() as client:
        response = client.post("/api/v1/extract", files=files)

    teardown()

    assert response.status_code == 422
    assert response.json()["detail"]["error"] == "unsupported_format"