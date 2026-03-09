"""
OllamaClient — backward-compatible shim over LLMClient.

All real work is now performed by LLMClient (app/core/llm_client.py).
OllamaClient keeps the original interface so every existing caller
(ReminderEngine, PrescriptionProcessor, FinetunedMedicalExtractor, …)
continues to work without changes, regardless of which provider is active.
"""

import logging
import os
from typing import Dict, List, Optional

try:
    from .llm_client import LLMClient, get_llm_client
    from .logging_config import get_logger
except ImportError:
    from app.core.llm_client import LLMClient, get_llm_client
    from logging import getLogger as get_logger

logger = get_logger(__name__)


class OllamaClient:
    """
    Thin compatibility wrapper around LLMClient.

    Constructor arguments are accepted but ignored; all configuration
    is read from environment variables by LLMClient.
    """

    def __init__(self, base_url: str = None, timeout: int = None) -> None:
        # Delegate to the shared singleton
        self._client: LLMClient = get_llm_client()
        logger.info(
            f"OllamaClient initialised — delegating to provider={self._client.provider}"
        )

    # ── Main generation methods ───────────────────────────────────────────────

    def generate_response(self, payload: Dict, use_fast_model: bool = False) -> str:
        """
        Generate using an Ollama-style payload dict.
        Raises on failure to preserve the original contract.
        """
        return self._client.generate_response(payload, use_fast_model=use_fast_model)

    def chat(
        self,
        messages: List[Dict],
        model: str = None,
        temperature: float = 0.2,
        max_tokens: int = 4096,
    ) -> str:
        """
        Chat-style completion.
        Returns the assistant's reply text; raises on failure.
        """
        result = self._client.chat(
            messages=messages,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        if result is None:
            raise RuntimeError(
                f"LLM chat failed (provider={self._client.provider})"
            )
        return result

    # ── Utility methods ───────────────────────────────────────────────────────

    def is_available(self) -> bool:
        """Check if the active provider is reachable / configured."""
        return self._client.is_available()

    def list_models(self) -> list:
        """
        Return a list of available model names.
        Only meaningful for the Ollama provider; returns the configured
        model name for API providers.
        """
        if self._client.provider == "ollama":
            import requests
            try:
                resp = requests.get(
                    f"{self._client.base_url}/api/tags", timeout=5
                )
                if resp.status_code == 200:
                    models = resp.json().get("models", [])
                    return [m.get("name", "") for m in models]
            except Exception:
                pass
            return []
        else:
            # For API providers just report the configured model
            return [self._client.model]

    # ── Expose underlying model names for callers that need them ──────────────

    @property
    def default_model(self) -> str:
        return self._client.model

    @property
    def fast_model(self) -> str:
        return self._client.fast_model
