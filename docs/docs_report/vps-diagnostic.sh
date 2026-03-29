#!/bin/bash

echo "=== DAS-TERN VPS Diagnostic Report ==="
echo "Timestamp: $(date)"
echo ""

echo "1. DOCKER CONTAINERS STATUS"
echo "================================"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "2. BACKEND CONTAINER LOGS (last 20 lines)"
echo "=========================================="
docker logs dastern-backend --tail 20 2>&1
echo ""

echo "3. BACKEND LISTENING ON PORT 3001?"
echo "===================================="
docker exec dastern-backend netstat -tlnp 2>/dev/null | grep 3001 || echo "Not found in container"
echo ""

echo "4. NGINX STATUS"
echo "==============="
systemctl is-active nginx && echo "✓ Nginx is running" || echo "✗ Nginx is NOT running"
nginx -t 2>&1
echo ""

echo "5. SSL CERTIFICATES"
echo "==================="
ls -la /etc/letsencrypt/live/ 2>/dev/null | grep -E "api|ocr|ai"
echo ""

echo "6. DNS RESOLUTION"
echo "================="
dig +short api.dastern.site
dig +short ocr.dastern.site
dig +short ai.dastern.site
echo ""

echo "7. TEST BACKEND DIRECTLY (localhost:3001)"
echo "=========================================="
curl -s http://127.0.0.1:3001/api/v1/health 2>&1 | head -20
echo ""

echo "8. TEST VIA NGINX (localhost)"
echo "=============================="
curl -sk https://127.0.0.1/api/v1/health 2>&1 | head -20
echo ""

echo "9. ENVIRONMENT VARIABLES"
echo "========================"
grep -E "^(NODE_ENV|ALLOWED_ORIGINS|API_PREFIX|PORT|HOST)" /root/das-tern/backend_nestjs/.env 2>/dev/null || echo "Could not read .env"
echo ""

echo "=== End of Diagnostic Report ==="

