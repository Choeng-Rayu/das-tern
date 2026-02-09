#!/bin/bash

echo "🔍 Das Tern NestJS Backend - System Check"
echo "=========================================="
echo ""

# Check port 3000
echo "📡 Checking port 3000..."
if lsof -ti:3000 > /dev/null 2>&1; then
    echo "❌ Port 3000 is in use. Killing process..."
    lsof -ti:3000 | xargs kill -9
    echo "✅ Port 3000 is now free"
else
    echo "✅ Port 3000 is free"
fi
echo ""

# Check Node.js version
echo "📦 Checking Node.js version..."
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node -v)
    echo "✅ Node.js: $NODE_VERSION"
else
    echo "❌ Node.js not found"
fi
echo ""

# Check npm version
echo "📦 Checking npm version..."
if command -v npm > /dev/null 2>&1; then
    NPM_VERSION=$(npm -v)
    echo "✅ npm: $NPM_VERSION"
else
    echo "❌ npm not found"
fi
echo ""

# Check Docker
echo "🐳 Checking Docker..."
if command -v docker > /dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    echo "✅ Docker: $DOCKER_VERSION"
else
    echo "❌ Docker not found"
fi
echo ""

# Check Docker Compose
echo "🐳 Checking Docker Compose..."
if command -v docker > /dev/null 2>&1 && docker compose version > /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version)
    echo "✅ Docker Compose: $COMPOSE_VERSION"
else
    echo "❌ Docker Compose not found"
fi
echo ""

# Check if in correct directory
echo "📁 Checking directory..."
if [ -f "package.json" ] && [ -f "docker-compose.yml" ]; then
    echo "✅ In correct directory: $(pwd)"
else
    echo "❌ Not in backend_nestjs directory"
    echo "   Run: cd /home/rayu/das-tern/backend_nestjs"
    exit 1
fi
echo ""

# Check if node_modules exists
echo "📦 Checking dependencies..."
if [ -d "node_modules" ]; then
    echo "✅ Dependencies installed"
else
    echo "⚠️  Dependencies not installed"
    echo "   Run: npm install"
fi
echo ""

# Check Docker containers
echo "🐳 Checking Docker containers..."
if docker compose ps | grep -q "Up"; then
    echo "✅ Docker containers running:"
    docker compose ps
else
    echo "⚠️  Docker containers not running"
    echo "   Run: docker compose up -d"
fi
echo ""

# Check .env file
echo "⚙️  Checking .env file..."
if [ -f ".env" ]; then
    echo "✅ .env file exists"
else
    echo "❌ .env file not found"
    echo "   Run: cp .env.example .env"
fi
echo ""

echo "=========================================="
echo "✅ System check complete!"
echo ""
echo "Next steps:"
echo "1. npm install (if not done)"
echo "2. docker compose up -d"
echo "3. npm run prisma:generate"
echo "4. npm run prisma:migrate"
echo "5. npm run start:dev"
