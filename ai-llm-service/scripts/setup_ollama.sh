#!/bin/bash
# Ollama AI Service Setup Script

echo "🚀 Setting up Ollama AI Service for OCR Enhancement"
echo "=================================================="

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed. Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "✅ Ollama is already installed"
fi

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "🔄 Starting Ollama service..."
    ollama serve &
    sleep 5
else
    echo "✅ Ollama service is running"
fi

# Pull the recommended model
echo "📥 Pulling Llama3.2 3B model (recommended for OCR correction)..."
ollama pull llama3.2:3b

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip install -r requirements_ollama.txt

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 To run the Ollama AI Service:"
echo "   python app/main_ollama.py"
echo ""
echo "🔗 Service will be available at: http://localhost:8004"
echo "🤖 Ollama API at: http://localhost:11434"
echo ""
echo "📝 Available models:"
ollama list