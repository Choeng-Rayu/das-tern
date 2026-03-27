# Bakong Payment - Public Deployment Guide

Deploying bakong_payment service for public internet access with Docker, Nginx, and Let's Encrypt SSL.

:::note
This guide assumes you're deploying on a **Fedora/RHEL Linux system** with **public internet access** and a **purchased domain** (dastern.site).
:::

---

## 🎯 Your Deployment Setup

| Component | Value |
|-----------|-------|
| **Local Machine IP** | 10.212.42.210 |
| **Public IP** | 117.20.116.46 |
| **Domain** | payment.dastern.site |
| **Email (SSL)** | dastern.healthcare@gmail.com |
| **App Port** | 3002 (internal) |
| **Public Ports** | 80, 443 (Nginx) |

---

## 📋 Prerequisites Checklist

- [x] **Public IP assigned**: 117.20.116.46
- [ ] **Domain purchased**: dastern.site
- [ ] **Router/Firewall**: Port forwarding configured (80→80, 443→443 to 10.212.42.210)
- [ ] **ISP**: Doesn't block ports 80/443
- [ ] **DNS A Record**: Set to 117.20.116.46

---

## 🚀 Deployment Steps

### Step 1: Install Prerequisites

```bash
sudo bash /home/rayu/das-tern/bakong_payment/install-prerequisites.sh
```

