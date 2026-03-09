"""
Model Loader — provider-aware startup initialisation.

For the 'ollama' provider   : checks / pulls the model on startup.
For the 'openrouter' provider: verifies the API key is set; no download needed.
"""

import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# Re-read the provider here (before LLMClient fully initialises) so that
# load_model() can decide what to do at startup.
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "ollama").lower()

# Ollama-specific settings (only used when LLM_PROVIDER=ollama)
OLLAMA_HOST   = os.getenv("OLLAMA_HOST", os.getenv("OLLAMA_BASE_URL", "http://ollama:11434"))
DEFAULT_MODEL = os.getenv("LLM_MODEL",  os.getenv("OLLAMA_MODEL", "llama3.2:3b"))

# Cached state
_model_loaded = False
_model_name: Optional[str] = None


# ── Accessors (kept for backward-compat with old import sites) ────────────────

def get_ollama_host() -> str:
    """Return the Ollama host URL (only relevant for Ollama provider)."""
    return OLLAMA_HOST


def get_model_name() -> str:
    """Return the active model name."""
    if _model_name:
        return _model_name
    # For openrouter, pull from its own env var
    if LLM_PROVIDER == "openrouter":
        return os.getenv("OPENROUTER_MODEL", "google/gemma-3-4b-it:free")
    return DEFAULT_MODEL


def is_model_ready() -> bool:
    """Return True once load_model() has completed successfully."""
    return _model_loaded


def get_model_info() -> dict:
    """Return a dict describing the current model / provider state."""
    from app.core.llm_client import get_llm_client  # avoid circular at module-level
    try:
        info = get_llm_client().get_info()
    except Exception:
        info = {
            "provider":   LLM_PROVIDER,
            "model":      get_model_name(),
            "is_loaded":  _model_loaded,
            "ollama_host": OLLAMA_HOST if LLM_PROVIDER == "ollama" else None,
        }
    # Keep 'model_name' key for callers that expect it
    info["model_name"] = info.get("model", get_model_name())
    return info


# ── Startup ───────────────────────────────────────────────────────────────────

def load_model(model_name: str = None) -> bool:
    """
    Initialise the LLM backend at service startup.

    - ollama     : checks model availability, pulls if missing.
    - openrouter : verifies OPENROUTER_API_KEY is set.

    Returns True if the backend is ready.
    """
    global _model_loaded, _model_name

    if LLM_PROVIDER == "openrouter":
        api_key = os.getenv("OPENROUTER_API_KEY", "")
        if api_key:
            _model_loaded = True
            _model_name   = os.getenv("OPENROUTER_MODEL", "google/gemma-3-4b-it:free")
            logger.info(f"OpenRouter provider ready — model={_model_name}")
            return True
        else:
            logger.error("LLM_PROVIDER=openrouter but OPENROUTER_API_KEY is not set")
            return False

    # --- Ollama path ---
    model = model_name or DEFAULT_MODEL
    try:
        if check_model_available(model):
            _model_loaded = True
            _model_name   = model
            logger.info(f"Ollama model '{model}' is available")
            return True
        else:
            logger.warning(f"Ollama model '{model}' not found — attempting pull")
            if pull_model(model):
                _model_loaded = True
                _model_name   = model
                return True
            logger.error(f"Failed to pull Ollama model '{model}'")
            return False
    except Exception as exc:
        logger.error(f"Error during model load: {exc}")
        return False


# ── Ollama-specific helpers ───────────────────────────────────────────────────

def check_model_available(model_name: str = None) -> bool:
    """Check whether a model exists in the local Ollama instance."""
    import requests

    model = model_name or DEFAULT_MODEL
    try:
        resp = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=5)
        if resp.status_code == 200:
            models    = resp.json().get("models", [])
            available = any(
                m.get("name", "").startswith(model.split(":")[0]) for m in models
            )
            logger.info(f"Ollama model '{model}' available={available}")
            return available
        return False
    except Exception as exc:
        logger.warning(f"Could not reach Ollama to check model: {exc}")
        return False


def pull_model(model_name: str) -> bool:
    """Pull a model from the Ollama registry (5-minute timeout)."""
    import requests

    try:
        logger.info(f"Pulling Ollama model '{model_name}' …")
        resp = requests.post(
            f"{OLLAMA_HOST}/api/pull",
            json={"name": model_name},
            timeout=300,
        )
        return resp.status_code == 200
    except Exception as exc:
        logger.error(f"Failed to pull model '{model_name}': {exc}")
        return False
