#!/usr/bin/env bash
# =============================================================================
# stop-bakong.sh
# Gracefully stops the Bakong Payment Service and Docker containers.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

echo ""
echo "=================================================================="
echo "  🛑  Bakong Payment Service — Stopping"
echo "=================================================================="
echo ""

# Stop NestJS process
PID_FILE="$SCRIPT_DIR/bakong-payment.pid"
if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    log "Stopping NestJS process (PID: $PID)..."
    kill "$PID"
    sleep 2
    kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null || true
    log "Process stopped."
  else
    warn "Process $PID not running."
  fi
  rm -f "$PID_FILE"
else
  # Fallback: kill by port
  PID=$(lsof -ti:3002 2>/dev/null || true)
  if [[ -n "$PID" ]]; then
    log "Stopping process on port 3002 (PID: $PID)..."
    kill "$PID" 2>/dev/null || true
  else
    warn "No process found on port 3002."
  fi
fi

# Stop Docker containers
log "Stopping Docker containers..."
cd "$SCRIPT_DIR"
docker compose down
log "Docker containers stopped."

echo ""
echo "=================================================================="
echo "  ✅  Bakong Payment Service stopped."
echo "=================================================================="
echo ""
