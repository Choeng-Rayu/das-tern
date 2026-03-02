#!/bin/bash
# Quick Ollama AI Test
echo "Testing Ollama AI service..."

# Test simple correction
curl -X POST http://localhost:8004/correct-ocr \
  -H "Content-Type: application/json" \
  -d '{"text": "ParscotamolB00mg Tako 2ibotsdeiy Morning and Evening Duration 5 days", "language": "en"}' \
  --max-time 60 | jq .