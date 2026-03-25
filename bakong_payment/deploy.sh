#!/usr/bin/env bash
# ============================================================================
# deploy.sh - Complete deployment script for bakong_payment
# Run this script with: sudo bash deploy.sh
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/rayu/das-tern/bakong_payment"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"
NGINX_CONFIG="$PROJECT_DIR/nginx.payment.conf"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/payment.dastern.site"
CERTBOT_WEBROOT="/var/www/certbot"
DOMAIN="payment.dastern.site"
EMAIL="dastern.healthcare@gmail.com"

# Rate limiting zone (add to nginx.conf)
RATE_LIMIT_CONFIG="limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;"

# Functions
log() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  error "This script must be run as root. Use: sudo bash deploy.sh"
  exit 1
fi

echo ""
echo "=========================================================================="
echo "               BAKONG PAYMENT SERVICE - FULL DEPLOYMENT"
echo "=========================================================================="
echo ""

# Step 1: Check prerequisites
log "Step 1/8: Checking prerequisites..."
command -v docker &> /dev/null || { error "Docker not installed"; exit 1; }
docker compose version &> /dev/null || { error "Docker Compose not installed"; exit 1; }
command -v nginx &> /dev/null || { error "Nginx not installed"; exit 1; }
command -v certbot &> /dev/null || { error "Certbot not installed"; exit 1; }
success "All prerequisites met"

# Step 2: Create necessary directories
log "Step 2/8: Setting up directories..."
mkdir -p "$CERTBOT_WEBROOT"
mkdir -p /var/www/payment.dastern.site
mkdir -p /var/log/bakong_payment
chmod 755 "$CERTBOT_WEBROOT"
success "Directories created"

# Step 3: Verify DNS resolution
log "Step 3/8: Verifying DNS configuration..."
RESOLVED=$(dig +short "$DOMAIN" 2>/dev/null | tail -1 || echo "")
PUBLIC_IP=$(curl -s http://api.ipify.org)

if [ -z "$RESOLVED" ]; then
  warn "DNS not resolving for $DOMAIN yet"
  warn "Make sure to update your DNS A record to: $PUBLIC_IP"
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r; echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "DNS must be configured first"
    exit 1
  fi
else
  if [ "$RESOLVED" == "$PUBLIC_IP" ]; then
    success "DNS correctly resolves $DOMAIN → $PUBLIC_IP"
  else
    warn "DNS resolves to $RESOLVED, but public IP is $PUBLIC_IP"
    warn "Update your DNS A record to: $PUBLIC_IP"
  fi
fi

# Step 4: Stop existing services
log "Step 4/8: Stopping existing services..."
docker compose -f "$DOCKER_COMPOSE_FILE" down 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
sleep 2
success "Services stopped"

# Step 5: Pull and build Docker images
log "Step 5/8: Building Docker images (this may take 2-5 minutes)..."
cd "$PROJECT_DIR"
docker compose -f "$DOCKER_COMPOSE_FILE" build --no-cache app
success "Docker images built"

# Step 6: Configure and enable Nginx
log "Step 6/8: Configuring Nginx..."

# Add rate limiting to nginx.conf if not already present
if ! grep -q "limit_req_zone" /etc/nginx/nginx.conf; then
  sed -i "/http {/a\\    $RATE_LIMIT_CONFIG" /etc/nginx/nginx.conf
fi

# Copy nginx config to sites-available
cp "$NGINX_CONFIG" "/etc/nginx/sites-available/payment.dastern.site"

# Enable site if not already enabled
if [[ ! -L "$NGINX_SITES_ENABLED" ]]; then
  ln -s "/etc/nginx/sites-available/payment.dastern.site" "$NGINX_SITES_ENABLED"
fi

# Test Nginx configuration
if ! nginx -t &>/dev/null; then
  error "Nginx configuration test failed"
  nginx -t
  exit 1
fi

success "Nginx configured"

# Step 7: Obtain SSL certificate with Certbot
log "Step 7/8: Obtaining SSL certificate from Let's Encrypt..."
log "Starting Nginx for ACME challenge..."
systemctl start nginx

# Wait for Nginx to start
sleep 3

# Request certificate using webroot method
if certbot certonly \
  --webroot \
  -w "$CERTBOT_WEBROOT" \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  --force-renewal 2>&1 | tee /tmp/certbot.log
then
  success "SSL certificate obtained"
else
  error "Certbot failed. Check /tmp/certbot.log for details"
  cat /tmp/certbot.log
  exit 1
fi

# Step 8: Start services
log "Step 8/8: Starting all services..."

# Start Docker services
cd "$PROJECT_DIR"
docker compose -f "$DOCKER_COMPOSE_FILE" up -d
sleep 5

# Reload Nginx with SSL
systemctl reload nginx

success "All services started"

# Verify deployment
echo ""
echo "=========================================================================="
echo "               DEPLOYMENT VERIFICATION"
echo "=========================================================================="
echo ""

log "Checking Docker containers..."
docker compose -f "$DOCKER_COMPOSE_FILE" ps

log "Testing application health..."
sleep 3

# Test via localhost
if curl -s http://127.0.0.1:3002/api/health > /dev/null; then
  success "Application is responding on localhost:3002"
else
  warn "Application health check failed"
fi

# Test via HTTPS
if curl -sk https://localhost/api/health > /dev/null 2>&1; then
  success "HTTPS reverse proxy working on localhost"
else
  warn "HTTPS reverse proxy not responding yet"
fi

# Test via domain (if DNS is ready)
if command -v dig &> /dev/null; then
  RESOLVED=$(dig +short "$DOMAIN" @8.8.8.8 2>/dev/null | tail -1 || echo "")
  if [ "$RESOLVED" == "$PUBLIC_IP" ]; then
    if timeout 5 curl -sk "https://$DOMAIN/api/health" > /dev/null 2>&1; then
      success "Application is publicly accessible at https://$DOMAIN"
    else
      warn "Domain resolves but HTTPS request timed out (port forwarding may not be configured)"
    fi
  else
    warn "Domain not yet resolving to public IP"
  fi
fi

echo ""
echo "=========================================================================="
echo "               DEPLOYMENT COMPLETE"
echo "=========================================================================="
echo ""
echo "Application URL: https://$DOMAIN"
echo "Public IP: $PUBLIC_IP"
echo ""
echo "Next steps:"
echo "  1. Verify DNS A record points to: $PUBLIC_IP"
echo "  2. Configure router port forwarding (80→80, 443→443) to: 10.212.42.210"
echo "  3. SSL auto-renewal: certbot renew (runs daily via cron)"
echo ""
echo "Docker commands:"
echo "  View logs: docker compose -f $DOCKER_COMPOSE_FILE logs -f app"
echo "  Stop: docker compose -f $DOCKER_COMPOSE_FILE down"
echo "  Restart: docker compose -f $DOCKER_COMPOSE_FILE restart"
echo ""
echo "=========================================================================="