**This installs:**
- Docker & Docker Compose
- Nginx (web server + reverse proxy)
- Certbot (Let's Encrypt client)

### Step 2: Make scripts executable

```bash
chmod +x /home/rayu/das-tern/bakong_payment/{deploy.sh,install-prerequisites.sh}
```

### Step 3: Update DNS Records

**Login to your domain registrar** (where you bought dastern.site):

1. Find the DNS management panel
2. Create/Update an **A record**:
   - **Name**: `payment` (or `payment.dastern.site` depending on registrar)
   - **Type**: A
   - **Value**: `117.20.116.46`
   - **TTL**: 300 (or lowest available)

3. Save changes
4. **Wait 5-15 minutes** for DNS propagation (or up to 24 hours)

**Verify DNS is working:**
```bash
dig payment.dastern.site
# Should eventually show: 117.20.116.46
```

### Step 4: Configure Router Port Forwarding

**On your router's admin panel:**

- **Forward Port 80** (HTTP):
  - External Port: 80
  - Internal IP: 10.212.42.210
  - Internal Port: 80
  - Protocol: TCP

- **Forward Port 443** (HTTPS):
  - External Port: 443
  - Internal IP: 10.212.42.210
  - Internal Port: 443
  - Protocol: TCP

**Test port forwarding is working:**
```bash
# From outside your network (or use a port checker online)
curl http://117.20.116.46/api/health
# Should show connection refused initially (before deployment)
```

### Step 5: Run Full Deployment

```bash
sudo bash /home/rayu/das-tern/bakong_payment/deploy.sh
```

The script will:
1. ✓ Verify prerequisites
2. ✓ Create directories
3. ✓ Verify DNS
4. ✓ Stop existing services
5. ✓ Build Docker images
6. ✓ Configure Nginx
7. ✓ Request SSL certificate from Let's Encrypt
8. ✓ Start all services
9. ✓ Verify deployment

**Expected output (success):**
```
========================================================================
                    DEPLOYMENT COMPLETE
========================================================================

Application URL: https://payment.dastern.site
Public IP: 117.20.116.46

Next steps:
  1. Verify DNS A record points to: 117.20.116.46
  2. Configure router port forwarding (80→80, 443→443) to: 10.212.42.210
  3. SSL auto-renewal: certbot renew (runs daily via cron)
```

---

## ✅ Verification

### Test Locally
```bash
# Test via localhost
curl http://localhost:3002/api/health
curl https://localhost/api/health -k

# Test via domain (only after DNS propagation + port forwarding)
curl https://payment.dastern.site/api/health
```

### View Docker Containers
```bash
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml ps
```

### View Application Logs
```bash
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml logs -f app
```

### Check SSL Certificate
```bash
sudo openssl x509 -in /etc/letsencrypt/live/payment.dastern.site/fullchain.pem -text -noout
```

---

## 📊 Service Status Commands

### Nginx
```bash
sudo systemctl status nginx
sudo systemctl reload nginx  # Apply config changes
sudo systemctl restart nginx # Full restart
```

### Docker
```bash
# View all containers
docker ps -a

# View specific service
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml ps

# View container logs
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml logs app
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml logs postgres
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml logs redis
```

### Certbot (SSL)
```bash
# Check certificate status
sudo certbot certificates

# Test auto-renewal (dry run)
sudo certbot renew --dry-run

# Manual renewal
sudo certbot renew
```

---

## 🔧 Troubleshooting

### Issue: "DNS not resolving"
**Solution:**
- Verify DNS A record is set correctly in your registrar
- Wait longer for propagation (up to 24 hours)
- Clear DNS cache: `sudo systemctl restart systemd-resolved`

### Issue: "Port forwarding not working"
**Solution:**
- Verify router port forwarding rules are configured correctly
- Check your ISP allows ports 80/443 (some residential ISPs block them)
- Test with: `sudo netstat -tlnp | grep -E ":(80|443)"`
- If ports not listening, Nginx/Docker may not have started properly

### Issue: "Certbot fails with port error"
**Solution:**
- Ensure port 80 is accessible: `sudo netstat -tlnp | grep :80`
- Nginx must be running: `sudo systemctl status nginx`
- Verify no iptables redirects: `sudo iptables -t nat -L -n`

### Issue: "SSL certificate error in browser"
**Solution:**
- Wait for certificate to be issued (1-5 minutes after deployment)
- Clear browser SSL cache and try again
- Check certificate: `sudo certbot certificates`

### Issue: "Application not starting"
**Solution:**
```bash
# View application logs
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml logs app

# Check environment variables in .env file
cat /home/rayu/das-tern/bakong_payment/.env

# Verify database connection
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml exec postgres pg_isready
```

---

## 🔄 Maintenance

### Daily Auto-Renewal of SSL Certificates
Certbot automatically renews certificates 30 days before expiration via cron job. Verify:

```bash
sudo systemctl status certbot.timer
# or
sudo crontab -l | grep certbot
```

### Update Docker Images
```bash
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml pull
docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml up -d
```

### View Nginx Logs
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Clean Up Old Data
```bash
# View disk usage
docker system df

# Remove unused images
docker system prune -a

# Remove volumes (WARNING: deletes data)
docker volume prune
```

---

## 📝 File Locations

| File | Purpose |
|------|---------|
| `/home/rayu/das-tern/bakong_payment/docker-compose.prod.yml` | Production Docker Compose config |
| `/etc/nginx/sites-available/payment.dastern.site` | Nginx configuration |
| `/etc/letsencrypt/live/payment.dastern.site/` | SSL certificates |
| `/var/log/bakong_payment/` | Application logs |
| `/var/lib/docker/volumes/bakong_payment_*/` | Docker volume data |

---

## 🆘 Support

If deployment fails, check:

1. **Full deployment log**:
   ```bash
   sudo bash /home/rayu/das-tern/bakong_payment/deploy.sh 2>&1 | tee deployment.log
   ```

2. **Component logs**:
   ```bash
   # Docker
   docker-compose -f /home/rayu/das-tern/bakong_payment/docker-compose.prod.yml logs

   # Nginx
   sudo journalctl -u nginx -n 50

   # Certbot
   sudo tail -f /var/log/letsencrypt/letsencrypt.log
   ```

3. **Network diagnostics**:
   ```bash
   # Check if ports are listening
   sudo netstat -tlnp | grep -E "(nginx|docker|:80|:443)"

   # Check firewall
   sudo firewall-cmd --list-all
   ```

---

**Deployment complete!** Your bakong_payment service is now publicly accessible.
