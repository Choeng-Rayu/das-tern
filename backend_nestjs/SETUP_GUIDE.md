# Das Tern NestJS Backend - Setup Guide

> **Quick start guide for setting up the NestJS backend with Docker (PostgreSQL & Redis)**

---

## 🎯 Overview

This guide follows the **Agent Rules**: Docker is ONLY used for PostgreSQL and Redis. The NestJS backend runs outside Docker.

---

## 📋 Prerequisites

- ✅ **Node.js** >= 22.0.0
- ✅ **npm** >= 10.0.0
- ✅ **Docker** and **Docker Compose**

---

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
cd /home/rayu/das-tern/backend_nestjs
npm install
```

### Step 2: Start Docker Containers

```bash
docker compose up -d
```

### Step 3: Generate Prisma Client

```bash
npm run prisma:generate
```

### Step 4: Run Migrations

```bash
npm run prisma:migrate
```

### Step 5: Start Backend

```bash
npm run start:dev
```

API available at: **http://localhost:3000/api/v1**

---

## 🔄 Container Lifecycle

**MUST restart when:**
- `.env` changes
- `docker-compose.yml` changes

```bash
docker compose down
docker compose up -d
```

**MUST reset when schema changes:**

```bash
docker compose down -v
docker compose up -d
npm run prisma:migrate
```

---

## 🐛 Troubleshooting

Check containers:
```bash
docker compose ps
docker compose logs postgres
docker compose logs redis
```

---

**Happy Coding! 🚀**
