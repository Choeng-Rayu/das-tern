"""
Generation Module
Unified generation logic for all LLM tasks.
Delegates to LLMClient which routes to the configured provider (ollama / openrouter).
"""

import json
import logging
from typing import Optional, Dict, Any, List

try:
    from .llm_client import get_llm_client
    from .model_loader import is_model_ready
except ImportError:
    from app.core.llm_client import get_llm_client
    from app.core.model_loader import is_model_ready

logger = logging.getLogger(__name__)

# Generation defaults
DEFAULT_TEMPERATURE = 0.3  # Low temperature for medical accuracy
DEFAULT_MAX_TOKENS  = 1024
DEFAULT_TIMEOUT     = 60   # seconds


def generate(
    prompt: str,
    system_prompt: str = None,
    temperature: float = DEFAULT_TEMPERATURE,
    max_tokens: int = DEFAULT_MAX_TOKENS,
    timeout: int = DEFAULT_TIMEOUT,
    **kwargs,   # Accept extra parameters for backward compatibility
) -> Optional[str]:
    """
    Generate text using the configured LLM provider.

    Args:
        prompt: User prompt.
        system_prompt: System instructions.
        temperature: Sampling temperature (0.0–1.0).
        max_tokens: Maximum tokens to generate.
        timeout: Request timeout in seconds.

    Returns:
        Generated text or None if failed.
    """
    if not is_model_ready():
        logger.warning("Model not marked as ready, attempting generation anyway")

    client = get_llm_client()
    result = client.generate(
        prompt=prompt,
        system_prompt=system_prompt,
        temperature=temperature,
        max_tokens=max_tokens,
        timeout=timeout,
    )

    if result:
        logger.debug(f"Generated {len(result)} characters")
    return result


def generate_json(
    prompt: str,
    system_prompt: str = None,
    temperature: float = 0.1,   # Even lower for JSON
    timeout: int = DEFAULT_TIMEOUT,
    **kwargs,   # Accept extra parameters for backward compatibility
) -> Optional[Dict[str, Any]]:
    """
    Generate and parse a JSON response from the LLM.

    Args:
        prompt: User prompt.
        system_prompt: System instructions (should mention JSON output).
        temperature: Sampling temperature.
        timeout: Request timeout.

    Returns:
        Parsed JSON dict or None if failed.
    """
    json_system = (system_prompt or "") + "\nYou MUST respond with valid JSON only. No explanation."

    raw = generate(
        prompt=prompt,
        system_prompt=json_system,
        temperature=temperature,
        timeout=timeout,
    )

    if not raw:
        return None

    try:
        result = raw.strip()
        # Strip markdown code fences
        if result.startswith("```json"):
            result = result[7:]
        if result.startswith("```"):
            result = result[3:]
        if result.endswith("```"):
            result = result[:-3]

        return json.loads(result.strip())
    except json.JSONDecodeError as exc:
        logger.error(f"Failed to parse JSON response: {exc}")
        logger.debug(f"Raw response was: {raw}")
        return None


def generate_with_context(
    prompt: str,
    context: List[Dict[str, str]],
    system_prompt: str = None,
    temperature: float = DEFAULT_TEMPERATURE,
) -> Optional[str]:
    """
    Generate with conversation context (multi-turn).

    Args:
        prompt: Current user prompt.
        context: Previous messages [{"role": "user"|"assistant", "content": "..."}].
        system_prompt: System instructions.
        temperature: Sampling temperature.

    Returns:
        Generated text or None.
    """
    messages = []

    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})

    messages.extend(context)
    messages.append({"role": "user", "content": prompt})

    client = get_llm_client()
    return client.chat(messages, temperature=temperature, timeout=DEFAULT_TIMEOUT)
