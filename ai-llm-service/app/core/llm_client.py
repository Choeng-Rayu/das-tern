"""
Unified LLM Client
Supports multiple providers via LLM_PROVIDER env var:
  - "ollama"      : local Ollama server (default)
  - "openrouter"  : OpenRouter API (OpenAI-compatible)

To switch providers, set LLM_PROVIDER in your .env file.
"""

import os
import json
import logging
import time
from typing import Dict, List, Optional, Any

import requests

try:
    from .logging_config import get_logger, truncate_for_log
except ImportError:
    from logging import getLogger as get_logger
    def truncate_for_log(data, max_length=200):
        return data[:max_length] + "..." if len(str(data)) > max_length else data

logger = get_logger(__name__)

# ── Provider selection ────────────────────────────────────────────────────────
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "ollama").lower()

# ── Ollama config ─────────────────────────────────────────────────────────────
OLLAMA_BASE_URL   = os.getenv("OLLAMA_BASE_URL",   "http://localhost:11434")
OLLAMA_MODEL      = os.getenv("OLLAMA_MODEL",      "llama3.2:3b")
OLLAMA_FAST_MODEL = os.getenv("OLLAMA_FAST_MODEL", "llama3.2:3b")
OLLAMA_TIMEOUT    = int(os.getenv("OLLAMA_TIMEOUT", "60"))

# ── OpenRouter config ─────────────────────────────────────────────────────────
OPENROUTER_API_KEY   = os.getenv("OPENROUTER_API_KEY",   "")
OPENROUTER_MODEL     = os.getenv("OPENROUTER_MODEL",     "google/gemma-3-4b-it:free")
OPENROUTER_BASE_URL  = "https://openrouter.ai/api/v1"
OPENROUTER_TIMEOUT   = int(os.getenv("OPENROUTER_TIMEOUT", "60"))


