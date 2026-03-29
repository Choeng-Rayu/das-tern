# Das Tern Production Deployment Guide

**Complete VPS Deployment with Docker & Nginx**

| Item | Value |
|------|-------|
| VPS IP | `167.71.194.68` |
| Domain | `dastern.site` |
| Public Endpoint | `https://api.dastern.site` |
| OS | Ubuntu 22.04+ |

---

## Table of Contents

1. [Domain Configuration on Namecheap](#1-domain-configuration-on-namecheap)
2. [VPS Prerequisites](#2-vps-prerequisites)
3. [Clone and Configure Project](#3-clone-and-configure-project)
4. [SSL Certificate Setup (BEFORE Docker)](#4-ssl-certificate-setup-before-docker)
5. [Create Required Databases](#5-create-required-databases)
6. [Docker Deployment Commands](#6-docker-deployment-commands)
7. [Database Migrations](#7-database-migrations)
8. [Post-Deployment Verification](#8-post-deployment-verification)
9. [Maintenance Commands](#9-maintenance-commands)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Domain Configuration on Namecheap

### Step 1: Log into Namecheap Account

1. Open your web browser and navigate to [https://www.namecheap.com](https://www.namecheap.com)
2. Click the **SIGN IN** button in the top-right corner of the page
3. Enter your Namecheap username/email and password
4. Click **SIGN IN** to access your account dashboard

### Step 2: Navigate to Domain List

1. After logging in, you'll see your Namecheap Dashboard
2. In the left sidebar menu, click on **Domain List**
   - Alternatively, hover over **Account** in the top menu and click **Domain List**
3. You'll see a list of all domains registered under your account

### Step 3: Access Domain Management

1. Find `dastern.site` in your domain list
2. Click the **MANAGE** button on the right side of the domain row
3. This opens the domain management page with multiple tabs

### Step 4: Navigate to Advanced DNS

1. On the domain management page, you'll see several tabs: **Domain**, **Sharing & Transfer**, **Security**, **Advanced DNS**, etc.
2. Click on the **Advanced DNS** tab
3. You'll see the "Host Records" section where DNS records are configured

### Step 5: Add DNS A Records

In the "Host Records" section, you need to add the following records:

**Record 1: API Subdomain (Required)**
| Field | Value |
|-------|-------|
| Type | A Record |
| Host | `api` |
| Value | `167.71.194.68` |
| TTL | Automatic |

**Record 2: Root Domain (Optional - for future use)**
| Field | Value |
|-------|-------|
| Type | A Record |
| Host | `@` |
| Value | `167.71.194.68` |
| TTL | Automatic |

**To add each record:**
1. Click the **ADD NEW RECORD** button
2. In the **Type** dropdown, select **A Record**
3. In the **Host** field:
   - Enter `api` for the API subdomain
   - Enter `@` for the root domain
4. In the **Value** field, enter the VPS IP: `167.71.194.68`
5. Leave **TTL** as **Automatic** (or select 30 min for faster propagation during testing)
6. Click the **green checkmark** to save the record

### Step 6: Verify Your DNS Configuration

After adding the records, your Host Records table should look like this:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A Record | api | 167.71.194.68 | Automatic |
| A Record | @ | 167.71.194.68 | Automatic |

**Note:** You may see other default records like:
- CNAME Record with Host `www` - this is fine to keep
- URL Redirect Record - this is fine to keep or remove
- Parking page records - remove these if present

### Step 7: Verify DNS Propagation

DNS changes can take **up to 48 hours** to propagate globally, but usually complete within **15-30 minutes**.

**Method 1: Using dig command (Linux/Mac)**
```bash
# Check A record for api subdomain
dig api.dastern.site +short

# Expected output:
167.71.194.68

# More detailed output
dig api.dastern.site A

# Expected output includes:
# ;; ANSWER SECTION:
# api.dastern.site.    300    IN    A    167.71.194.68
```

**Method 2: Using nslookup (Windows/Linux/Mac)**
```bash
nslookup api.dastern.site

# Expected output:
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   api.dastern.site
Address: 167.71.194.68
```

**Method 3: Using nslookup with specific DNS server**
```bash
# Query Google's DNS directly
nslookup api.dastern.site 8.8.8.8

# Query Cloudflare's DNS
nslookup api.dastern.site 1.1.1.1
```

**Method 4: Online DNS Propagation Checkers**
- [https://dnschecker.org](https://dnschecker.org) - Check propagation across multiple global servers
- [https://www.whatsmydns.net](https://www.whatsmydns.net) - Visual propagation map

Enter `api.dastern.site` and select **A** record type to check propagation status worldwide.

### DNS Propagation Timeline

| Time | Expected Status |
|------|-----------------|
| 0-5 minutes | Changes saved in Namecheap |
| 5-15 minutes | Propagating to major DNS servers |
| 15-30 minutes | Most global DNS servers updated |
| 30-60 minutes | Nearly complete propagation |
| Up to 48 hours | Full global propagation (rare cases) |

> **Important:** Wait until DNS propagation is complete before proceeding to SSL certificate setup. You can verify by running `dig api.dastern.site +short` - it should return `167.71.194.68`.

---

## 2. VPS Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS or 24.04 LTS |
| RAM | 4 GB | 8 GB |
| CPU | 2 cores | 4 cores |
| Storage | 40 GB SSD | 80 GB SSD |
| Network | Public IPv4 | Public IPv4 |

### Step 1: Connect to VPS

```bash
ssh root@167.71.194.68

# Or with a specific user
ssh rayu@167.71.194.68
```

### Step 2: Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 3: Install Docker

```bash
# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Verify installation
docker --version
```

**Expected output:**
```
Docker version 24.0.7, build afdd53b
```

### Step 4: Install Docker Compose

```bash
# Install Docker Compose plugin (recommended method)
sudo apt install -y docker-compose-plugin

# Verify installation
docker compose version
```

**Expected output:**
```
Docker Compose version v2.24.0
```

### Step 5: Configure Docker Permissions (Optional)

To run Docker commands without `sudo`:

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Apply group changes (or logout and login again)
newgrp docker

# Verify
docker ps
```

### Step 6: Configure Firewall (UFW)

```bash
# Check if UFW is installed
which ufw || sudo apt install -y ufw

# Allow SSH first (IMPORTANT: prevents lockout)
sudo ufw allow 22/tcp

# Allow HTTP (for Let's Encrypt and redirects)
sudo ufw allow 80/tcp

# Allow HTTPS (main traffic)
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Verify rules
sudo ufw status verbose
```

**Expected output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
```

### Step 7: Create Project Directory Structure

```bash
# Create project directory
sudo mkdir -p /home/rayu/das-tern

# Set ownership
sudo chown -R $USER:$USER /home/rayu/das-tern

# Create certbot webroot directory
sudo mkdir -p /var/www/certbot

# Verify
ls -la /home/rayu/
```

---

## 3. Clone and Configure Project

### Step 1: Clone Repository

```bash
cd /home/rayu/das-tern

# Clone the repository
git clone <your-repository-url> .

# If already cloned, pull latest
git pull origin main

# Verify files
ls -la
```

### Step 2: Create Environment Files

You need to create 5 `.env` files:

| File Path | Purpose |
|-----------|---------|
| `.env` | Root infrastructure (PostgreSQL, Redis, RabbitMQ, MinIO) |
| `backend_nestjs/.env` | NestJS backend service |
| `ai-llm-service/.env` | AI/LLM service |
| `ocr/.env` | OCR service |
| `bakong_payment/.env` | Bakong payment service |

#### Root Infrastructure `.env`

```bash
nano /home/rayu/das-tern/.env
```

```env
# ===========================================
# INFRASTRUCTURE ENVIRONMENT VARIABLES
# ===========================================

# PostgreSQL
POSTGRES_DB=dastern
POSTGRES_USER=dastern_user
POSTGRES_PASSWORD=your_strong_postgres_password_here

# Redis
REDIS_PASSWORD=your_strong_redis_password_here

# RabbitMQ
RABBITMQ_USER=dastern_user
RABBITMQ_PASSWORD=your_strong_rabbitmq_password_here

# MinIO (S3-compatible storage)
MINIO_ROOT_USER=dastern_admin
MINIO_ROOT_PASSWORD=your_strong_minio_password_here
MINIO_BUCKET_NAME=dastern-uploads

# Bakong Payment Shared Secrets
BAKONG_MERCHANT_ID=your_bakong_merchant_id
BAKONG_PHONE_NUMBER=+855xxxxxxxxx
BAKONG_DEVELOPER_TOKEN=your_bakong_developer_token
BAKONG_API_URL=https://api-bakong.nbc.gov.kh
DEFAULT_MERCHANT_NAME=Das Tern
DEFAULT_MERCHANT_CITY=Phnom Penh
MAIN_BACKEND_API_KEY=your_secure_api_key_32_chars_min
WEBHOOK_SECRET=your_webhook_secret_here
ENCRYPTION_KEY=12345678901234567890123456789012
PREMIUM_PRICE=0.50
FAMILY_PREMIUM_PRICE=1.00
```

#### Backend NestJS `.env`

```bash
nano /home/rayu/das-tern/backend_nestjs/.env
```

```env
# ===========================================
# BACKEND SERVICE ENVIRONMENT VARIABLES
# ===========================================

# Server Configuration
NODE_ENV=production
PORT=3001
API_PREFIX=api/v1

# Database (IMPORTANT: Use 'postgres' as host, not 'localhost')
# URL-encode special characters: @ = %40, # = %23, ! = %21, $ = %24
DATABASE_URL=postgresql://dastern_user:your_password@postgres:5432/dastern?schema=public
DATABASE_READ_URL=postgresql://dastern_user:your_password@postgres:5432/dastern?schema=public

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here
REDIS_DB=0

# JWT Authentication (generate with: openssl rand -hex 32)
JWT_SECRET=your_64_character_jwt_secret_here_generated_with_openssl
JWT_REFRESH_SECRET=your_64_character_refresh_secret_here_different_from_above
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Encryption (MUST be EXACTLY 32 characters)
ENCRYPTION_KEY=12345678901234567890123456789012

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_CALLBACK_URL=https://api.dastern.site/api/v1/auth/google/callback

# Telegram Bot
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
TELEGRAM_BOT_CLIENT_ID=your_telegram_bot_id
TELEGRAM_BOT_USERNAME=your_bot_username_without_at
TELEGRAM_OAUTH_REDIRECT_URI=https://api.dastern.site/api/v1/auth/telegram/callback

# MinIO/S3 Storage
AWS_ACCESS_KEY_ID=dastern_admin
AWS_SECRET_ACCESS_KEY=your_minio_password_here
AWS_S3_BUCKET=dastern-uploads
AWS_S3_ENDPOINT=http://minio:9000

# Internal Services (Docker service names)
OCR_SERVICE_URL=http://ocr:8000
AI_SERVICE_URL=http://ai-llm:8001
BAKONG_SERVICE_URL=http://bakong-payment:3002

# Bakong Integration
BAKONG_API_KEY=your_secure_api_key_32_chars_min
BAKONG_WEBHOOK_SECRET=your_webhook_secret_here

# CORS
ALLOWED_ORIGINS=https://api.dastern.site,https://dastern.site

# Timezone
TZ=Asia/Phnom_Penh

# Optional: Email (SendGrid)
# SENDGRID_API_KEY=your_sendgrid_api_key
# SENDGRID_FROM_EMAIL=noreply@dastern.site
# SENDGRID_FROM_NAME=Das Tern

# Optional: SMS (Twilio)
# TWILIO_ACCOUNT_SID=your_twilio_sid
# TWILIO_AUTH_TOKEN=your_twilio_token
# TWILIO_PHONE_NUMBER=+1234567890
```

#### AI-LLM Service `.env`

```bash
nano /home/rayu/das-tern/ai-llm-service/.env
```

```env
# ===========================================
# AI-LLM SERVICE ENVIRONMENT VARIABLES
# ===========================================

# LLM Provider: 'ollama' or 'openrouter'
LLM_PROVIDER=openrouter

# OpenRouter Configuration (if LLM_PROVIDER=openrouter)
OPENROUTER_API_KEY=sk-or-v1-your_openrouter_api_key_here
OPENROUTER_MODEL=google/gemma-3-4b-it:free
OPENROUTER_TIMEOUT=60

# Ollama Configuration (if LLM_PROVIDER=ollama)
# OLLAMA_BASE_URL=http://localhost:11434
# OLLAMA_MODEL=llama3.2:3b
# OLLAMA_FAST_MODEL=llama3.2:3b
# OLLAMA_TIMEOUT=60

# Logging
LOG_LEVEL=INFO
DEBUG=false
TZ=Asia/Phnom_Penh
```

#### OCR Service `.env`

```bash
nano /home/rayu/das-tern/ocr/.env
```

```env
# ===========================================
# OCR SERVICE ENVIRONMENT VARIABLES
# ===========================================

# Server
HOST=0.0.0.0
PORT=8000

# OCR Model Configuration
OCR_MODEL=kiri-ocr
HF_TOKEN=hf_your_huggingface_token_here
KIRI_DEVICE=cpu
MODEL_CACHE_DIR=./models

# File Handling
MAX_UPLOAD_SIZE_MB=10
MAX_IMAGE_DIMENSION=4000

# Timezone
TZ=Asia/Phnom_Penh
```

#### Bakong Payment `.env`

```bash
nano /home/rayu/das-tern/bakong_payment/.env
```

```env
# ===========================================
# BAKONG PAYMENT SERVICE ENVIRONMENT VARIABLES
# ===========================================

# Server
NODE_ENV=production
PORT=3002

# Database (Uses shared postgres with separate database)
DATABASE_URL=postgresql://dastern_user:your_password@postgres:5432/bakong_payment?schema=public

# Redis (shared)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password_here

# Bakong API Credentials
BAKONG_MERCHANT_ID=your_bakong_merchant_id
BAKONG_PHONE_NUMBER=+855xxxxxxxxx
BAKONG_DEVELOPER_TOKEN=your_bakong_developer_token
BAKONG_API_URL=https://api-bakong.nbc.gov.kh

# Merchant Information
DEFAULT_MERCHANT_NAME=Das Tern
DEFAULT_MERCHANT_CITY=Phnom Penh

# Pricing (USD)
PREMIUM_PRICE=0.50
FAMILY_PREMIUM_PRICE=1.00

# Backend Integration
MAIN_BACKEND_API_KEY=your_secure_api_key_32_chars_min
MAIN_BACKEND_WEBHOOK_URL=http://backend:3001/api/v1/webhooks/bakong
WEBHOOK_SECRET=your_webhook_secret_here

# Encryption (MUST be EXACTLY 32 characters)
ENCRYPTION_KEY=12345678901234567890123456789012

# CORS
CORS_ORIGIN=https://api.dastern.site,https://dastern.site

# Timezone
TZ=Asia/Phnom_Penh
```

### Step 3: Generate Secure Keys

```bash
# Generate 32-character encryption key
openssl rand -hex 16
# Output example: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

# Generate 64-character JWT secret
openssl rand -hex 32
# Output example: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2

# URL-encode password with special characters
python3 -c "import urllib.parse; print(urllib.parse.quote('P@ssw0rd!#$', safe=''))"
# Output: P%40ssw0rd%21%23%24
```

> **Reference:** See [PRODUCTION_ENV_VARIABLES.md](./PRODUCTION_ENV_VARIABLES.md) for complete documentation of all environment variables.

---

## 4. SSL Certificate Setup (BEFORE Docker)

> **CRITICAL:** SSL certificates MUST be generated BEFORE starting Docker containers. The Nginx container expects certificates to exist at `/etc/letsencrypt/`.

### Step 1: Install Certbot on VPS

```bash
sudo apt install -y certbot
```

**Verify installation:**
```bash
certbot --version
# Expected: certbot 2.x.x
```

### Step 2: Create Certbot Webroot Directory

```bash
sudo mkdir -p /var/www/certbot
```

### Step 3: Verify DNS Points to VPS

Before generating certificates, confirm DNS is properly configured:

```bash
dig api.dastern.site +short
# MUST return: 167.71.194.68
```

If DNS is not yet propagated, wait and check again later.

### Step 4: Stop Any Services Using Port 80

```bash
# Check what's using port 80
sudo lsof -i :80

# Stop nginx if running on host
sudo systemctl stop nginx 2>/dev/null || true

# Stop any Docker containers using port 80
docker stop dastern-nginx 2>/dev/null || true
```

### Step 5: Generate SSL Certificate (Standalone Mode)

```bash
sudo certbot certonly --standalone -d api.dastern.site
```

**Interactive prompts:**
1. **Enter email address:** Enter your email for renewal notifications
2. **Terms of Service:** Press `A` to agree
3. **Share email with EFF:** Press `Y` or `N` (your choice)

**Expected output:**
```
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for api.dastern.site

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/api.dastern.site/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/api.dastern.site/privkey.pem
This certificate expires on 2026-06-26.
These files will be updated when the certificate renews.

NEXT STEPS:
- The certificate will need to be renewed before it expires.
```

### Step 6: Verify Certificate Files Exist

```bash
sudo ls -la /etc/letsencrypt/live/api.dastern.site/
```

**Expected output:**
```
total 12
drwxr-xr-x 2 root root 4096 Mar 28 10:00 .
drwx------ 3 root root 4096 Mar 28 10:00 ..
lrwxrwxrwx 1 root root   45 Mar 28 10:00 cert.pem -> ../../archive/api.dastern.site/cert1.pem
lrwxrwxrwx 1 root root   46 Mar 28 10:00 chain.pem -> ../../archive/api.dastern.site/chain1.pem
lrwxrwxrwx 1 root root   50 Mar 28 10:00 fullchain.pem -> ../../archive/api.dastern.site/fullchain1.pem
lrwxrwxrwx 1 root root   48 Mar 28 10:00 privkey.pem -> ../../archive/api.dastern.site/privkey1.pem
-rw-r--r-- 1 root root  692 Mar 28 10:00 README
```

**File descriptions:**
| File | Description | Used By |
|------|-------------|---------|
| `fullchain.pem` | Server cert + intermediate certs | Nginx `ssl_certificate` |
| `privkey.pem` | Private key | Nginx `ssl_certificate_key` |
| `chain.pem` | Intermediate certificates only | Nginx `ssl_trusted_certificate` |
| `cert.pem` | Server certificate only | Not commonly used |

### Step 7: Verify Certificate Content

```bash
# Check certificate validity dates
sudo openssl x509 -in /etc/letsencrypt/live/api.dastern.site/fullchain.pem -noout -dates

# Expected output:
notBefore=Mar 28 00:00:00 2026 GMT
notAfter=Jun 26 23:59:59 2026 GMT
```

### Step 8: Set Up Auto-Renewal with Cron

Let's Encrypt certificates expire every 90 days. Set up automatic renewal:

```bash
# Test renewal process (dry run)
sudo certbot renew --dry-run
```

**Expected output:**
```
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/api.dastern.site.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Simulating renewal of an existing certificate for api.dastern.site

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded:
  /etc/letsencrypt/live/api.dastern.site/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

**Create cron job for auto-renewal:**

```bash
# Open crontab editor
sudo crontab -e

# Add this line at the end (runs twice daily at 3:00 AM and 3:00 PM)
0 3,15 * * * certbot renew --quiet --deploy-hook "docker exec dastern-nginx nginx -s reload"
```

**What this cron job does:**
- Runs at 3:00 AM and 3:00 PM daily
- Checks if certificate expires within 30 days
- Renews only if needed
- Reloads Nginx after successful renewal to pick up new certificate

---

## 5. Create Required Databases

The Bakong Payment service requires a separate database named `bakong_payment`. This database must be created manually.

### Step 1: Start Only PostgreSQL Container

```bash
cd /home/rayu/das-tern

# Start only the postgres service
docker compose -f docker-compose.prod.yml up -d postgres
```

**Expected output:**
```
[+] Running 2/2
 ✔ Network das-tern_dastern-network  Created
 ✔ Container dastern-postgres        Started
```

### Step 2: Wait for PostgreSQL to be Healthy

```bash
# Check container status (wait until STATUS shows "healthy")
docker ps --filter name=dastern-postgres --format "table {{.Names}}\t{{.Status}}"
```

**Expected output:**
```
NAMES              STATUS
dastern-postgres   Up 30 seconds (healthy)
```

If it shows "(health: starting)", wait a few more seconds and check again.

**Alternative: Check logs**
```bash
docker logs dastern-postgres

# Look for:
# PostgreSQL init process complete; ready for start up.
# database system is ready to accept connections
```

### Step 3: Create the bakong_payment Database

```bash
# Connect to PostgreSQL container
docker exec -it dastern-postgres psql -U dastern_user -d dastern
```

**You're now in the PostgreSQL shell. Run:**

```sql
-- Create the bakong_payment database
CREATE DATABASE bakong_payment;

-- Verify it was created
\l
```

**Expected output from `\l`:**
```
                                         List of databases
      Name       |    Owner     | Encoding |  Collate   |   Ctype    |       Access privileges
-----------------+--------------+----------+------------+------------+-------------------------------
 bakong_payment  | dastern_user | UTF8     | en_US.utf8 | en_US.utf8 |
 dastern         | dastern_user | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres        | dastern_user | UTF8     | en_US.utf8 | en_US.utf8 |
 template0       | dastern_user | UTF8     | en_US.utf8 | en_US.utf8 | =c/dastern_user              +
                 |              |          |            |            | dastern_user=CTc/dastern_user
 template1       | dastern_user | UTF8     | en_US.utf8 | en_US.utf8 | =c/dastern_user              +
                 |              |          |            |            | dastern_user=CTc/dastern_user
(5 rows)
```

**Exit PostgreSQL shell:**
```sql
\q
```

### Step 4: Verify Database Access

```bash
# Test connection to the new database
docker exec -it dastern-postgres psql -U dastern_user -d bakong_payment -c "SELECT 1 as test;"
```

**Expected output:**
```
 test
------
    1
(1 row)
```

---

## 6. Docker Deployment Commands

### Step 1: Build and Start All Services

```bash
cd /home/rayu/das-tern

# Build images and start all services in detached mode
docker compose -f docker-compose.prod.yml up -d --build
```

**Expected output:**
```
[+] Building 120.5s (45/45) FINISHED
 => [backend internal] load build definition from Dockerfile
 => [ocr internal] load build definition from Dockerfile
 => [ai-llm internal] load build definition from Dockerfile
 => [bakong-payment internal] load build definition from Dockerfile
...
[+] Running 9/9
 ✔ Network das-tern_dastern-network    Created
 ✔ Volume "das-tern_postgres_data"     Created
 ✔ Volume "das-tern_redis_data"        Created
 ✔ Volume "das-tern_rabbitmq_data"     Created
 ✔ Volume "das-tern_minio_data"        Created
 ✔ Container dastern-postgres          Started
 ✔ Container dastern-redis             Started
 ✔ Container dastern-rabbitmq          Started
 ✔ Container dastern-minio             Started
 ✔ Container dastern-backend           Started
 ✔ Container dastern-ocr               Started
 ✔ Container dastern-ai-llm            Started
 ✔ Container dastern-bakong-payment    Started
 ✔ Container dastern-nginx             Started
```

### Step 2: Check Container Status

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected output (all should show "Up" and eventually "healthy"):**
```
NAMES                   STATUS                    PORTS
dastern-nginx           Up 2 minutes (healthy)    0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
dastern-backend         Up 2 minutes (healthy)
dastern-ocr             Up 2 minutes (healthy)
dastern-ai-llm          Up 2 minutes (healthy)
dastern-bakong-payment  Up 2 minutes (healthy)
dastern-postgres        Up 3 minutes (healthy)
dastern-redis           Up 3 minutes (healthy)
dastern-rabbitmq        Up 3 minutes (healthy)
dastern-minio           Up 3 minutes (healthy)
```

**Note:** Health checks have start periods, so containers may show "(health: starting)" for the first 60-120 seconds.

### Step 3: View Logs for Each Service

```bash
# View all logs (combined)
docker compose -f docker-compose.prod.yml logs

# View specific service logs
docker logs dastern-backend
docker logs dastern-nginx
docker logs dastern-postgres
docker logs dastern-ocr
docker logs dastern-ai-llm
docker logs dastern-bakong-payment

# Follow logs in real-time (Ctrl+C to exit)
docker logs -f dastern-backend

# View last 100 lines only
docker logs --tail 100 dastern-backend

# View logs with timestamps
docker logs -t dastern-backend
```

### Step 4: Troubleshooting Startup Issues

**If a container keeps restarting:**

```bash
# Check exit code
docker inspect dastern-backend --format='{{.State.ExitCode}}'
# Exit codes: 0=success, 1=app error, 137=OOM killed, 143=SIGTERM

# View detailed logs
docker logs dastern-backend --tail 200
```

**If containers can't connect to database:**

```bash
# Verify postgres is healthy
docker exec -it dastern-postgres pg_isready -U dastern_user

# Test connection from backend
docker exec -it dastern-backend nc -zv postgres 5432
# Expected: postgres (172.x.x.x:5432) open
```

**If Nginx fails to start:**

```bash
# Usually SSL certificate issues
docker logs dastern-nginx

# Verify certificates are mounted
docker exec dastern-nginx ls -la /etc/letsencrypt/live/api.dastern.site/

# Test nginx configuration
docker exec dastern-nginx nginx -t
```

**If services can't communicate:**

```bash
# Check network
docker network inspect das-tern_dastern-network

# Test from one container to another
docker exec -it dastern-backend ping -c 3 postgres
docker exec -it dastern-backend ping -c 3 redis
docker exec -it dastern-backend ping -c 3 ocr
```

---

## 7. Database Migrations

After all containers are running, apply database migrations using Prisma.

### Step 1: Run Backend Prisma Migrations

```bash
docker exec -it dastern-backend npx prisma migrate deploy
```

**Expected output:**
```
Environment variables loaded from .env
Prisma schema loaded from prisma/schema.prisma
Datasource "db": PostgreSQL database "dastern", schema "public" at "postgres:5432"

15 migrations found in prisma/migrations

Applying migration `20240101000000_init`
Applying migration `20240115000000_add_users`
Applying migration `20240201000000_add_subscriptions`
...

All migrations have been successfully applied.
```

### Step 2: Run Bakong Payment Prisma Migrations

```bash
docker exec -it dastern-bakong-payment npx prisma migrate deploy
```

**Expected output:**
```
Environment variables loaded from .env
Prisma schema loaded from prisma/schema.prisma
Datasource "db": PostgreSQL database "bakong_payment", schema "public" at "postgres:5432"

5 migrations found in prisma/migrations

Applying migration `20240301000000_init_payment`
Applying migration `20240315000000_add_transactions`
...

All migrations have been successfully applied.
```

### Step 3: Verify Migrations (Optional)

```bash
# Check backend database tables
docker exec -it dastern-postgres psql -U dastern_user -d dastern -c "\dt"

# Check bakong_payment database tables
docker exec -it dastern-postgres psql -U dastern_user -d bakong_payment -c "\dt"
```

### Step 4: Seed Initial Data (If Available)

```bash
# Only if your project has seed scripts
docker exec -it dastern-backend npx prisma db seed
```

---

## 8. Post-Deployment Verification

### Step 1: Test Health Endpoints

```bash
# Test Nginx health endpoint
curl -s https://api.dastern.site/health
# Expected: {"status":"ok"}

# Test API v1 health endpoint
curl -s https://api.dastern.site/api/v1/health
# Expected: {"status":"ok","timestamp":"2026-03-28T12:00:00.000Z","uptime":123.456}

# Test with verbose output (see headers)
curl -v https://api.dastern.site/health
```

**Expected verbose output:**
```
*   Trying 167.71.194.68:443...
* Connected to api.dastern.site (167.71.194.68) port 443 (#0)
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* Server certificate:
*  subject: CN=api.dastern.site
*  start date: Mar 28 00:00:00 2026 GMT
*  expire date: Jun 26 23:59:59 2026 GMT
*  issuer: C=US; O=Let's Encrypt; CN=R3
...
< HTTP/2 200
< content-type: application/json
< strict-transport-security: max-age=31536000; includeSubDomains
...
{"status":"ok"}
```

### Step 2: Verify SSL Certificate

**Using openssl:**
```bash
openssl s_client -connect api.dastern.site:443 -servername api.dastern.site </dev/null 2>/dev/null | openssl x509 -noout -dates -subject -issuer
```

**Expected output:**
```
notBefore=Mar 28 00:00:00 2026 GMT
notAfter=Jun 26 23:59:59 2026 GMT
subject=CN = api.dastern.site
issuer=C = US, O = Let's Encrypt, CN = R3
```

**Check SSL grade online:**
- Visit [https://www.ssllabs.com/ssltest/](https://www.ssllabs.com/ssltest/)
- Enter `api.dastern.site`
- Expected grade: **A** or **A+**

### Step 3: Check Inter-Service Communication

```bash
# Backend → OCR
docker exec -it dastern-backend curl -s http://ocr:8000/api/v1/health
# Expected: {"status":"healthy"} or similar

# Backend → AI-LLM
docker exec -it dastern-backend curl -s http://ai-llm:8001/
# Expected: {"message":"AI-LLM Service Running"}

# Backend → Bakong Payment
docker exec -it dastern-backend curl -s http://bakong-payment:3002/health
# Expected: {"status":"ok"}

# Backend → PostgreSQL
docker exec -it dastern-backend nc -zv postgres 5432
# Expected: postgres (172.x.x.x:5432) open

# Backend → Redis
docker exec -it dastern-backend nc -zv redis 6379
# Expected: redis (172.x.x.x:6379) open

# Backend → MinIO
docker exec -it dastern-backend curl -s http://minio:9000/minio/health/live
# Expected: (empty response with 200 status)
```

### Step 4: Test Rate Limiting

```bash
# Send 50 rapid requests to trigger rate limiting
for i in {1..50}; do
  echo -n "Request $i: "
  curl -s -o /dev/null -w "%{http_code}\n" https://api.dastern.site/health
done
```

**Expected output:**
```
Request 1: 200
Request 2: 200
...
Request 40: 200
Request 41: 429
Request 42: 429
...
```

Requests 1-40 return `200`, then rate limiting kicks in with `429 Too Many Requests`.

### Step 5: Full System Status Check

```bash
echo "=========================================="
echo "       DAS TERN DEPLOYMENT STATUS"
echo "=========================================="
echo ""
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep dastern
echo ""
echo "=== Health Endpoints ==="
echo "Nginx health:    $(curl -s -o /dev/null -w '%{http_code}' https://api.dastern.site/health)"
echo "API v1 health:   $(curl -s -o /dev/null -w '%{http_code}' https://api.dastern.site/api/v1/health)"
echo ""
echo "=== SSL Certificate ==="
echo "$(openssl s_client -connect api.dastern.site:443 -servername api.dastern.site </dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)"
echo ""
echo "=== Disk Usage ==="
df -h / | tail -1
echo ""
echo "=== Memory Usage ==="
free -h | head -2
echo ""
echo "=========================================="
echo "         DEPLOYMENT COMPLETE!"
echo "=========================================="
```

---

## 9. Maintenance Commands

### View Logs

```bash
# View all container logs
docker compose -f docker-compose.prod.yml logs

# View specific service logs
docker logs dastern-backend
docker logs dastern-nginx
docker logs dastern-postgres
docker logs dastern-ocr
docker logs dastern-ai-llm
docker logs dastern-bakong-payment

# Follow logs in real-time (Ctrl+C to exit)
docker logs -f dastern-backend

# View last N lines
docker logs --tail 100 dastern-backend

# View logs with timestamps
docker logs -t dastern-backend

# Combine options
docker logs -f --tail 50 -t dastern-backend
```

### Restart Services

```bash
# Restart all services
docker compose -f docker-compose.prod.yml restart

# Restart specific service
docker compose -f docker-compose.prod.yml restart backend
docker compose -f docker-compose.prod.yml restart nginx

# Stop all services
docker compose -f docker-compose.prod.yml stop

# Start all services (without rebuilding)
docker compose -f docker-compose.prod.yml start

# Stop and remove containers (keeps volumes)
docker compose -f docker-compose.prod.yml down

# Stop and remove everything including volumes (DATA LOSS!)
docker compose -f docker-compose.prod.yml down -v
```

### Update and Redeploy

```bash
# Navigate to project directory
cd /home/rayu/das-tern

# Pull latest code from repository
git pull origin main

# Rebuild and restart all services
docker compose -f docker-compose.prod.yml up -d --build

# Rebuild only a specific service
docker compose -f docker-compose.prod.yml up -d --build backend

# Run migrations after code update
docker exec -it dastern-backend npx prisma migrate deploy
docker exec -it dastern-bakong-payment npx prisma migrate deploy
```

### Database Backup Commands

**Manual backup:**
```bash
# Backup main database
docker exec dastern-postgres pg_dump -U dastern_user dastern > backup_dastern_$(date +%Y%m%d_%H%M%S).sql

# Backup bakong_payment database
docker exec dastern-postgres pg_dump -U dastern_user bakong_payment > backup_bakong_$(date +%Y%m%d_%H%M%S).sql

# Backup all databases
docker exec dastern-postgres pg_dumpall -U dastern_user > backup_all_$(date +%Y%m%d_%H%M%S).sql

# Compress backup
gzip backup_dastern_*.sql
```

**Restore from backup:**
```bash
# Restore main database
docker exec -i dastern-postgres psql -U dastern_user dastern < backup_dastern_20260328_120000.sql

# Restore bakong_payment database
docker exec -i dastern-postgres psql -U dastern_user bakong_payment < backup_bakong_20260328_120000.sql

# Restore from compressed backup
gunzip -c backup_dastern_20260328.sql.gz | docker exec -i dastern-postgres psql -U dastern_user dastern
```

**Automated backup script:**

Create `/home/rayu/das-tern/scripts/backup.sh`:
```bash
#!/bin/bash
BACKUP_DIR="/home/rayu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "Starting database backup at $DATE..."

# Backup databases
docker exec dastern-postgres pg_dump -U dastern_user dastern | gzip > "$BACKUP_DIR/dastern_$DATE.sql.gz"
docker exec dastern-postgres pg_dump -U dastern_user bakong_payment | gzip > "$BACKUP_DIR/bakong_$DATE.sql.gz"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
ls -lh $BACKUP_DIR/*.sql.gz | tail -5
```

```bash
# Make executable
chmod +x /home/rayu/das-tern/scripts/backup.sh

# Add to cron (daily at 2 AM)
sudo crontab -e
# Add: 0 2 * * * /home/rayu/das-tern/scripts/backup.sh >> /var/log/backup.log 2>&1
```

### SSL Certificate Renewal

```bash
# Check certificate expiry
sudo certbot certificates

# Manual renewal
sudo certbot renew

# Force renewal (even if not expiring soon)
sudo certbot renew --force-renewal

# Renew and reload Nginx
sudo certbot renew --deploy-hook "docker exec dastern-nginx nginx -s reload"

# Test renewal (dry run)
sudo certbot renew --dry-run
```

### Clean Up Docker Resources

```bash
# Remove unused containers
docker container prune -f

# Remove unused images
docker image prune -f

# Remove ALL unused images (including tagged ones)
docker image prune -a -f

# Remove unused networks
docker network prune -f

# Remove unused volumes (CAUTION: may delete data!)
docker volume prune -f

# Remove all unused resources
docker system prune -f

# View disk usage
docker system df
```

---

## 10. Troubleshooting

### Common Errors and Solutions

#### 1. Container Won't Start / Keeps Restarting

**Symptoms:**
- Container status shows "Restarting"
- Container exits immediately after starting

**Diagnosis:**
```bash
# Check exit code
docker inspect dastern-backend --format='{{.State.ExitCode}}'

# Exit code meanings:
# 0   = Success (normal exit)
# 1   = Application error
# 137 = OOM killed (out of memory)
# 143 = SIGTERM (graceful termination)

# View last 200 lines of logs
docker logs --tail 200 dastern-backend
```

**Solutions:**
- Exit code 1: Check logs for application errors, verify environment variables
- Exit code 137: Increase container memory limits or VPS RAM
- Check for missing dependencies or configuration errors

#### 2. Database Connection Failed

**Symptoms:**
- `Error: getaddrinfo ENOTFOUND postgres`
- `Error: Connection refused`
- `ECONNREFUSED 127.0.0.1:5432`

**Diagnosis:**
```bash
# Check if postgres is running
docker ps | grep postgres

# Check postgres logs
docker logs dastern-postgres

# Test connection from backend
docker exec -it dastern-backend nc -zv postgres 5432
```

**Solutions:**
```bash
# Ensure DATABASE_URL uses 'postgres' (Docker service name), NOT 'localhost'
# Wrong: DATABASE_URL=postgresql://user:pass@localhost:5432/db
# Correct: DATABASE_URL=postgresql://user:pass@postgres:5432/db

# Check password encoding if it contains special characters
# @ = %40, # = %23, ! = %21, $ = %24

# Restart postgres if needed
docker compose -f docker-compose.prod.yml restart postgres

# Wait for healthcheck then restart backend
docker compose -f docker-compose.prod.yml restart backend
```

#### 3. SSL Certificate Issues

**Symptoms:**
- Nginx fails to start
- `nginx: [emerg] cannot load certificate`
- Browser shows "Connection not secure"

**Diagnosis:**
```bash
# Check if certificates exist on host
sudo ls -la /etc/letsencrypt/live/api.dastern.site/

# Check nginx logs
docker logs dastern-nginx

# Verify certificate is mounted in container
docker exec dastern-nginx ls -la /etc/letsencrypt/live/api.dastern.site/
```

**Solutions:**
```bash
# If certificates don't exist, generate them
sudo certbot certonly --standalone -d api.dastern.site

# If certificates exist but Nginx can't read them, check permissions
sudo chmod -R 755 /etc/letsencrypt/live/
sudo chmod -R 755 /etc/letsencrypt/archive/

# Restart Nginx
docker compose -f docker-compose.prod.yml restart nginx
```

#### 4. Network Connectivity Issues

**Symptoms:**
- Services can't communicate with each other
- `Error: connect ECONNREFUSED`
- Ping between containers fails

**Diagnosis:**
```bash
# List networks
docker network ls

# Inspect the dastern network
docker network inspect das-tern_dastern-network

# Check which containers are connected
docker network inspect das-tern_dastern-network | grep -A 5 "Containers"

# Test ping between containers
docker exec -it dastern-backend ping -c 3 postgres
docker exec -it dastern-backend ping -c 3 redis
```

**Solutions:**
```bash
# Reconnect container to network
docker network connect das-tern_dastern-network dastern-backend

# Restart all services to recreate network
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# If network is corrupted, recreate it
docker compose -f docker-compose.prod.yml down
docker network rm das-tern_dastern-network
docker compose -f docker-compose.prod.yml up -d
```

#### 5. 502 Bad Gateway

**Symptoms:**
- `curl https://api.dastern.site` returns 502
- Nginx is running but backend is not responding

**Diagnosis:**
```bash
# Check if backend is running and healthy
docker ps | grep backend

# Test Nginx → Backend connection
docker exec dastern-nginx curl -s http://backend:3001/health

# Check Nginx configuration
docker exec dastern-nginx nginx -t
```

**Solutions:**
```bash
# Restart backend
docker compose -f docker-compose.prod.yml restart backend

# Check backend logs for errors
docker logs dastern-backend --tail 100

# Reload Nginx configuration
docker exec dastern-nginx nginx -s reload
```

#### 6. Rate Limiting (429 Too Many Requests)

**Symptoms:**
- Getting 429 responses for legitimate requests
- API becoming unresponsive during normal usage

**Diagnosis:**
```bash
# Check current rate limit configuration
docker exec dastern-nginx cat /etc/nginx/nginx.conf | grep -A 3 "limit_req"
```

**Solutions:**
- Rate limit is set to 20 requests/second with burst of 40
- For legitimate high-traffic, adjust in `nginx/nginx.conf`:
  ```nginx
  limit_req_zone $binary_remote_addr zone=api_limit:10m rate=50r/s;  # Increase rate
  limit_req zone=api_limit burst=100 nodelay;  # Increase burst
  ```
- Rebuild Nginx: `docker compose -f docker-compose.prod.yml up -d --build nginx`

### How to Check Container Health

```bash
# Quick health status for all containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# Detailed health check output
docker inspect --format='{{json .State.Health}}' dastern-backend | jq

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.End}}: {{.Output}}{{end}}' dastern-backend

# Check all container health at once
for container in dastern-postgres dastern-redis dastern-backend dastern-nginx dastern-ocr dastern-ai-llm dastern-bakong-payment; do
  status=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo "no healthcheck")
  echo "$container: $status"
done
```

### Useful Diagnostic Commands

```bash
# Full system diagnostic script
echo "=========================================="
echo "         SYSTEM DIAGNOSTIC REPORT"
echo "=========================================="
echo ""
echo "=== System Info ==="
uname -a
echo ""
echo "=== Docker Version ==="
docker version --format '{{.Server.Version}}'
echo ""
echo "=== Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep dastern
echo ""
echo "=== Disk Usage ==="
df -h /
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Docker Resource Usage ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep dastern
echo ""
echo "=== Recent Errors in Backend ==="
docker logs dastern-backend 2>&1 | grep -i "error\|exception" | tail -5
echo ""
echo "=========================================="
```

### Emergency Recovery

```bash
# Stop all containers
docker compose -f docker-compose.prod.yml down

# Remove all containers but keep volumes (data preserved)
docker compose -f docker-compose.prod.yml down --remove-orphans

# Full reset - REMOVES ALL DATA!
docker compose -f docker-compose.prod.yml down -v

# Rebuild everything from scratch
docker compose -f docker-compose.prod.yml up -d --build --force-recreate

# If Docker itself is having issues
sudo systemctl restart docker
docker compose -f docker-compose.prod.yml up -d
```

---

## Quick Reference Card

| Task | Command |
|------|---------|
| **Start all services** | `docker compose -f docker-compose.prod.yml up -d` |
| **Stop all services** | `docker compose -f docker-compose.prod.yml down` |
| **View logs** | `docker logs -f dastern-backend` |
| **Restart service** | `docker compose -f docker-compose.prod.yml restart backend` |
| **Rebuild & deploy** | `docker compose -f docker-compose.prod.yml up -d --build` |
| **Check status** | `docker ps` |
| **Run migrations** | `docker exec -it dastern-backend npx prisma migrate deploy` |
| **Backup database** | `docker exec dastern-postgres pg_dump -U dastern_user dastern > backup.sql` |
| **Restore database** | `docker exec -i dastern-postgres psql -U dastern_user dastern < backup.sql` |
| **Renew SSL** | `sudo certbot renew && docker exec dastern-nginx nginx -s reload` |
| **View container shell** | `docker exec -it dastern-backend sh` |
| **Test API** | `curl https://api.dastern.site/api/v1/health` |
| **Check SSL** | `openssl s_client -connect api.dastern.site:443 </dev/null` |

---

## Additional Resources

- **Environment Variables:** [PRODUCTION_ENV_VARIABLES.md](./PRODUCTION_ENV_VARIABLES.md)
- **Docker Compose Config:** [docker-compose.prod.yml](./docker-compose.prod.yml)
- **Nginx Config:** [nginx/nginx.conf](./nginx/nginx.conf)

---

**Last Updated:** March 28, 2026  
**Maintainer:** Das Tern DevOps Team  
**Version:** 2.0.0
