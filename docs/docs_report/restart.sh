#!/bin/bash
# ============================================================
# restart.sh — Run on VPS after: git pull origin main
#
# Usage:
#   git pull origin main
#   bash restart.sh
#
# What it does:
#   1. Detects which service directories changed in the last commit
#   2. Rebuilds only the changed Docker images
#   3. Restarts all app containers (DB containers keep running)
#   4. Prunes dangling images to save disk space
#   5. Shows container status and tail logs
# ============================================================
set -euo pipefail

REPO_DIR="/root/das-tern"
COMPOSE_FILE="$REPO_DIR/docker-compose.prod.yml"
LOG_FILE="/var/log/dastern-deploy.log"

# ── Colour helpers ────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }

echo "" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
info "$(date '+%Y-%m-%d %H:%M:%S')  DasTern restart starting..."
echo "============================================" | tee -a "$LOG_FILE"

cd "$REPO_DIR"

# ── Detect what changed ───────────────────────────────────
CHANGED=$(git diff HEAD~1 HEAD --name-only 2>/dev/null || echo "all")
info "Changed files: $(echo "$CHANGED" | tr '\n' ' ')"

REBUILD_BACKEND=false
REBUILD_OCR=false
REBUILD_AI=false

# Rebuild if service directory or compose file changed
if echo "$CHANGED" | grep -qE "^backend_nestjs/|^docker-compose\.prod\.yml|^\.env\.prod|all"; then
  REBUILD_BACKEND=true
fi
if echo "$CHANGED" | grep -qE "^ocr/|^docker-compose\.prod\.yml|all"; then
  REBUILD_OCR=true
fi
if echo "$CHANGED" | grep -qE "^ai-llm-service/|^docker-compose\.prod\.yml|all"; then
  REBUILD_AI=true
fi

# ── Build changed services ────────────────────────────────
SERVICES_TO_BUILD=""
$REBUILD_BACKEND && SERVICES_TO_BUILD="$SERVICES_TO_BUILD backend"
$REBUILD_OCR     && SERVICES_TO_BUILD="$SERVICES_TO_BUILD ocr"
$REBUILD_AI      && SERVICES_TO_BUILD="$SERVICES_TO_BUILD ai-llm"

if [ -n "${SERVICES_TO_BUILD// /}" ]; then
  info "Rebuilding:$SERVICES_TO_BUILD ..."
  docker compose -f "$COMPOSE_FILE" build --no-cache $SERVICES_TO_BUILD 2>&1 | tee -a "$LOG_FILE"
else
  warn "No service code changed — skipping rebuild (only restarting containers)"
fi

# ── Restart app containers (keep DB services running) ─────
info "Restarting app containers..."
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans 2>&1 | tee -a "$LOG_FILE"

# ── Cleanup dangling images ───────────────────────────────
info "Pruning dangling images..."
docker image prune -f 2>&1 | tee -a "$LOG_FILE"

# ── Reload nginx if config changed ───────────────────────
if echo "$CHANGED" | grep -qE "^nginx/"; then
  info "Nginx config changed — reloading nginx..."
  cp "$REPO_DIR/nginx/dastern.conf" /etc/nginx/sites-available/dastern
  nginx -t && systemctl reload nginx && info "Nginx reloaded OK"
fi

# ── Show status ───────────────────────────────────────────
echo "" | tee -a "$LOG_FILE"
info "Container status:"
docker compose -f "$COMPOSE_FILE" ps 2>&1 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
info "$(date '+%Y-%m-%d %H:%M:%S')  Restart complete!"
echo ""
info "Useful commands:"
echo "  Logs (all):     docker compose -f $COMPOSE_FILE logs -f --tail=50"
echo "  Logs (backend): docker compose -f $COMPOSE_FILE logs -f --tail=50 backend"
echo "  Health check:   curl -s http://127.0.0.1:3001/api/v1/health"
echo "============================================" | tee -a "$LOG_FILE"

