"""
Structured Logging Configuration for AI-LLM Service
Provides request tracking, structured output, and clear log formatting.
"""

import logging
import sys
import os
import uuid
from datetime import datetime
from typing import Optional
from contextvars import ContextVar
from functools import wraps
import time

# Context variable for request ID tracking
request_id_var: ContextVar[Optional[str]] = ContextVar("request_id", default=None)

# Log format with colors for terminal
LOG_COLORS = {
    'DEBUG': '\033[36m',     # Cyan
    'INFO': '\033[32m',      # Green
    'WARNING': '\033[33m',   # Yellow
    'ERROR': '\033[31m',     # Red
    'CRITICAL': '\033[35m',  # Magenta
    'RESET': '\033[0m'       # Reset
}


class RequestIDFilter(logging.Filter):
    """Add request ID to log records."""
    
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id_var.get() or "no-request"
        return True


class ColoredFormatter(logging.Formatter):
    """Formatter with color support for terminal output."""
    
    def format(self, record: logging.LogRecord) -> str:
        # Add color to level name for terminal
        levelname = record.levelname
        if sys.stdout.isatty():
            color = LOG_COLORS.get(levelname, LOG_COLORS['RESET'])
            record.levelname = f"{color}{levelname}{LOG_COLORS['RESET']}"
        
        result = super().format(record)
        record.levelname = levelname  # Reset for file output
        return result


def setup_logging(
    log_level: str = None,
    log_file: str = None,
    service_name: str = "ai-llm-service"
) -> None:
    """
    Configure application logging with structured format.
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
        log_file: Optional file path for logging
        service_name: Service identifier for logs
    """
    level = log_level or os.getenv("LOG_LEVEL", "INFO")
    
    # Create structured log format
    log_format = (
        "%(asctime)s | %(levelname)-8s | [%(request_id)s] | "
        "%(name)s:%(lineno)d | %(message)s"
    )
    date_format = "%Y-%m-%d %H:%M:%S"
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, level.upper()))
    
    # Clear existing handlers
    root_logger.handlers.clear()
    
    # Console handler with colors
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(ColoredFormatter(log_format, datefmt=date_format))
    console_handler.addFilter(RequestIDFilter())
    root_logger.addHandler(console_handler)
    
    # File handler (no colors)
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(logging.Formatter(log_format, datefmt=date_format))
        file_handler.addFilter(RequestIDFilter())
        root_logger.addHandler(file_handler)
    
    # Reduce noise from third-party libraries
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    
    # Log startup
    logger = logging.getLogger(service_name)
    logger.info(f"Logging configured: level={level}, service={service_name}")


def get_logger(name: str) -> logging.Logger:
    """Get a logger with the given name."""
    return logging.getLogger(name)


def generate_request_id() -> str:
    """Generate a unique request ID."""
    return str(uuid.uuid4())[:8]


def set_request_id(request_id: Optional[str] = None) -> str:
    """Set the request ID for the current context."""
    if request_id is None:
        request_id = generate_request_id()
    request_id_var.set(request_id)
    return request_id


def get_request_id() -> Optional[str]:
    """Get the current request ID."""
    return request_id_var.get()


def log_timing(logger: logging.Logger):
    """Decorator to log function execution time."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start = time.time()
            func_name = func.__name__
            logger.info(f"[START] {func_name}")
            try:
                result = func(*args, **kwargs)
                elapsed = (time.time() - start) * 1000
                logger.info(f"[COMPLETE] {func_name} - {elapsed:.0f}ms")
                return result
            except Exception as e:
                elapsed = (time.time() - start) * 1000
                logger.error(f"[FAILED] {func_name} - {elapsed:.0f}ms - {str(e)}")
                raise
        return wrapper
    return decorator


def log_async_timing(logger: logging.Logger):
    """Decorator to log async function execution time."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            start = time.time()
            func_name = func.__name__
            logger.info(f"[START] {func_name}")
            try:
                result = await func(*args, **kwargs)
                elapsed = (time.time() - start) * 1000
                logger.info(f"[COMPLETE] {func_name} - {elapsed:.0f}ms")
                return result
            except Exception as e:
                elapsed = (time.time() - start) * 1000
                logger.error(f"[FAILED] {func_name} - {elapsed:.0f}ms - {str(e)}")
                raise
        return wrapper
    return decorator


def truncate_for_log(data: str, max_length: int = 200) -> str:
    """Truncate data for logging to avoid huge log entries."""
    if len(data) <= max_length:
        return data
    return data[:max_length] + f"... [truncated, total: {len(data)} chars]"
