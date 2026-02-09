#!/bin/bash

# Das Tern NestJS Backend - Quick Start Script
# This script helps you start the backend development environment

set -e

echo "🚀 Das Tern NestJS Backend - Quick Start"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the backend_nestjs directory."
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
else
    echo "✅ Dependencies already installed"
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "✅ .env file created. Please update it with your configuration."
fi

# Check if Docker containers are running
echo ""
echo "🐳 Checking Docker containers..."
if ! docker compose ps | grep -q "dastern-postgres.*Up"; then
    echo "⚠️  PostgreSQL container not running. Starting Docker containers..."
    docker compose up -d
    echo "⏳ Waiting for PostgreSQL to be ready..."
    sleep 5
else
    echo "✅ Docker containers are running"
fi

# Generate Prisma Client
echo ""
echo "🔧 Generating Prisma Client..."
npm run prisma:generate

# Check if database is migrated
echo ""
echo "🗄️  Checking database migrations..."
if ! npm run prisma:migrate:status 2>&1 | grep -q "Database schema is up to date"; then
    echo "⚠️  Database needs migration. Running migrations..."
    npm run prisma:migrate
else
    echo "✅ Database is up to date"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📚 Available commands:"
echo "  npm run start:dev    - Start development server"
echo "  npm run start:debug  - Start with debugging"
echo "  npm run test         - Run tests"
echo "  npm run prisma:studio - Open Prisma Studio"
echo ""
echo "🌐 API will be available at: http://localhost:3000/api/v1"
echo ""
echo "📖 Documentation:"
echo "  - README.md - Full documentation"
echo "  - IMPLEMENTATION_PROGRESS.md - Current progress"
echo "  - QUICK_REFERENCE.md - Command reference"
echo ""
echo "🎯 Next steps:"
echo "  1. Review IMPLEMENTATION_PROGRESS.md for current status"
echo "  2. Run 'npm run start:dev' to start the server"
echo "  3. Test endpoints with curl or Postman"
echo ""
echo "Happy coding! 🚀"
