"""
Model Loader for LLM Service
Loads LLaMA model via Ollama once and caches it for reuse
"""

import os
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# Ollama configuration
# Default to 'ollama' service name for Docker network, fallback to localhost for local dev
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://ollama:11434")
DEFAULT_MODEL = os.getenv("LLM_MODEL", "llama3.1:8b")

# Cached model status
_model_loaded = False
_model_name: Optional[str] = None


def get_ollama_host() -> str:
    """Get Ollama API host URL."""
    return OLLAMA_HOST


def get_model_name() -> str:
    """Get the configured model name."""
    return _model_name or DEFAULT_MODEL


def check_model_available(model_name: str = None) -> bool:
    """
    Check if the specified model is available in Ollama.
    
    Args:
        model_name: Model to check (uses default if not specified)
        
    Returns:
        True if model is available
    """
    import requests
    
    model = model_name or DEFAULT_MODEL
    
    try:
        response = requests.get(
            f"{OLLAMA_HOST}/api/tags",
            timeout=5
        )
        
        if response.status_code == 200:
            models = response.json().get("models", [])
            available = any(m.get("name", "").startswith(model.split(":")[0]) for m in models)
            logger.info(f"Model {model} available: {available}")
            return available
        
        return False
    except Exception as e:
        logger.warning(f"Could not check model availability: {e}")
        return False


def load_model(model_name: str = None) -> bool:
    """
    Load/initialize the LLM model.
    For Ollama, this just verifies the model is available.
    
    Args:
        model_name: Model to load (uses default if not specified)
        
    Returns:
        True if model is ready
    """
    global _model_loaded, _model_name
    
    model = model_name or DEFAULT_MODEL
    
    try:
        if check_model_available(model):
            _model_loaded = True
            _model_name = model
            logger.info(f"Model {model} loaded successfully")
            return True
        else:
            logger.warning(f"Model {model} not found - attempting to pull")
            # Try to pull the model
            if pull_model(model):
                _model_loaded = True
                _model_name = model
                return True
            return False
            
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        return False


def pull_model(model_name: str) -> bool:
    """
    Pull a model from Ollama registry.
    
    Args:
        model_name: Model to pull
        
    Returns:
        True if pull succeeded
    """
    import requests
    
    try:
        logger.info(f"Pulling model {model_name}...")
        response = requests.post(
            f"{OLLAMA_HOST}/api/pull",
            json={"name": model_name},
            timeout=300  # 5 min timeout for large models
        )
        return response.status_code == 200
    except Exception as e:
        logger.error(f"Failed to pull model: {e}")
        return False


def is_model_ready() -> bool:
    """Check if model is loaded and ready."""
    return _model_loaded


def get_model_info() -> dict:
    """Get current model information."""
    return {
        "model_name": _model_name or DEFAULT_MODEL,
        "is_loaded": _model_loaded,
        "ollama_host": OLLAMA_HOST
    }

