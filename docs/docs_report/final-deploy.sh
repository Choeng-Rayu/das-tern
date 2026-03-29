#!/bin/bash
# Final deployment script - run this on the VPS
# Usage: bash final-deploy.sh

set -euo pipefail

VPS_IP="167.71.194.68"
REPO_DIR="/root/das-tern"
EMAIL="choengrayu307@gmail.com"

echo "=========================================="
echo "  DasTern Final Deployment"
echo "=========================================="

# Step 1: Pull latest code
echo "[1/4] Pulling latest code..."
cd "$REPO_DIR"
git pull origin main 2>&1 || echo "Pull failed, continuing..."

# Step 2: Copy fixed Nginx config
echo "[2/4] Applying Nginx config..."
cp "$REPO_DIR/nginx/dastern.conf" /etc/nginx/sites-available/dastern
ln -sf /etc/nginx/sites-available/dastern /etc/nginx/sites-enabled/dastern

# Step 3: Test and reload Nginx
echo "[3/4] Testing and reloading Nginx..."
nginx -t && systemctl reload nginx
echo "✓ Nginx reloaded successfully"

# Step 4: Verify containers
echo "[4/4] Verifying containers..."
sleep 5
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Test endpoints:"
echo "  https://api.dastern.site/api/v1/health"
echo "  https://ocr.dastern.site/api/v1/health"
echo "  https://ai.dastern.site/"
echo ""

