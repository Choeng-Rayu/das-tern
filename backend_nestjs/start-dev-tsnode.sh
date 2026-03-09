#!/bin/bash

# Alternative startup script using ts-node for development
cd /home/rayu/das-tern/backend_nestjs

echo "Starting DasTern Backend with ts-node..."

# Use ts-node to run the TypeScript directly  
npx ts-node --project tsconfig.json src/main.ts
