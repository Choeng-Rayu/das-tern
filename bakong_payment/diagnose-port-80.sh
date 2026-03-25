#!/usr/bin/env bash
# =============================================================================
# diagnose-port-80.sh
# Diagnose why port 80 is redirecting to port 8080
# Run this on the BAKONG VPS (103.216.50.111)
# =============================================================================
set -e

echo ""
echo "=================================================================="
echo "  Diagnosing Port 80 → 8080 Redirect Issue"
echo "=================================================================="
echo ""

# Check 1: Is anything listening on port 80?
echo "[1/6] Checking what's listening on port 80..."
sudo netstat -tlnp 2>/dev/null | grep -E ":80 " || echo "  ✗ Nothing listening on port 80!"

# Check 2: Is Nginx running?
echo ""
echo "[2/6] Nginx status..."
sudo systemctl is-active nginx && echo "  ✓ Nginx is running" || echo "  ✗ Nginx is NOT running"

# Check 3: Nginx config syntax
echo ""
echo "[3/6] Testing Nginx config..."
sudo nginx -t 2>&1 || echo "  ✗ Nginx config has errors"

# Check 4: Check iptables for port redirects
echo ""
echo "[4/6] Checking iptables port forwarding rules..."
sudo iptables -t nat -L -n 2>/dev/null | grep -E "80|8080" || echo "  ℹ No iptables redirects found"

# Check 5: Check /etc/nginx/sites-available/ for port 8080 references
echo ""
echo "[5/6] Checking Nginx configs for port 8080..."
grep -r "8080" /etc/nginx/sites-available/ 2>/dev/null || echo "  ℹ No 8080 references in Nginx"

# Check 6: Test locally (127.0.0.1:80)
echo ""
echo "[6/6] Testing local connection on port 80..."
curl -sI http://127.0.0.1:80/.well-known/acme-challenge/test 2>&1 | head -10 || echo "  ℹ Connection test completed"

echo ""
echo "=================================================================="
echo "  Next Steps:"
echo "=================================================================="
echo ""
echo "If you see port 8080 mentioned above:"
echo "  1. Check /etc/nginx/nginx.conf and /etc/nginx/sites-available/*"
echo "  2. Remove any 'listen 8080' or 'redirect to 8080' directives"
echo "  3. Ensure the payment.dastern.site server block listens on 80 and 443"
echo "  4. Run: sudo systemctl reload nginx"
echo ""
echo "If iptables shows 80→8080 redirect:"
echo "  1. Remove the rule: sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
echo "  2. Save: sudo iptables-save | sudo tee /etc/iptables/rules.v4"
echo ""
echo "=================================================================="
echo ""
