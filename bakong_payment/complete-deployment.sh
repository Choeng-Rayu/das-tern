#!/bin/bash
# ============================================================================
# Complete bakong_payment deployment manually
# Run with: sudo bash complete-deployment.sh
# ============================================================================

set -e

echo ""
echo "=========================================================================="
echo "               COMPLETING DEPLOYMENT - NGINX & SSL"
echo "=========================================================================="
echo ""

# Step 1: Nginx directories
echo "[1/5] Setting up Nginx directories..."
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
echo "✓ Directories created"

# Step 2: Copy Nginx config
echo ""
echo "[2/5] Configuring Nginx..."
cp /home/rayu/das-tern/bakong_payment/nginx.payment.conf /etc/nginx/sites-available/payment.dastern.site
ln -sf /etc/nginx/sites-available/payment.dastern.site /etc/nginx/sites-enabled/payment.dastern.site
echo "✓ Nginx config installed"

# Step 3: Add rate limiting
echo ""
echo "[3/5] Adding rate limiting to Nginx..."
if ! grep -q "limit_req_zone" /etc/nginx/nginx.conf; then
  sed -i "/http {/a\\    limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;" /etc/nginx/nginx.conf
  echo "✓ Rate limiting added"
else
  echo "✓ Rate limiting already configured"
fi

# Step 4: Test and start Nginx
echo ""
echo "[4/5] Testing and starting Nginx..."
if nginx -t &>/dev/null; then
  systemctl start nginx
  echo "✓ Nginx started successfully"
else
  echo "✗ Nginx config test failed!"
  nginx -t
  exit 1
fi

# Step 5: Prepare Certbot
echo ""
echo "[5/5] Preparing Certbot for SSL..."
mkdir -p /var/www/certbot
chmod 755 /var/www/certbot
echo "✓ Certbot webroot ready"

# Step 6: Start Docker containers
echo ""
echo "Starting Docker containers..."
cd /home/rayu/das-tern/bakong_payment
docker compose -f docker-compose.prod.yml up -d
sleep 5

# Step 7: Request SSL certificate
echo ""
echo "Requesting SSL certificate from Let's Encrypt..."
if certbot certonly \
  --webroot \
  -w /var/www/certbot \
  -d payment.dastern.site \
  --non-interactive \
  --agree-tos \
  --email dastern.healthcare@gmail.com \
  --force-renewal 2>&1 | tee /tmp/certbot.log
then
  echo "✓ SSL certificate obtained"
  
  # Reload Nginx
  echo ""
  echo "Reloading Nginx with SSL..."
  systemctl reload nginx
  sleep 2
  echo "✓ Nginx reloaded"
else
  echo "⚠ Certbot request failed (DNS might not be propagated yet)"
  cat /tmp/certbot.log
  echo ""
  echo "You can manually run later:"
  echo "  sudo certbot certonly --webroot -w /var/www/certbot -d payment.dastern.site --email dastern.healthcare@gmail.com"
fi

# Verification
echo ""
echo "=========================================================================="
echo "               DEPLOYMENT VERIFICATION"
echo "=========================================================================="
echo ""

echo "Docker containers:"
docker compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml ps

echo ""
echo "Nginx status:"
systemctl status nginx --no-pager | head -3

echo ""
echo "SSL certificates:"
certbot certificates

echo ""
echo "=========================================================================="
echo "               ✓ DEPLOYMENT COMPLETE"
echo "=========================================================================="
echo ""
echo "Application should be accessible at:"
echo "  https://payment.dastern.site/api/health"
echo ""
echo "Make sure:"
echo "  1. DNS points to your public IP: 117.20.116.46 (or updated public IP)"
echo "  2. Router port forwarding is configured (80→80, 443→443)"
echo ""
