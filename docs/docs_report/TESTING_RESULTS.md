# Part B – Networking Architecture Design
## Scenario C: Media Streaming Startup
### AWS Deployment | Professional Design Document
---

## 1. System Overview

**Business Context:**
A media streaming startup that delivers on-demand video and live streaming to end users globally. The platform must support:
- Video upload and transcoding by content creators
- Video playback by thousands of concurrent viewers
- Metadata management (titles, thumbnails, user data)
- Secure storage of raw and processed video files

**Key Non-Functional Requirements:**
| Requirement       | Target                                      |
|-------------------|---------------------------------------------|
| Availability      | 99.9% uptime (Multi-AZ)                     |
| Scalability       | Auto-scale during peak hours                |
| Security          | No direct DB/storage exposure to internet   |
| Performance       | Low-latency playback via CDN                |
| Compliance        | HTTPS only for all client-facing traffic    |

---

## 2. VPC Design

### 2.1 VPC CIDR Block

```
VPC CIDR:  10.0.0.0/16
Region:    ap-southeast-1 (Singapore) — primary
           us-east-1 (N. Virginia)   — CDN edge / secondary (optional)
```

**Reason for /16:**
Provides 65,536 IP addresses — sufficient room to grow subnets
across multiple Availability Zones without re-addressing.

---

### 2.2 Subnet Design (Multi-AZ: 2 AZs minimum)

| Subnet Name              | CIDR           | AZ           | Type    | Purpose                                  |
|--------------------------|----------------|--------------|---------|------------------------------------------|
| public-subnet-az1        | 10.0.1.0/24    | AZ-a         | Public  | Application Load Balancer, Bastion Host  |
| public-subnet-az2        | 10.0.2.0/24    | AZ-b         | Public  | Application Load Balancer (redundancy)   |
| private-app-az1          | 10.0.11.0/24   | AZ-a         | Private | API servers, Transcoding workers         |
| private-app-az2          | 10.0.12.0/24   | AZ-b         | Private | API servers, Transcoding workers         |
| private-db-az1           | 10.0.21.0/24   | AZ-a         | Private | RDS Primary (PostgreSQL)                 |
| private-db-az2           | 10.0.22.0/24   | AZ-b         | Private | RDS Standby (Multi-AZ failover)          |
| private-storage-az1      | 10.0.31.0/24   | AZ-a         | Private | S3 VPC Endpoint traffic, ElastiCache     |

**Total Subnets: 7**

---

## 3. Network Component Placement

### 3.1 Internet Gateway (IGW)
- **1x IGW** attached to the VPC
- Routes traffic from public subnets to the internet
- Public subnets route table: `0.0.0.0/0 → IGW`

### 3.2 NAT Gateway
- **2x NAT Gateways** (one per AZ — for high availability)
  - NAT-AZ1 placed in `public-subnet-az1`
  - NAT-AZ2 placed in `public-subnet-az2`
- Private subnets route table: `0.0.0.0/0 → NAT Gateway (local AZ)`
- **Purpose:** Allow private EC2 instances (app servers, transcoding workers)
  to pull software updates, reach AWS APIs, and download media packages
  without being reachable from the internet.

### 3.3 Load Balancer
- **Application Load Balancer (ALB)** — Layer 7
  - Placed in: `public-subnet-az1` + `public-subnet-az2`
  - Listens on: HTTPS (port 443)
  - Routes to: Private App Tier (API servers) via Target Group
  - Supports path-based routing:
    - `/api/*`   → API Server Target Group
    - `/upload*` → Transcoding/Upload Target Group
- **Internal ALB** (optional, private) for microservice-to-microservice calls

### 3.4 CloudFront CDN (AWS-managed, outside VPC)
- Sits in front of the ALB and S3 for video delivery
- Origin 1: ALB (for API/metadata)
- Origin 2: S3 bucket (for HLS video segments via signed URLs)
- Distributes to AWS edge locations globally → reduces latency for viewers

### 3.5 S3 Buckets (outside VPC, accessed via VPC Endpoint)
- `raw-video-bucket` — stores uploaded raw files (private, creator access only)
- `processed-video-bucket` — stores transcoded HLS/DASH segments
- Access via **S3 Gateway VPC Endpoint** (no NAT required for S3 traffic)

---

