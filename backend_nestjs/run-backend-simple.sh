#!/bin/bash
#############################################
# DasTern Backend - Build & Run Fix
# This script compiles TypeScript and starts the backend
#############################################

set -e

cd /home/rayu/das-tern/backend_nestjs

echo "====== Cleaning Previous Build ======"
rm -rf dist
rm -f tsconfig*.tsbuildinfo

echo "====== Installing Dependencies ======"
npm install --silent

echo "====== Compiling TypeScript ======"
npx tsc --listFiles false

echo "====== Verifying Build ======"
if [ ! -f dist/main.js ]; then
    echo "ERROR: Build failed - dist/main.js not found"
    echo "Trying manual compilation of main.ts..."
    npx tsc src/main.ts --outDir dist --module commonjs --target ES2021 --declaration
fi

echo "====== Build Complete ======"
echo ""
echo "Starting Backend Server..."
echo ""

node dist/main
