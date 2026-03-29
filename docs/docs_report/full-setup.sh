#!/bin/bash
# ============================================================
# full-setup.sh — Complete VPS setup + build + start
# Includes: swap, docker, nginx, certbot acme temp, 
#           git pull, build images, start containers,
#           setup auto-deploy key + GitHub Actions
# Run: bash /root/das-tern/full-setup.sh
# ============================================================
set -euo pipefail

REPO_DIR="/root/das-tern"
COMPOSE_FILE="$REPO_DIR/docker-compose.prod.yml"
LOG_FILE="/var/log/dastern-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================================"
echo "  Das Tern Full VPS Setup — $(date)"
echo "======================================================"

# ─── 1. Swap (ensure 2GB) ──────────────────────────────────
echo ""
echo "[1/8] Setting up swap..."
if ! swapon --show | grep -q swapfile; then
  if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    echo '/swapfile none swap sw 0 0' | grep -q swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
  swapon /swapfile 2>/dev/null || true
fi
sysctl -w vm.swappiness=10 >/dev/null
echo "  Swap: $(free -h | awk '/Swap/{print $2}')"
echo "  RAM:  $(free -h | awk '/Mem/{print $2}')"

# ─── 2. Install dependencies ───────────────────────────────
echo ""
echo "[2/8] Installing packages (Docker, Nginx, Certbot)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# Docker
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh -s -- --quiet
  systemctl enable docker --quiet
  systemctl start docker
fi
echo "  Docker: $(docker --version)"

# Nginx
if ! command -v nginx &>/dev/null; then
  apt-get install -y -q nginx
fi
systemctl enable nginx --quiet
systemctl start nginx 2>/dev/null || true
echo "  Nginx: $(nginx -v 2>&1)"

# Certbot 
if ! command -v certbot &>/dev/null; then
  apt-get install -y -q certbot python3-certbot-nginx
fi
echo "  Certbot: $(certbot --version 2>&1)"

# UFW firewall
apt-get install -y -q ufw 2>/dev/null || true
ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1
ufw allow ssh >/dev/null 2>&1
ufw allow 80/tcp >/dev/null 2>&1
ufw allow 443/tcp >/dev/null 2>&1
ufw --force enable >/dev/null 2>&1
echo "  Firewall: SSH/HTTP/HTTPS open"

# ─── 3. SSH deploy key (for GitHub Actions) ────────────────
echo ""
echo "[3/8] Setting up SSH deploy key..."
DEPLOY_KEY_FILE="/root/.ssh/dastern_deploy"
if [ ! -f "$DEPLOY_KEY_FILE" ]; then
  ssh-keygen -t ed25519 -f "$DEPLOY_KEY_FILE" -N "" -C "dastern-github-actions"
  cat "$DEPLOY_KEY_FILE.pub" >> /root/.ssh/authorized_keys
  sort -u /root/.ssh/authorized_keys -o /root/.ssh/authorized_keys
  echo "  Deploy key created. Add this PUBLIC key to GitHub repo deploy keys:"
  echo "  (Settings → Deploy keys → Add key, with Write access=NO)"
  echo "  ---COPY FROM HERE---"
  cat "$DEPLOY_KEY_FILE.pub"
  echo "  ---COPY TO HERE---"
  echo ""
  echo "  Add this PRIVATE key to GitHub Secrets as VPS_SSH_KEY:"
  echo "  (Settings → Secrets → Actions → New secret)"
  echo "  ---COPY FROM HERE---"
  cat "$DEPLOY_KEY_FILE"
  echo "  ---COPY TO HERE---"
else
  echo "  Deploy key already exists at $DEPLOY_KEY_FILE"
fi

# ─── 4. Git pull latest ────────────────────────────────────
echo ""
echo "[4/8] Updating repo from GitHub..."
cd "$REPO_DIR"
git fetch origin main 2>&1 || true
git reset --hard origin/main 2>&1 || true
echo "  Repo: $(git log -1 --oneline)"

