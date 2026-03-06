FROM python:3.11-slim

# System dependencies for OpenCV and image processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Expose port
EXPOSE 8003

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=120s \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8003/api/v1/health')" || exit 1

# Run the service
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8003"]
