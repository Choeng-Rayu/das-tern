# 🎉 DasTern Deployment - Final Steps

## ✅ What's Been Completed

1. **DNS Configuration** ✓
   - api.dastern.site → 167.71.194.68
   - ocr.dastern.site → 167.71.194.68
   - ai.dastern.site → 167.71.194.68

2. **SSL Certificates** ✓
   - Let's Encrypt certs issued for all 3 subdomains
   - Located in `/etc/letsencrypt/live/`

3. **Docker Containers** ✓
   - dastern-backend (3001) - HEALTHY
   - dastern-ocr (8000) - HEALTHY
   - dastern-ai-llm (8001) - HEALTHY
   - All infrastructure (postgres, redis, rabbitmq, minio) - HEALTHY

4. **Nginx Config** ⚠️ NEEDS FIX
   - Fixed http2 directive syntax (moved to listen line)
   - File: `/root/das-tern/nginx/dastern.conf`

---

## 🔧 Final Manual Steps (Run on VPS)

SSH into your VPS:
```bash
ssh root@167.71.194.68
# Password: rayu@dastern@1VPS
```

Then run these commands:

```bash
cd /root/das-tern

# Pull latest code
git pull origin main

# Apply fixed Nginx config
cp /root/das-tern/nginx/dastern.conf /etc/nginx/sites-available/dastern
ln -sf /etc/nginx/sites-available/dastern /etc/nginx/sites-enabled/dastern

# Test and reload
nginx -t
systemctl reload nginx

# Verify
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

---

## ✅ Verify It Works

Test from your local machine:

```bash
curl https://api.dastern.site/api/v1/health
curl https://ocr.dastern.site/api/v1/health
curl https://ai.dastern.site/
```

All should return **200 OK** with JSON responses.

---

## 🚀 Your Services Are Live!

- **Backend API**: https://api.dastern.site
- **OCR Service**: https://ocr.dastern.site
- **AI LLM Service**: https://ai.dastern.site

---

## 📝 Future Deployments

After this, to deploy new code:

```bash
cd /root/das-tern
git pull origin main
bash restart.sh
```

The `restart.sh` script will automatically rebuild and restart services.