## 4. Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                          INTERNET                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                  [CloudFront CDN]
                  (Global Edge Locations)
                          │
                    [Route 53 DNS]
                          │
         ┌────────────────▼────────────────┐
         │         VPC: 10.0.0.0/16        │
         │  ┌──────────────────────────┐   │
         │  │   PUBLIC SUBNETS         │   │
         │  │  [ALB] ←→ IGW ←→ Internet│   │
         │  │  [Bastion Host]          │   │
         │  └───────────┬──────────────┘   │
         │              │ (HTTPS to Port 8080/internal)
         │  ┌───────────▼──────────────┐   │
         │  │   PRIVATE APP SUBNETS    │   │
         │  │  [EC2 API Servers]       │   │
         │  │  [Transcoding Workers]   │   │
         │  │  (Auto Scaling Group)    │   │
         │  └───────────┬──────────────┘   │
         │              │ (DB port 5432)    │
         │  ┌───────────▼──────────────┐   │
         │  │   PRIVATE DB SUBNETS     │   │
         │  │  [RDS PostgreSQL Pri]    │   │
         │  │  [RDS Standby Multi-AZ]  │   │
         │  │  [ElastiCache Redis]     │   │
         │  └──────────────────────────┘   │
         │                                 │
         │  [NAT GW]←→[S3 VPC Endpoint]   │
         └─────────────────────────────────┘
```

---

## 5. Security Group Rules

### SG-1: ALB Security Group (`sg-alb`)
| Direction | Protocol | Port | Source/Destination | Reason                        |
|-----------|----------|------|-------------------|-------------------------------|
| Inbound   | TCP      | 443  | 0.0.0.0/0         | HTTPS from all internet users |
| Inbound   | TCP      | 80   | 0.0.0.0/0         | HTTP (redirect to 443 only)   |
| Outbound  | TCP      | 8080 | sg-app            | Forward to API servers        |

### SG-2: App Server Security Group (`sg-app`)
| Direction | Protocol | Port | Source/Destination | Reason                             |
|-----------|----------|------|-------------------|------------------------------------|
| Inbound   | TCP      | 8080 | sg-alb            | Only accept traffic from ALB       |
| Inbound   | TCP      | 22   | sg-bastion        | SSH only from Bastion Host         |
| Outbound  | TCP      | 5432 | sg-db             | Connect to PostgreSQL              |
| Outbound  | TCP      | 6379 | sg-cache          | Connect to Redis                   |
| Outbound  | TCP      | 443  | 0.0.0.0/0         | HTTPS to S3, AWS APIs (via NAT)    |

### SG-3: Database Security Group (`sg-db`)
| Direction | Protocol | Port | Source/Destination | Reason                              |
|-----------|----------|------|-------------------|-------------------------------------|
| Inbound   | TCP      | 5432 | sg-app            | Only API servers can query database |
| Outbound  | ALL      | ALL  | NONE              | No outbound access required         |

### SG-4: ElastiCache Security Group (`sg-cache`)
| Direction | Protocol | Port | Source/Destination | Reason                         |
|-----------|----------|------|-------------------|--------------------------------|
| Inbound   | TCP      | 6379 | sg-app            | Only app servers access Redis  |
| Outbound  | ALL      | ALL  | NONE              | No outbound required           |

### SG-5: Bastion Host Security Group (`sg-bastion`)
| Direction | Protocol | Port | Source/Destination     | Reason                          |
|-----------|----------|------|------------------------|---------------------------------|
| Inbound   | TCP      | 22   | Corporate IP/32 only   | SSH restricted to known IPs     |
| Outbound  | TCP      | 22   | sg-app                 | Can SSH into private app servers|

---

## 6. Traffic Flow (Step-by-Step)

### 6.1 Viewer Watching a Video
```
1. User opens browser → DNS lookup via Route 53
2. Route 53 resolves to CloudFront distribution URL
3. CloudFront checks cache:
   - HIT  → serve video segment directly from edge cache
   - MISS → requests from S3 processed-video-bucket (origin)
