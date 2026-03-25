#!/bin/bash
# ============================================================
# auto-deploy.sh — Run on VPS when GitHub pushes to main
# Triggered by GitHub Actions via SSH
# ============================================================
set -euo pipefail

REPO_DIR="/root/das-tern"
COMPOSE_FILE="$REPO_DIR/docker-compose.prod.yml"
LOG_FILE="/var/log/dastern-deploy.log"
DEPLOY_LOCK="/tmp/dastern-deploy.lock"

# Prevent concurrent deploys
if [ -f "$DEPLOY_LOCK" ]; then
  echo "$(date): Deploy already running, skipping." | tee -a "$LOG_FILE"
  exit 0
fi
touch "$DEPLOY_LOCK"
trap "rm -f $DEPLOY_LOCK" EXIT

echo "============================================" | tee -a "$LOG_FILE"
echo "$(date): Starting auto-deploy..." | tee -a "$LOG_FILE"

cd "$REPO_DIR"

# Pull latest code from main
echo "$(date): Pulling latest code..." | tee -a "$LOG_FILE"
git fetch origin main 2>&1 | tee -a "$LOG_FILE"
git reset --hard origin/main 2>&1 | tee -a "$LOG_FILE"

# Detect which service directories changed
CHANGED=$(git diff HEAD~1 --name-only 2>/dev/null || echo "all")
echo "$(date): Changed files: $CHANGED" | tee -a "$LOG_FILE"

REBUILD_BACKEND=false
REBUILD_OCR=false
REBUILD_AI=false

if echo "$CHANGED" | grep -q "^backend_nestjs/\|all"; then REBUILD_BACKEND=true; fi
if echo "$CHANGED" | grep -q "^ocr/\|all"; then REBUILD_OCR=true; fi
if echo "$CHANGED" | grep -q "^ai-llm-service/\|all"; then REBUILD_AI=true; fi

# Always rebuild if docker-compose.prod.yml changed
if echo "$CHANGED" | grep -q "docker-compose.prod.yml\|^\.env"; then
  REBUILD_BACKEND=true; REBUILD_AI=true; REBUILD_OCR=true
fi

# Build changed services
SERVICES_TO_BUILD=""
$REBUILD_BACKEND && SERVICES_TO_BUILD="$SERVICES_TO_BUILD backend"
$REBUILD_OCR    && SERVICES_TO_BUILD="$SERVICES_TO_BUILD ocr"
$REBUILD_AI     && SERVICES_TO_BUILD="$SERVICES_TO_BUILD ai-llm"

if [ -n "$SERVICES_TO_BUILD" ]; then
  echo "$(date): Rebuilding services:$SERVICES_TO_BUILD" | tee -a "$LOG_FILE"
  docker compose -f "$COMPOSE_FILE" build $SERVICES_TO_BUILD 2>&1 | tee -a "$LOG_FILE"
else
  echo "$(date): No service code changed, skipping rebuild." | tee -a "$LOG_FILE"
fi

# Restart all app services (db services keep running)
echo "$(date): Restarting app containers..." | tee -a "$LOG_FILE"
docker compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "$LOG_FILE"

# Remove dangling images to free disk space
docker image prune -f 2>&1 | tee -a "$LOG_FILE"

echo "$(date): Deploy complete!" | tee -a "$LOG_FILE"
echo "============================================" | tee -a "$LOG_FILE"
