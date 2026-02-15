#!/bin/bash
set -ex
cd /home/rayu/das-tern/bakong_payment
echo "Starting Prisma generation..."
./node_modules/.bin/prisma generate --schema=./prisma/schema.prisma
echo "Checking if generated..."
ls -la node_modules/.prisma/client/ 2>&1 || echo "Not generated"
echo "Done!"
