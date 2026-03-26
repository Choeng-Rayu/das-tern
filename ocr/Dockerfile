FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for OpenCV/OCR and Tesseract
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libglib2.0-0 \
    libgomp1 \
    libgl1 \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-script-khmr \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for layer caching
COPY requirements.txt .

# Install Python dependencies
# Note: Kiri-OCR is optional and only needed if OCR_MODEL=kiri-ocr
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Optionally install Kiri-OCR (can be skipped if only using Tesseract)
# Uncomment the following lines if you want Kiri-OCR support:
# RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch \
#     && pip install --no-cache-dir --no-deps kiri-ocr==0.2.15

# Copy application code
COPY . .

# Environment defaults
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV HOST=0.0.0.0
ENV PORT=8000
ENV OCR_MODEL=tesseract

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