4. Video segments (.m3u8 / .ts) delivered via HTTPS to user
```

### 6.2 API Request (e.g., search, user login)
```
1. Client sends HTTPS request to CloudFront
2. CloudFront forwards /api/* to ALB origin
3. ALB receives on port 443, terminates SSL
4. ALB forwards to EC2 API Server (port 8080) in private-app subnet
5. API Server queries:
   - ElastiCache Redis (cache hit) → return immediately
   - RDS PostgreSQL (cache miss)  → query DB, update cache, return
6. Response flows back: DB → App → ALB → CloudFront → User
```

### 6.3 Content Creator Uploading a Video
```
1. Creator authenticates via API (JWT token)
2. API Server generates pre-signed S3 URL
3. Creator uploads directly to S3 raw-video-bucket (bypasses servers)
4. S3 Event triggers SQS/Lambda notification
5. Transcoding Worker (in private-app subnet) picks up job
6. Worker processes video (converts to HLS, multiple resolutions)
7. Output stored in S3 processed-video-bucket
8. Metadata saved to RDS via Worker → DB connection
```

---

## 7. Complete Networking Architecture Table

| Design Decision             | Choice                              | Justification                                                     |
|-----------------------------|-------------------------------------|-------------------------------------------------------------------|
| VPC CIDR                    | 10.0.0.0/16                         | Supports 65K IPs; room for growth across 7+ subnets              |
| Availability Zones          | 2 AZs (AZ-a, AZ-b)                 | Ensures fault tolerance; service survives 1 AZ failure           |
| Public Subnets              | 2 (one per AZ)                      | Only ALB and Bastion Host exposed to internet                     |
| Private App Subnets         | 2 (one per AZ)                      | API & transcoding servers isolated; unreachable from internet     |
| Private DB Subnets          | 2 (one per AZ)                      | DB never exposed; only app tier has access                        |
| Internet Gateway            | 1 (attached to VPC)                 | Single IGW handles all public subnet internet traffic             |
| NAT Gateway                 | 2 (one per AZ)                      | Private servers get outbound internet; no inbound exposure        |
| Load Balancer               | Public ALB (Layer 7)                | HTTPS termination, path-based routing, health checks              |
| CDN                         | CloudFront                          | Global video distribution, reduces origin load, caching           |
| Database                    | RDS PostgreSQL Multi-AZ             | Managed DB with automatic standby failover                        |
| Caching                     | ElastiCache Redis                   | Reduce DB reads for metadata/session data                         |
| Storage                     | S3 + VPC Gateway Endpoint           | Scalable storage; endpoint avoids NAT cost for S3 traffic         |
| Bastion Host                | 1 in public subnet                  | Admin SSH access to private instances; no direct RDP/SSH from web |
| Auto Scaling                | ASG for App & Transcoding tiers     | Scale out during viral content spikes                             |

---

## 8. Risk Analysis

### 8.1 Risks of Poor Networking Design

| Risk                             | Impact              | Example of Poor Design                          | Mitigation Applied                            |
|----------------------------------|---------------------|-------------------------------------------------|-----------------------------------------------|
| Database exposed to internet     | **CRITICAL**        | RDS in public subnet with port 5432 open to all | DB in private subnet, SG allows only sg-app   |
| Single AZ deployment             | **HIGH**            | All resources in 1 AZ                           | Multi-AZ subnets + RDS Multi-AZ enabled       |
| Overly permissive Security Groups| **HIGH**            | SG allows 0.0.0.0/0 on all ports               | Least-privilege SGs; restrict by source SG    |
| No NAT Gateway                   | **MEDIUM**          | Private servers cannot be patched/updated       | NAT GW per AZ enables outbound-only access    |
| No CDN                           | **MEDIUM**          | Origin servers handle every video byte globally | CloudFront offloads 80–90% of video traffic   |
| Shared subnets (app + DB)        | **MEDIUM**          | App and DB in same subnet, no logical isolation | Separate subnet tiers with Route Tables       |
| No Bastion / SSM                 | **MEDIUM**          | SSH open to 0.0.0.0/0 on app servers           | Bastion with restricted IP, or AWS SSM        |
| Single NAT Gateway               | **LOW-MEDIUM**      | NAT in one AZ — failure kills all outbound      | One NAT Gateway per AZ                        |

### 8.2 How Security Groups Protect Instances

1. **Defense in Depth:** Each tier (ALB → App → DB) only accepts traffic from the tier directly above it, using Security Group IDs as sources — not IP ranges.
2. **No inbound from internet to private tiers:** App and DB servers are invisible to the internet by design.
3. **Stateful filtering:** Security Groups are stateful — response traffic is automatically allowed without needing a separate outbound rule.
4. **Minimal blast radius:** If an app server is compromised, the attacker still cannot reach the DB directly unless they also bypass `sg-db` rules.

### 8.3 How Availability is Ensured

| Mechanism                  | Protects Against                    |
|----------------------------|-------------------------------------|
| Multi-AZ subnets           | Single datacenter (AZ) failure      |
| ALB with health checks     | Unhealthy instance receiving traffic|
| Auto Scaling Group         | Traffic spikes overwhelming servers |
| RDS Multi-AZ               | Database primary instance failure   |
| 2x NAT Gateways            | NAT failure cutting off private tier|
| CloudFront                 | Origin overload; regional outage    |
| ElastiCache Redis (cluster)| DB overload from repetitive queries |

---

## 9. AWS Services Summary

| Layer           | AWS Service                     |
|-----------------|---------------------------------|
| DNS             | Route 53                        |
| CDN             | CloudFront                      |
| Load Balancer   | Application Load Balancer (ALB) |
| Compute         | EC2 (Auto Scaling Groups)       |
| Container (opt) | ECS Fargate (for transcoding)   |
| Database        | RDS PostgreSQL (Multi-AZ)       |
| Cache           | ElastiCache for Redis           |
| Object Storage  | Amazon S3                       |
| Networking      | VPC, Subnets, IGW, NAT GW, SG   |
| Admin Access    | EC2 Bastion Host / AWS SSM      |
| Queue (opt)     | SQS (transcode job queue)       |
| Monitoring      | CloudWatch + VPC Flow Logs      |

---

*Document Version: 1.0 | Date: February 2026 | Scenario C – Media Streaming Startup*