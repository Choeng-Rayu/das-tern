#!/bin/bash
# ============================================================
# deploy-vps.sh — First-time VPS setup for das-tern
# Run ONCE on the VPS as root: bash ~/das-tern/deploy-vps.sh
#
# For subsequent deploys after git pull, use:
#   git pull origin main && bash restart.sh
#
# Domain: dastern.site  |  VPS: 167.71.194.68
# ============================================================
set -euo pipefail

DOMAIN="dastern.site"
REPO_DIR="/root/das-tern"
EMAIL="choengrayu307@gmail.com"
SUBDOMAINS=("api.dastern.site" "ocr.dastern.site" "ai.dastern.site")

echo "======================================================"
echo "  Das Tern VPS Deployment — $DOMAIN"
echo "======================================================"

# ─── Step 1: Update system ─────────────────────────────────
echo ""
echo "[1/8] Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# ─── Step 2: Install Docker ───────────────────────────────
echo ""
echo "[2/8] Installing Docker..."
if command -v docker &>/dev/null; then
  echo "  Docker already installed: $(docker --version)"
else
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
  echo "  Docker installed: $(docker --version)"
fi

# ─── Step 3: Install Nginx ────────────────────────────────
echo ""
echo "[3/8] Installing Nginx..."
apt-get install -y -qq nginx
systemctl enable nginx
echo "  Nginx installed: $(nginx -v 2>&1)"

# ─── Step 4: Install Certbot ──────────────────────────────
echo ""
echo "[4/8] Installing Certbot..."
apt-get install -y -qq certbot python3-certbot-nginx
echo "  Certbot installed: $(certbot --version)"

# ─── Step 5: Setup UFW Firewall ───────────────────────────
echo ""
echo "[5/8] Configuring firewall..."
apt-get install -y -qq ufw
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "  Firewall configured: SSH, HTTP, HTTPS allowed"

# ─── Step 6: Copy config files ────────────────────────────
echo ""
echo "[6/8] Setting up config files..."

# Copy root .env (from .env.prod) for docker-compose infra secrets
cp "$REPO_DIR/.env.prod" "$REPO_DIR/.env"
echo "  Root .env created from .env.prod"

# Copy backend production env
if [ -f "$REPO_DIR/backend_nestjs/.env.prod" ]; then
  cp "$REPO_DIR/backend_nestjs/.env.prod" "$REPO_DIR/backend_nestjs/.env"
  echo "  backend_nestjs/.env created from .env.prod"
fi

# Setup Nginx — install the full dastern config
mkdir -p /var/www/certbot
cp "$REPO_DIR/nginx/dastern.conf" /etc/nginx/sites-available/dastern
rm -f /etc/nginx/sites-enabled/default

# Use HTTP-only temp config while SSL certs don't exist yet
cat > /etc/nginx/sites-available/dastern_temp << 'NGINXTMP'
server {
    listen 80;
    listen [::]:80;
    server_name api.dastern.site ocr.dastern.site ai.dastern.site;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 200 '{"status":"ok - SSL pending"}';
        add_header Content-Type application/json;
    }
}
NGINXTMP

ln -sf /etc/nginx/sites-available/dastern_temp /etc/nginx/sites-enabled/dastern
nginx -t && systemctl reload nginx
echo "  Nginx configured (HTTP-only, waiting for SSL)"

# ─── Step 7: Obtain SSL Certificates for each subdomain ───
echo ""
echo "[7/8] Obtaining SSL certificates from Let's Encrypt..."
echo "  NOTE: Subdomains must resolve to this VPS (167.71.194.68) first."
echo "        If DNS is not ready yet, this step will fail — that is OK."
echo "        Run setup-ssl.sh later once DNS is configured."
echo ""

ALL_CERTS_OK=true
for SUB in "${SUBDOMAINS[@]}"; do
  RESOLVED=$(dig +short "$SUB" 2>/dev/null | tail -1 || echo "")
  if [ "$RESOLVED" != "167.71.194.68" ]; then
    echo "  SKIP: $SUB resolves to '${RESOLVED:-nothing}' (expected 167.71.194.68)"
    ALL_CERTS_OK=false
    continue
  fi
  echo "  Getting cert for $SUB..."
  certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$SUB" \
    --non-interactive && echo "  Certificate issued for $SUB" \
    || { echo "  WARN: certbot failed for $SUB"; ALL_CERTS_OK=false; }
done

if $ALL_CERTS_OK; then
  # All certs obtained — switch to full HTTPS Nginx config
  ln -sf /etc/nginx/sites-available/dastern /etc/nginx/sites-enabled/dastern
  nginx -t && systemctl reload nginx
  echo "  Nginx switched to HTTPS config"
else
  echo "  Some certs missing — keeping HTTP-only nginx config."
  echo "  Run 'bash $REPO_DIR/setup-ssl.sh' after configuring DNS."
fi

# Setup Certbot auto-renewal
(crontab -l 2>/dev/null | grep -v certbot; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -
echo "  Certbot auto-renewal configured"

# ─── Step 8: Build and Start Docker Services ───────────────
echo ""
echo "[8/8] Building and starting Docker containers..."
cd "$REPO_DIR"

# Build all images
docker compose -f docker-compose.prod.yml build --no-cache

# Start database services first, wait for health
docker compose -f docker-compose.prod.yml up -d postgres redis rabbitmq minio
echo "  Waiting for database services to be healthy..."
sleep 15

# Start application services
docker compose -f docker-compose.prod.yml up -d backend ocr ai-llm
echo "  All containers started"

# Wait a bit for services to initialize
sleep 20

# Show status
echo ""
echo "======================================================"
echo "  Container Status:"
docker compose -f docker-compose.prod.yml ps
echo ""
echo "======================================================"
echo ""
echo "✅ Deployment complete!"
echo ""
echo "  Backend API:  https://api.$DOMAIN/api/v1/health"
echo "  OCR Service:  https://ocr.$DOMAIN/api/v1/health"
echo "  AI LLM:       https://ai.$DOMAIN/health"
echo ""
echo "  Logs: docker compose -f $REPO_DIR/docker-compose.prod.yml logs -f"
echo ""
echo "  After pushing new code, on the VPS run:"
echo "    cd $REPO_DIR && git pull origin main && bash restart.sh"
echo ""
echo "  If DNS is not yet configured, set A records for:"
echo "    api.$DOMAIN → 167.71.194.68"
echo "    ocr.$DOMAIN → 167.71.194.68"
echo "    ai.$DOMAIN  → 167.71.194.68"
echo "  Then run: bash $REPO_DIR/setup-ssl.sh"
echo "======================================================"
