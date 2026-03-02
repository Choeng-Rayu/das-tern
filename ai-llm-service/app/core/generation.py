"""
Generation Module
Unified generation logic for all LLM tasks
"""

import json
import logging
import requests
from typing import Optional, Dict, Any, List

from .model_loader import get_ollama_host, get_model_name, is_model_ready

logger = logging.getLogger(__name__)

# Generation defaults
DEFAULT_TEMPERATURE = 0.3  # Low temperature for medical accuracy
DEFAULT_MAX_TOKENS = 1024
DEFAULT_TIMEOUT = 60  # seconds


def generate(
    prompt: str,
    system_prompt: str = None,
    temperature: float = DEFAULT_TEMPERATURE,
    max_tokens: int = DEFAULT_MAX_TOKENS,
    timeout: int = DEFAULT_TIMEOUT,
    **kwargs  # Accept extra parameters for backward compatibility
) -> Optional[str]:
    """
    Generate text using the LLM.
    
    Args:
        prompt: User prompt
        system_prompt: System instructions
        temperature: Sampling temperature (0.0 to 1.0)
        max_tokens: Maximum tokens to generate
        timeout: Request timeout in seconds
        
    Returns:
        Generated text or None if failed
    """
    if not is_model_ready():
        logger.warning("Model not ready, attempting generation anyway")
    
    try:
        messages = []
        
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        messages.append({"role": "user", "content": prompt})
        
        response = requests.post(
            f"{get_ollama_host()}/api/chat",
            json={
                "model": get_model_name(),
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens
                }
            },
            timeout=timeout
        )
        
        if response.status_code == 200:
            result = response.json()
            content = result.get("message", {}).get("content", "")
            logger.debug(f"Generated {len(content)} characters")
            return content
        else:
            logger.error(f"Generation failed: {response.status_code} - {response.text}")
            return None
            
    except requests.Timeout:
        logger.error(f"Generation timed out after {timeout}s")
        return None
    except Exception as e:
        logger.error(f"Generation error: {e}")
        return None


def generate_json(
    prompt: str,
    system_prompt: str = None,
    temperature: float = 0.1,  # Even lower for JSON
    timeout: int = DEFAULT_TIMEOUT,
    **kwargs  # Accept extra parameters for backward compatibility
) -> Optional[Dict[str, Any]]:
    """
    Generate and parse JSON response from LLM.
    
    Args:
        prompt: User prompt
        system_prompt: System instructions (should mention JSON output)
        temperature: Sampling temperature
        timeout: Request timeout
        
    Returns:
        Parsed JSON dict or None if failed
    """
    # Add JSON instruction to system prompt
    json_system = (system_prompt or "") + "\nYou MUST respond with valid JSON only. No explanation."
    
    result = generate(
        prompt=prompt,
        system_prompt=json_system,
        temperature=temperature,
        timeout=timeout
    )
    
    if not result:
        return None
    
    try:
        # Try to extract JSON from response
        result = result.strip()
        
        # Handle markdown code blocks
        if result.startswith("```json"):
            result = result[7:]
        if result.startswith("```"):
            result = result[3:]
        if result.endswith("```"):
            result = result[:-3]
        
        return json.loads(result.strip())
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON: {e}")
        logger.debug(f"Raw response: {result}")
        return None


def generate_with_context(
    prompt: str,
    context: List[Dict[str, str]],
    system_prompt: str = None,
    temperature: float = DEFAULT_TEMPERATURE
) -> Optional[str]:
    """
    Generate with conversation context.
    
    Args:
        prompt: Current user prompt
        context: List of previous messages [{"role": "user/assistant", "content": "..."}]
        system_prompt: System instructions
        temperature: Sampling temperature
        
    Returns:
        Generated text or None
    """
    try:
        messages = []
        
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        # Add context
        messages.extend(context)
        
        # Add current prompt
        messages.append({"role": "user", "content": prompt})
        
        response = requests.post(
            f"{get_ollama_host()}/api/chat",
            json={
                "model": get_model_name(),
                "messages": messages,
                "stream": False,
                "options": {"temperature": temperature}
            },
            timeout=DEFAULT_TIMEOUT
        )
        
        if response.status_code == 200:
            return response.json().get("message", {}).get("content", "")
        return None
        
    except Exception as e:
        logger.error(f"Context generation error: {e}")
        return None
