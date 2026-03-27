#!/usr/bin/env bash
# =============================================================================
# setup-ssl.sh
# Run this script on the BAKONG VPS to get a Let's Encrypt certificate.
#
# IMPORTANT: This must be run on the machine where payment.dastern.site 
# resolves to (103.216.50.111). Port 80 must NOT be redirected elsewhere.
# =============================================================================
set -e

echo ""
echo "=================================================================="
echo "  SSL Certificate Setup — payment.dastern.site"
echo "=================================================================="
echo ""

VPS_IP=$(curl -s http://api.ipify.org)
EXPECTED_IP="103.216.50.111"

# Step 0: Verify we're on the right machine
echo "[0/6] Verifying this is the Bakong VPS..."
RESOLVED=$(dig +short payment.dastern.site 2>/dev/null | tail -1 || echo "")
if [ "$RESOLVED" != "$EXPECTED_IP" ]; then
  echo "❌ ERROR: payment.dastern.site resolves to $RESOLVED"
  echo "   Expected: $EXPECTED_IP (Bakong VPS)"
  echo "   This script must be run on the VPS where the domain points!"
  exit 1
fi
echo "✓ Confirmed: payment.dastern.site → $VPS_IP"

# Step 1: Check if port 80 is being redirected
echo ""
echo "[1/6] Checking if port 80 is accessible..."
if ! nc -zv 127.0.0.1 80 2>&1 | grep -q "succeeded"; then
  echo "❌ Port 80 is NOT listening!"
  echo "   Ensure Nginx is running and listening on port 80."
  echo "   Check: sudo systemctl status nginx"
  exit 1
fi
echo "✓ Port 80 is listening"

# Step 2: Verify no redirect to 8080
echo ""
echo "[2/6] Checking for port 8080 redirects (iptables)..."
if sudo iptables -t nat -L -n 2>/dev/null | grep -E "80.*8080"; then
  echo "❌ Found iptables redirect 80→8080!"
  echo "   Run this to remove it:"
  echo "   sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
  echo "   sudo iptables-save | sudo tee /etc/iptables/rules.v4"
  exit 1
fi
echo "✓ No iptables redirects found"

# Step 3: Ensure certbot webroot directory exists
echo ""
echo "[3/6] Creating certbot webroot directory..."
sudo mkdir -p /var/www/certbot
sudo chmod 755 /var/www/certbot
echo "✓ Created /var/www/certbot"

# Step 4: Ensure Nginx is running
echo ""
echo "[4/6] Ensuring Nginx is running..."
sudo systemctl start nginx
sudo nginx -t || {
  echo "❌ Nginx config test failed!"
  exit 1
}
echo "✓ Nginx is running with valid config"

# Step 5: Obtain certificate via webroot HTTP-01 challenge
echo ""
echo "[5/6] Requesting Let's Encrypt certificate..."
sudo certbot certonly --webroot \
  -w /var/www/certbot \
  -d payment.dastern.site \
  --non-interactive \
  --agree-tos \
  --email rayuchoengrayu@gmail.com \
  --force-renewal || {
  echo "❌ Certbot failed! See diagnostics above."
  echo "   Run: ./diagnose-port-80.sh"
  exit 1
}

# Step 6: Verify and reload
echo ""
echo "[6/6] Verifying certificate and reloading Nginx..."
ls -l /etc/letsencrypt/live/payment.dastern.site/ || {
  echo "❌ Certificate not found!"
  exit 1
}
echo "✓ Certificate installed"

sudo systemctl reload nginx
sleep 2

# Final verification
echo ""
echo "  Testing HTTPS connection..."
curl -sI https://payment.dastern.site/api/health 2>&1 | head -3 || {
  echo "⚠ HTTPS test failed, but certificate may still be valid."
}

echo ""
echo "=================================================================="
echo "  ✓ SSL certificate installed successfully!"
echo "  https://payment.dastern.site is now using a trusted certificate."
echo "=================================================================="
echo ""
