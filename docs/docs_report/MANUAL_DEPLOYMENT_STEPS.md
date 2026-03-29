# 🚀 Manual Deployment Steps for DasTern

## Current Status
✅ DNS configured and working  
✅ SSL certificates issued for all 3 subdomains  
✅ All containers healthy (backend, ocr, ai-llm)  
⚠️ Nginx config has http2 syntax error (needs fix)

---

## STEP 1 — SSH into VPS

```bash
ssh root@167.71.194.68
# Password: rayu@dastern@1VPS
```

---

## STEP 2 — Pull Latest Code

```bash
cd /root/das-tern
git pull origin main
```

---

## STEP 3 — Apply Fixed Nginx Config

```bash
# Copy the fixed config
cp /root/das-tern/nginx/dastern.conf /etc/nginx/sites-available/dastern

# Ensure symlink
ln -sf /etc/nginx/sites-available/dastern /etc/nginx/sites-enabled/dastern

# Test config
nginx -t

# Reload Nginx
systemctl reload nginx
```

Expected output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

## STEP 4 — Verify All Services

```bash
# Check container status
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Should show all 7 containers as healthy
```

---

## STEP 5 — Test HTTPS Endpoints

From your local machine:

```bash
curl https://api.dastern.site/api/v1/health
curl https://ocr.dastern.site/api/v1/health
curl https://ai.dastern.site/
```

All should return 200 OK with JSON responses.

---

## Done! 🎉

Your DasTern backend is now live on:
- **API**: https://api.dastern.site
- **OCR**: https://ocr.dastern.site
- **AI LLM**: https://ai.dastern.site