class LLMClient:
    """
    Unified LLM client.  Route every call through this class instead of
    calling Ollama or any API directly.  The active provider is selected once
    at construction time from the LLM_PROVIDER env var.
    """

    def __init__(self) -> None:
        self.provider = LLM_PROVIDER

        if self.provider == "ollama":
            self.base_url   = OLLAMA_BASE_URL
            self.model      = OLLAMA_MODEL
            self.fast_model = OLLAMA_FAST_MODEL
            self.timeout    = OLLAMA_TIMEOUT
            self.api_key    = None
        elif self.provider == "openrouter":
            self.base_url   = OPENROUTER_BASE_URL
            self.model      = OPENROUTER_MODEL
            self.fast_model = OPENROUTER_MODEL   # same model for both paths
            self.timeout    = OPENROUTER_TIMEOUT
            self.api_key    = OPENROUTER_API_KEY
            if not self.api_key:
                logger.warning("LLM_PROVIDER=openrouter but OPENROUTER_API_KEY is not set")
        else:
            raise ValueError(
                f"Unknown LLM_PROVIDER='{self.provider}'. "
                "Valid values: 'ollama', 'openrouter'."
            )

        logger.info(
            f"LLMClient ready — provider={self.provider}, model={self.model}"
        )

    # ── Public interface ──────────────────────────────────────────────────────

    def generate(
        self,
        prompt: str,
        system_prompt: str = None,
        temperature: float = 0.3,
        max_tokens: int = 1024,
        timeout: int = None,
    ) -> Optional[str]:
        """
        Generate a text completion.

        Args:
            prompt: User message / instruction.
            system_prompt: Optional system-level instruction.
            temperature: Sampling temperature (0 = deterministic).
            max_tokens: Max tokens to generate.
            timeout: Per-request timeout override (seconds).

        Returns:
            Generated text string, or None on failure.
        """
        messages: List[Dict[str, str]] = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})
        return self.chat(messages, temperature=temperature, max_tokens=max_tokens, timeout=timeout)

    def chat(
        self,
        messages: List[Dict[str, str]],
        model: str = None,
        temperature: float = 0.3,
        max_tokens: int = 1024,
        timeout: int = None,
    ) -> Optional[str]:
        """
        Send a list of chat messages and return the assistant reply.

        Args:
            messages: List of {"role": "system"|"user"|"assistant", "content": str}.
            model: Override the default model for this call.
            temperature: Sampling temperature.
            max_tokens: Max tokens to generate.
            timeout: Per-request timeout override (seconds).

        Returns:
            Assistant response text, or None on failure.
        """
        effective_model   = model or self.model
        effective_timeout = timeout or self.timeout

        if self.provider == "ollama":
            return self._ollama_chat(
                messages, effective_model, temperature, max_tokens, effective_timeout
            )
        else:
            return self._openrouter_chat(
                messages, effective_model, temperature, max_tokens, effective_timeout
            )

    def generate_response(self, payload: Dict[str, Any], use_fast_model: bool = False) -> str:
        """
        Compatibility shim for code that calls OllamaClient.generate_response(payload).

        Accepts an Ollama-style payload dict (with 'prompt', 'options', 'model', etc.)
        and raises on failure (matching the original behaviour).
        """
        prompt      = payload.get("prompt", "")
        system      = payload.get("system", None)
        options     = payload.get("options", {})
        temperature = options.get("temperature", 0.3)
        max_tokens  = options.get(
            "num_predict", options.get("num_ctx", options.get("max_tokens", 1024))
        )
        # Always use the provider's configured model.
        # Ollama model names from legacy payload dicts are meaningless for API providers.
        model = self.fast_model if use_fast_model else self.model

        result = self.generate(
            prompt=prompt,
            system_prompt=system,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        if result is None:
            raise RuntimeError(
                f"LLM generation failed (provider={self.provider}, model={model})"
            )
        return result

    def is_available(self) -> bool:
        """Return True if the provider backend is reachable / configured."""
        if self.provider == "ollama":
            try:
                resp = requests.get(f"{self.base_url}/api/tags", timeout=5)
                return resp.status_code == 200
            except Exception:
                return False
        elif self.provider == "openrouter":
            return bool(self.api_key)
        return False

    def get_info(self) -> Dict[str, Any]:
        """Return a dict describing the active provider and model."""
        return {
            "provider":   self.provider,
            "model":      self.model,
            "is_loaded":  self.is_available(),
            # Keep 'ollama_host' for backward-compat with existing health checks
            "ollama_host": self.base_url if self.provider == "ollama" else None,
        }

    # ── Private helpers ───────────────────────────────────────────────────────

    def _ollama_chat(
        self,
        messages: List[Dict],
        model: str,
        temperature: float,
        max_tokens: int,
        timeout: int,
    ) -> Optional[str]:
        start = time.time()
        try:
            resp = requests.post(
                f"{self.base_url}/api/chat",
                json={
                    "model":   model,
                    "messages": messages,
                    "stream":  False,
                    "options": {
                        "temperature": temperature,
                        "num_predict": max_tokens,
                        "top_k": 40,
                        "top_p": 0.9,
                    },
                },
                timeout=timeout,
            )
            elapsed = time.time() - start

            if resp.status_code == 200:
                content = resp.json().get("message", {}).get("content", "").strip()
                logger.info(f"[OLLAMA] {elapsed:.1f}s — {len(content)} chars")
                logger.debug(f"[OLLAMA] {truncate_for_log(content)}")
                return content
            else:
                logger.error(f"[OLLAMA] HTTP {resp.status_code}: {resp.text[:200]}")
                return None

        except requests.Timeout:
            logger.error(f"[OLLAMA] timeout after {timeout}s")
            return None
        except Exception as exc:
            logger.error(f"[OLLAMA] failed: {exc}")
            return None

    def _openrouter_chat(
        self,
        messages: List[Dict],
        model: str,
        temperature: float,
        max_tokens: int,
        timeout: int,
    ) -> Optional[str]:
        start = time.time()
        try:
            resp = requests.post(
                f"{self.base_url}/chat/completions",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type":  "application/json",
                    "HTTP-Referer":  "https://das-tern.app",
                    "X-Title":       "DasTern AI Service",
                },
                json={
                    "model":       model,
                    "messages":    messages,
                    "temperature": temperature,
                    "max_tokens":  max_tokens,
                },
                timeout=timeout,
            )
            elapsed = time.time() - start

            if resp.status_code == 200:
                content = resp.json()["choices"][0]["message"]["content"].strip()
                logger.info(f"[OPENROUTER] {elapsed:.1f}s — {len(content)} chars")
                logger.debug(f"[OPENROUTER] {truncate_for_log(content)}")
                return content
            else:
                logger.error(f"[OPENROUTER] HTTP {resp.status_code}: {resp.text[:200]}")
                return None

        except requests.Timeout:
            logger.error(f"[OPENROUTER] timeout after {timeout}s")
            return None
        except Exception as exc:
            logger.error(f"[OPENROUTER] failed: {exc}")
            return None


# ── Module-level singleton ────────────────────────────────────────────────────

_client: Optional[LLMClient] = None


def get_llm_client() -> LLMClient:
    """Return the module-level LLMClient singleton (lazy-initialised)."""
    global _client
    if _client is None:
        _client = LLMClient()
    return _client
