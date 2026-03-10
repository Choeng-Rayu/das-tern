#!/bin/bash
####################################
# DasTern Backend - Simple ts-node Start
# For development - no build needed
####################################

cd /home/rayu/das-tern/backend_nestjs

echo "Starting DasTern Backend (Development Mode)..."
echo "Using ts-node for direct TypeScript execution"
echo ""

# Run TypeScript directly without compilation
exec npx ts-node -r tsconfig-paths/register src/main.ts