# ─── 5. Copy root .env ─────────────────────────────────────
echo ""
echo "[5/8] Setting up environment files..."
if [ -f "$REPO_DIR/.env.prod" ]; then
  cp "$REPO_DIR/.env.prod" "$REPO_DIR/.env"
  echo "  Root .env set from .env.prod"
fi
echo "  backend_nestjs/.env: $([ -f $REPO_DIR/backend_nestjs/.env ] && echo 'exists' || echo 'MISSING')"
echo "  ai-llm-service/.env: $([ -f $REPO_DIR/ai-llm-service/.env ] && echo 'exists' || echo 'MISSING')"

# ─── 6. Configure Nginx (temp HTTP only) ───────────────────
echo ""
echo "[6/8] Configuring Nginx (HTTP while waiting for DNS)..."
mkdir -p /var/www/certbot

# Install temp HTTP config for all subdomains (no SSL yet)
cat > /etc/nginx/sites-available/dastern << 'NGINXTEMP'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name api.dastern.site ocr.dastern.site ai.dastern.site _;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Temporary: proxy to backend if running (for health checks)
    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 2s;
        proxy_read_timeout 5s;
    }

    location /ocr/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_connect_timeout 2s;
    }

    location /ai/ {
        proxy_pass http://127.0.0.1:8001/;
        proxy_set_header Host $host;
        proxy_connect_timeout 2s;
    }

    location / {
        return 200 '{"status":"das-tern running","note":"HTTPS available after DNS setup"}';
        add_header Content-Type application/json;
    }
}
NGINXTEMP

rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
ln -sf /etc/nginx/sites-available/dastern /etc/nginx/sites-enabled/dastern
nginx -t 2>&1
systemctl reload nginx
echo "  Nginx HTTP config active (HTTPS after DNS)"

# ─── 7. Build Docker images (sequential, memory-safe) ──────
echo ""
echo "[7/8] Building Docker images (sequential)..."
cd "$REPO_DIR"

# Set memory limits for npm to prevent OOM
export NODE_OPTIONS="--max-old-space-size=1024"

echo "  --- Building ai-llm (Python/FastAPI) ---"
docker build --no-cache -t das-tern-ai-llm ./ai-llm-service
echo "  ai-llm image: OK"

echo "  --- Building ocr (Python/FastAPI) ---"
docker build --no-cache -t das-tern-ocr ./ocr
echo "  ocr image: OK"

echo "  --- Building backend (NestJS) ---"
docker build --no-cache -t das-tern-backend ./backend_nestjs
echo "  backend image: OK"

echo "  All images built:"
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E "das-tern|REPO"

# ─── 8. Start all containers ───────────────────────────────
echo ""
echo "[8/8] Starting all containers..."
cd "$REPO_DIR"

# Start databases first
echo "  Starting databases..."
docker compose -f "$COMPOSE_FILE" up -d postgres redis rabbitmq minio
echo "  Waiting 20s for databases to be healthy..."
sleep 20

# Check DB health
docker compose -f "$COMPOSE_FILE" ps postgres redis

# Start app services
echo "  Starting app services..."
docker compose -f "$COMPOSE_FILE" up -d backend ocr ai-llm

echo "  Waiting 30s for app services to start..."
sleep 30

echo ""
echo "======================================================"
echo "  Container Status:"
docker compose -f "$COMPOSE_FILE" ps
echo ""
echo "======================================================"
echo ""
echo "✅ Setup complete!"
echo ""
echo "  HTTP endpoints (before DNS):"
echo "  http://167.71.194.68/"
echo ""
echo "  After DNS is configured in Namecheap:"
echo "  bash /root/das-tern/setup-ssl.sh"
echo ""
echo "  For GitHub Actions auto-deploy, add these secrets:"
echo "  VPS_HOST = 167.71.194.68"
echo "  VPS_USER = root"
echo "  VPS_SSH_KEY = (the private key printed in step 3)"
echo ""
echo "  Deploy log: tail -f $LOG_FILE"
echo "======================================================"
