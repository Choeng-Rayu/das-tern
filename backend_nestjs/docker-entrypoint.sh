#!/bin/sh
set -e

echo "🚀 Starting Das Tern Backend..."
echo "📦 Environment: $NODE_ENV"

# Run Prisma migrations (postgres is already healthy via docker-compose depends_on)
echo "🔄 Running database migrations..."
MAX_RETRIES=10
RETRY=0
until npx prisma migrate deploy; do
  RETRY=$((RETRY+1))
  if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "❌ Migration failed after $MAX_RETRIES attempts. Exiting."
    exit 1
  fi
  echo "⏳ Retrying migration ($RETRY/$MAX_RETRIES)..."
  sleep 3
done
echo "✅ Migrations complete"

# Start the application
echo "▶️  Starting NestJS application on port ${PORT:-3001}..."
exec node dist/main
