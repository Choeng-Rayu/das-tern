#!/usr/bin/env bash
# =============================================================================
# start-bakong.sh
# Run this script EVERY TIME you boot your machine and want to serve
# payment.dastern.site from your local machine.
#
# What it does:
#   1. Detects your current public IP
#   2. Updates the Cloudflare DNS A record for payment.dastern.site
#   3. Starts Docker containers (Postgres + Redis)
#   4. Runs Prisma migrations
#   5. Builds & starts the NestJS bakong_payment service (port 3002)
#   6. Reloads Nginx so the SSL proxy is live
#
# Prerequisites (one-time setup — see RUNBOOK.md):
#   - Cloudflare API token in CF_API_TOKEN env var (or .env.bakong-startup)
#   - Cloudflare Zone ID in CF_ZONE_ID env var (or .env.bakong-startup)
#   - Nginx installed with the payment.dastern.site config in place
#   - Certbot SSL cert already issued for payment.dastern.site
#   - Docker installed and running
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_STARTUP="$SCRIPT_DIR/.env.bakong-startup"
ENV_APP="$SCRIPT_DIR/.env"

# ── Load startup secrets (CF credentials) ────────────────────────────────────
if [[ -f "$ENV_STARTUP" ]]; then
  source "$ENV_STARTUP"
fi

CF_API_TOKEN="${CF_API_TOKEN:-}"
CF_ZONE_ID="${CF_ZONE_ID:-}"
CF_RECORD_NAME="payment.dastern.site"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

echo ""
echo "=================================================================="
echo "  🚀  Bakong Payment Service — Startup"
echo "=================================================================="
echo ""

# ── Step 1: Get current public IP ─────────────────────────────────────────────
log "Detecting public IP..."
PUBLIC_IP=$(curl -s --max-time 10 https://api.ipify.org || curl -s --max-time 10 https://checkip.amazonaws.com)
if [[ -z "$PUBLIC_IP" ]]; then
  err "Could not detect public IP. Check internet connection."
  exit 1
fi
log "Public IP: $PUBLIC_IP"

# ── Step 2: Update Cloudflare DNS ─────────────────────────────────────────────
if [[ -z "$CF_API_TOKEN" || -z "$CF_ZONE_ID" ]]; then
  warn "CF_API_TOKEN or CF_ZONE_ID not set — skipping DNS update."
  warn "Set them in $ENV_STARTUP to enable automatic DNS updates."
else
  log "Updating Cloudflare DNS: $CF_RECORD_NAME → $PUBLIC_IP ..."

  # Get the existing DNS record ID
  RECORD_ID=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=A&name=${CF_RECORD_NAME}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    | python3 -c "import sys,json; data=json.load(sys.stdin); print(data['result'][0]['id'] if data['result'] else '')" 2>/dev/null || echo "")

  if [[ -z "$RECORD_ID" ]]; then
    # Create new A record
    RESULT=$(curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${PUBLIC_IP}\",\"ttl\":60,\"proxied\":false}")
    log "Created new DNS A record."
  else
    # Update existing record
    RESULT=$(curl -s -X PUT \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${PUBLIC_IP}\",\"ttl\":60,\"proxied\":false}")
    log "Updated DNS A record → $PUBLIC_IP"
  fi

  # Check success
  SUCCESS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success','false'))" 2>/dev/null || echo "false")
  if [[ "$SUCCESS" != "True" && "$SUCCESS" != "true" ]]; then
    warn "Cloudflare API response: $RESULT"
    warn "DNS update may have failed. Check your token/zone ID."
  fi
fi

# ── Step 3: Start Docker services (Postgres + Redis) ─────────────────────────
log "Starting Docker containers..."
cd "$SCRIPT_DIR"
docker compose up -d
log "Waiting for Postgres to be healthy..."
ATTEMPTS=0
until docker exec bakong_payment_postgres pg_isready -U postgres >/dev/null 2>&1; do
  sleep 2
  ATTEMPTS=$((ATTEMPTS+1))
  if [[ $ATTEMPTS -gt 20 ]]; then
    err "Postgres did not become ready in time."
    exit 1
  fi
done
log "Postgres is ready."

# ── Step 4: Run Prisma DB migrations ──────────────────────────────────────────
log "Running database migrations..."
cd "$SCRIPT_DIR"
npx prisma migrate deploy --schema=./prisma/schema.prisma
log "Migrations complete."

# ── Step 5: Build NestJS app (skip if dist/ already up-to-date) ───────────────
if [[ ! -d "$SCRIPT_DIR/dist" || "$1" == "--rebuild" ]]; then
  log "Building NestJS app..."
  npm run build
  log "Build complete."
else
  log "Skipping build (dist/ exists). Use --rebuild to force."
fi

# ── Step 6: Reload Nginx ───────────────────────────────────────────────────────
log "Testing Nginx configuration..."
sudo nginx -t
log "Reloading Nginx..."
sudo systemctl reload nginx
log "Nginx reloaded."

# ── Step 7: Start NestJS in background ────────────────────────────────────────
log "Starting Bakong Payment Service (port 3002)..."
cd "$SCRIPT_DIR"

# Kill any existing instance on port 3002
PID=$(lsof -ti:3002 2>/dev/null || true)
if [[ -n "$PID" ]]; then
  warn "Killing existing process on port 3002 (PID: $PID)"
  kill -9 "$PID" 2>/dev/null || true
  sleep 1
fi

# Start with nohup so it survives terminal close
NODE_ENV=production nohup node dist/main.js >> "$SCRIPT_DIR/logs/startup.log" 2>&1 &
APP_PID=$!
echo $APP_PID > "$SCRIPT_DIR/bakong-payment.pid"
log "Service started (PID: $APP_PID) — logs: $SCRIPT_DIR/logs/startup.log"

# Wait a moment and verify it's running
sleep 3
if ! kill -0 "$APP_PID" 2>/dev/null; then
  err "Service failed to start. Check logs/startup.log"
  exit 1
fi

echo ""
echo "=================================================================="
echo "  ✅  Bakong Payment Service is LIVE"
echo ""
echo "  Local:   http://localhost:3002/api/health"
echo "  Public:  https://payment.dastern.site/api/health"
echo "  Your IP: $PUBLIC_IP"
echo ""
echo "  To stop:  ./stop-bakong.sh"
echo "  Logs:     tail -f $SCRIPT_DIR/logs/startup.log"
echo "=================================================================="
echo ""
