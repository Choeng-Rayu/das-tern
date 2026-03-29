#!/bin/bash
# ============================================================
# setup-ssl.sh — Run AFTER DNS is configured in Namecheap
# ============================================================
# Namecheap DNS records required (all A records → 167.71.194.68):
#   api.dastern.site
#   ocr.dastern.site
#   ai.dastern.site
# ============================================================
set -euo pipefail

DOMAIN="dastern.site"
VPS_IP="167.71.194.68"
EMAIL="choengrayu307@gmail.com"
SUBDOMAINS=("api.dastern.site" "ocr.dastern.site" "ai.dastern.site")

echo "====================================================="
echo "  SSL Certificate Setup for dastern.site subdomains"
echo "====================================================="

# Verify each subdomain resolves to this server
echo "[1/3] Checking DNS resolution..."
for SUB in "${SUBDOMAINS[@]}"; do
  RESOLVED=$(dig +short "$SUB" 2>/dev/null | tail -1 || echo "")
  if [ "$RESOLVED" != "$VPS_IP" ]; then
    echo "ERROR: $SUB resolves to '${RESOLVED:-nothing}' — expected $VPS_IP"
    echo "Set this A record in Namecheap first and wait for DNS propagation."
    exit 1
  fi
  echo "  OK: $SUB → $RESOLVED"
done

# Start temporary HTTP nginx for ACME challenge
echo "[2/3] Configuring temporary Nginx for Certbot challenge..."
mkdir -p /var/www/certbot

cat > /etc/nginx/sites-available/dastern_acme << 'NGINXTMP'
server {
    listen 80;
    listen [::]:80;
    server_name api.dastern.site ocr.dastern.site ai.dastern.site;
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    location / {
        return 200 '{"status":"waiting for SSL"}';
        add_header Content-Type application/json;
    }
}
NGINXTMP

ln -sf /etc/nginx/sites-available/dastern_acme /etc/nginx/sites-enabled/dastern
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Obtain individual cert for each subdomain
echo "[3/3] Obtaining SSL certificates from Let's Encrypt..."
for SUB in "${SUBDOMAINS[@]}"; do
  echo "  Getting cert for $SUB..."
  certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$SUB" \
    --non-interactive
  echo "  Certificate issued for $SUB"
done

# Switch to full HTTPS Nginx config with all subdomains
cp /root/das-tern/nginx/dastern.conf /etc/nginx/sites-available/dastern
ln -sf /etc/nginx/sites-available/dastern /etc/nginx/sites-enabled/dastern
nginx -t && systemctl reload nginx
echo "  Nginx switched to HTTPS config"

# Auto-renewal cron
(crontab -l 2>/dev/null | grep -v certbot; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") | crontab -

echo ""
echo "====================================================="
echo "  SSL Setup Complete!"
echo ""
echo "  API:      https://api.dastern.site/api/v1/health"
echo "  OCR:      https://ocr.dastern.site/api/v1/health"
echo "  AI LLM:   https://ai.dastern.site/health"
echo "====================================================="
