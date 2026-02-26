"""
HTTP Client for Ollama API
Supports both simple generate and chat-style completion.
Enhanced with comprehensive logging for debugging.
"""
import requests
import logging
import os
import time
from typing import Dict, Optional

try:
    from .logging_config import get_logger, truncate_for_log
except ImportError:
    from logging import getLogger as get_logger
    def truncate_for_log(data, max_length=200):
        return data[:max_length] + "..." if len(data) > max_length else data

logger = get_logger(__name__)

# Configuration
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
# Use llama3.1:8b as default (available model)
DEFAULT_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1:8b")
FAST_MODEL = os.getenv("OLLAMA_FAST_MODEL", "llama3.2:3b")


class OllamaClient:
    """HTTP client for Ollama API calls with enhanced logging"""
    
    def __init__(self, base_url: str = None, timeout: int = None):
        self.base_url = base_url or OLLAMA_BASE_URL
        # Default timeout is 60 seconds for fast 3B model
        self.timeout = timeout or int(os.getenv("OLLAMA_TIMEOUT", "60"))
        logger.info(f"OllamaClient initialized with base_url: {self.base_url}, timeout: {self.timeout}s (3B optimized)")
    
    def generate_response(self, payload: Dict, use_fast_model: bool = False) -> str:
        """
        Generate response using Ollama /api/generate endpoint (3B optimized).
        
        Args:
            payload: Request payload with model, prompt, options
            use_fast_model: If True, use faster 3B model instead of default
            
        Returns:
            Generated text response
        """
        start_time = time.time()
        
        try:
            # Use model from payload or default
            if "model" not in payload:
                payload["model"] = self.fast_model if use_fast_model else self.default_model
            
            # Ensure stream is disabled for sync call
            payload["stream"] = False
            
            # Add optimization options for 3B model
            if "options" not in payload:
                payload["options"] = {}
            if "top_k" not in payload["options"]:
                payload["options"]["top_k"] = 40
            if "top_p" not in payload["options"]:
                payload["options"]["top_p"] = 0.9
            
            logger.debug(f"Calling Ollama with 3B model: {payload['model']}, timeout: {self.timeout}s")
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=self.timeout
            )
            
            elapsed = time.time() - start_time
            
            if response.status_code == 200:
                result = response.json()
                response_text = result.get("response", "").strip()
                response_preview = truncate_for_log(response_text, 200)
                
                logger.info(f"[OLLAMA-COMPLETE] {elapsed:.1f}s - response_len={len(response_text)}")
                logger.debug(f"[OLLAMA-RESPONSE] {response_preview}")
                
                return response_text
            else:
                logger.error(f"[OLLAMA-ERROR] {elapsed:.1f}s - status={response.status_code}")
                raise Exception(f"Ollama API error: {response.status_code} - {response.text}")
                
        except requests.exceptions.Timeout:
            elapsed = time.time() - start_time
            logger.error(f"[OLLAMA-TIMEOUT] {elapsed:.1f}s - Request timed out after {self.timeout}s")
            raise TimeoutError(f"Ollama request timed out after {self.timeout} seconds. Try using a faster model or increase OLLAMA_TIMEOUT.")
        except Exception as e:
            elapsed = time.time() - start_time
            logger.error(f"[OLLAMA-FAILED] {elapsed:.1f}s - {str(e)}")
            raise
    
    def chat(
        self,
        messages: list,
        model: str = None,
        temperature: float = 0.2,
        max_tokens: int = 4096
    ) -> str:
        """
        Chat-style completion using Ollama /api/chat endpoint.
        Better for structured prompts with system/user separation.
        
        Args:
            messages: List of {"role": "system"|"user"|"assistant", "content": str}
            model: Model to use
            temperature: Sampling temperature (lower = more deterministic)
            max_tokens: Maximum tokens to generate
            
        Returns:
            Assistant's response text
        """
        try:
            payload = {
                "model": model or DEFAULT_MODEL,
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_ctx": max_tokens,
                }
            }
            
            logger.debug(f"Chat request with {len(messages)} messages, timeout: {self.timeout}s")
            
            response = requests.post(
                f"{self.base_url}/api/chat",
                json=payload,
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                result = response.json()
                message = result.get("message", {})
                return message.get("content", "").strip()
            else:
                raise Exception(f"Ollama chat error: {response.status_code} - {response.text}")
                
        except Exception as e:
            logger.error(f"Ollama chat failed: {str(e)}")
            raise
    
    def is_available(self) -> bool:
        """Check if Ollama is running and accessible"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def list_models(self) -> list:
        """Get list of available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            if response.status_code == 200:
                models = response.json().get("models", [])
                return [m.get("name", "") for m in models]
            return []
        except:
            return []