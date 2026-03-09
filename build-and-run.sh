#!/bin/bash
set -e

cd /home/rayu/das-tern/backend_nestjs

echo "====== Building Backend ======"
npm run build

echo "====== Verifying build ======"
if [ -f dist/main.js ]; then
    echo "✓ Build successful: dist/main.js exists"
    echo ""
    echo "====== Starting Backend ======"
    npm run start:prod
else
    echo "✗ Build failed: dist/main.js not found"
    echo "Contents of dist folder:"
    ls -la dist/ || echo "dist folder does not exist"
    exit 1
fi
