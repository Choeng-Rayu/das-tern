# 🏗️ Das Tern - System Architecture

> **Scalable, Secure, and Offline-First Medication Management Platform**

---

## 📑 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Technology Stack](#-technology-stack)
- [System Components](#-system-components)
- [Security Architecture](#-security-architecture)
- [Data Architecture](#-data-architecture)
- [Offline-First Strategy](#-offline-first-strategy)
- [Scalability Design](#-scalability-design)
- [Third-Party Integrations](#-third-party-integrations)
- [Deployment Architecture](#-deployment-architecture)
- [Monitoring & Observability](#-monitoring--observability)

---

## 🎯 Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐         ┌──────────────────┐            │
│  │  Flutter Mobile  │         │  Flutter Mobile  │            │
│  │   (Patient App)  │         │  (Doctor Portal) │            │
│  │                  │         │                  │            │
│  │  • Offline-First │         │  • Real-time     │            │
│  │  • Local Storage │         │  • Notifications │            │
│  │  • Push Notif    │         │  • Analytics     │            │
│  └──────────────────┘         └──────────────────┘            │
│           │                            │                       │
└───────────┼────────────────────────────┼───────────────────────┘
            │                            │
            └────────────┬───────────────┘
                         │
            (one application but two interface)
                    HTTPS/WSS
                         │
┌────────────────────────┼───────────────────────────────────────┐
│                   API GATEWAY LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              API Gateway (Kong / AWS API Gateway)        │  │
│  │                                                          │  │
│  │  • Rate Limiting      • Authentication                  │  │
│  │  • Load Balancing     • Request Validation              │  │
│  │  • SSL Termination    • API Versioning                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────────────┐
│                   APPLICATION LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │   Next.js API  │  │   Next.js API  │  │   Next.js API  │   │
│  │   Server 1     │  │   Server 2     │  │   Server N     │   │
│  │                │  │                │  │                │   │
│  │  • REST APIs   │  │  • GraphQL     │  │  • WebSocket   │   │
│  │  • Business    │  │  • Real-time   │  │  • Background  │   │
│  │    Logic       │  │    Queries     │  │    Jobs        │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
│                                                                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────────────┐
│                    SERVICE LAYER                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Auth Service │  │ Notification │  │ Sync Service │         │
│  │              │  │   Service    │  │              │         │
│  │ • OAuth 2.0  │  │ • Push Notif │  │ • Conflict   │         │
│  │ • JWT        │  │ • Email      │  │   Resolution │         │
│  │ • Google SSO │  │ • SMS        │  │ • Queue Mgmt │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Prescription │  │ Audit Log    │  │ File Storage │         │
│  │   Service    │  │   Service    │  │   Service    │         │
│  │              │  │              │  │              │         │
│  │ • Versioning │  │ • Compliance │  │ • S3/Minio   │         │
│  │ • Validation │  │ • Tracking   │  │ • CDN        │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────┼───────────────────────────────────────┐
│                     DATA LAYER                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         PostgreSQL Primary (Docker Container)          │    │
│  │                                                        │    │
│  │  • ACID Compliance    • Row-Level Security            │    │
│  │  • Encryption at Rest • Audit Logging                 │    │
│  └────────────────────────────────────────────────────────┘    │
│                          │                                     │
│                          │ Replication                         │
│                          ▼                                     │
│  ┌────────────────────────────────────────────────────────┐    │
│  │      PostgreSQL Read Replicas (Docker Containers)      │    │
│  │                                                        │    │
│  │  • Read Scaling       • Analytics Queries             │    │
│  │  • Failover Support   • Reporting                     │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────┐         ┌────────────────┐                │
│  │  Redis Cache   │         │  Message Queue │                │
│  │                │         │  (RabbitMQ)    │                │
│  │  • Session     │         │                │                │
│  │  • Rate Limit  │         │  • Async Jobs  │                │
│  │  • Real-time   │         │  • Sync Queue  │                │
│  └────────────────┘         └────────────────┘                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Frontend

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Mobile App** | Flutter 3.x | Cross-platform iOS/Android |
| **State Management** | Riverpod / Bloc | Reactive state management |
| **Local Database** | SQLite + Drift | Offline data persistence |
| **Secure Storage** | flutter_secure_storage | Encrypted credential storage |
| **HTTP Client** | Dio | API communication with interceptors |
| **Push Notifications** | Firebase Cloud Messaging | Real-time notifications |
| **Local Notifications** | flutter_local_notifications | Offline reminder system |

### Backend

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **API Framework** | Next.js 14+ (App Router) | Server-side API routes |
| **Runtime** | Node.js 20+ | JavaScript runtime |
| **API Type** | REST + GraphQL | Flexible API design |
| **Real-time** | WebSocket (Socket.io) | Live updates |
| **ORM** | Prisma | Type-safe database access |
| **Validation** | Zod | Schema validation |
| **Authentication** | NextAuth.js | OAuth & JWT management |

### Database & Storage

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Primary Database** | PostgreSQL 16+ | Relational data storage |
| **Containerization** | Docker + Docker Compose | Database hosting |
| **Cache** | Redis 7+ | Session & rate limiting |
| **Message Queue** | RabbitMQ / Bull | Async job processing |
| **File Storage** | AWS S3 / MinIO | Document & image storage |
| **CDN** | CloudFront / Cloudflare | Static asset delivery |

### Security

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Authentication** | OAuth 2.0 + JWT | Secure authentication |
| **SSO Provider** | Google OAuth | Social login |
| **Encryption** | AES-256 | Data encryption at rest |
| **TLS/SSL** | Let's Encrypt | Transport encryption |
| **API Gateway** | Kong / AWS API Gateway | Rate limiting & security |
| **Secrets Management** | AWS Secrets Manager / Vault | Credential management |
| **WAF** | Cloudflare WAF | Web application firewall |

---

## 🧩 System Components

### 1. Mobile Application (Flutter)

#### Single App, Multiple Roles

**One unified Flutter app** that adapts UI based on user role (Patient/Doctor/Family).

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER APP                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Authentication Layer                   │  │
│  │                                                  │  │
│  │  Login → Fetch User Profile → Determine Role    │  │
│  └──────────────────┬───────────────────────────────┘  │
│                     │                                   │
│         ┌───────────┴───────────┐                       │
│         │                       │                       │
│  ┌──────▼──────┐         ┌──────▼──────┐               │
│  │   Patient   │         │   Doctor    │               │
│  │     UI      │         │     UI      │               │
│  │             │         │             │               │
│  │ • Time-based│         │ • Patient   │               │
│  │   schedule  │         │   list      │               │
│  │ • Morning/  │         │ • Adherence │               │
│  │   Afternoon │         │   tracking  │               │
│  │   /Night    │         │ • Prescribe │               │
│  │ • Calendar  │         │ • Analytics │               │
│  │ • Quick     │         │ • Urgent    │               │
│  │   "Taken"   │         │   updates   │               │
│  └─────────────┘         └─────────────┘               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Architecture Pattern: Clean Architecture + Feature-First

```
/lib
  /core
    /theme
      patient_theme.dart      # Blue/Orange/Purple
      doctor_theme.dart       # Professional colors
    /router
      app_router.dart         # Role-based routing
    /di
      injection.dart          # Dependency injection
  
  /features
    /auth
      /presentation
        login_screen.dart
      /domain
      /data
    
    /patient                  # Patient-specific features
      /dashboard
        patient_dashboard.dart
        morning_meds_widget.dart
        afternoon_meds_widget.dart
        night_meds_widget.dart
      /calendar
        adherence_calendar.dart
      /medication
        medication_card.dart
        take_medication_dialog.dart
    
    /doctor                   # Doctor-specific features
      /dashboard
        doctor_dashboard.dart
        patient_list_widget.dart
        adherence_indicator.dart
      /prescription
        prescription_editor.dart
        urgent_update_dialog.dart
      /analytics
        patient_analytics.dart
    
    /shared                   # Shared features
      /connections
      /notifications
      /settings
  
  /data
    /local
      database.dart           # SQLite + Drift
      cache_manager.dart
    /remote
      api_client.dart
    /sync
      sync_manager.dart       # Offline sync engine
```

#### Performance Optimizations

**1. Lazy Loading & Code Splitting**

```dart
// Role-based lazy loading
class AppRouter {
  static Route onGenerateRoute(RouteSettings settings) {
    final user = getIt<AuthService>().currentUser;
    
    // Load only relevant UI code based on role
    if (user.role == UserRole.patient) {
      return MaterialPageRoute(
        builder: (_) => const PatientDashboard(),
      );
    } else if (user.role == UserRole.doctor) {
      return MaterialPageRoute(
        builder: (_) => const DoctorDashboard(),
      );
    }
  }
}
```

**2. Efficient State Management (Riverpod)**

```dart
// Cache-first data fetching
@riverpod
Future<List<Medication>> medications(MedicationsRef ref) async {
  // 1. Return cached data immediately
  final cached = await ref.watch(localDatabaseProvider)
    .getMedications();
  
  if (cached.isNotEmpty) {
    // Return cached, fetch in background
    ref.read(syncServiceProvider).syncMedications();
    return cached;
  }
  
  // 2. Fetch from API if no cache
  return ref.watch(apiClientProvider).getMedications();
}
```

**3. Image Optimization**

```dart
// Cached network images with compression
CachedNetworkImage(
  imageUrl: medication.imageUrl,
  memCacheWidth: 200,  // Resize in memory
  memCacheHeight: 200,
  maxWidthDiskCache: 400,
  maxHeightDiskCache: 400,
  placeholder: (context, url) => const ShimmerPlaceholder(),
  errorWidget: (context, url, error) => const DefaultMedicationIcon(),
)
```

**4. List Performance**

```dart
// Efficient scrolling with ListView.builder
ListView.builder(
  itemCount: medications.length,
  cacheExtent: 500,  // Pre-render items
  itemBuilder: (context, index) {
    final med = medications[index];
    return MedicationCard(
      key: ValueKey(med.id),  // Preserve state
      medication: med,
    );
  },
)
```

**5. Database Optimization**

```dart
// Indexed queries for fast lookups
@DataClassName('Medication')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get scheduledTime => dateTime()();
  IntColumn get userId => integer()();
  
  @override
  Set<Index> get indexes => {
    Index('idx_user_scheduled', [userId, scheduledTime]),
    Index('idx_scheduled_time', [scheduledTime]),
  };
}
```

**6. Background Sync Strategy**

```dart
// Intelligent sync with exponential backoff
class SyncManager {
  Timer? _syncTimer;
  
  void startPeriodicSync() {
    // Sync every 5 minutes when app is active
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncIfNeeded(),
    );
  }
  
  Future<void> syncIfNeeded() async {
    // Skip if offline
    if (!await connectivity.hasConnection) return;
    
    // Skip if recently synced (< 2 min ago)
    final lastSync = await getLastSyncTime();
    if (DateTime.now().difference(lastSync) < Duration(minutes: 2)) {
      return;
    }
    
    // Batch sync operations
    await Future.wait([
      syncMedications(),
      syncDoseEvents(),
      syncConnections(),
    ]);
  }
}
```

**7. Memory Management**

```dart
// Dispose resources properly
class PatientDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends ConsumerState<PatientDashboard> {
  late final ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Use AutoDispose providers to clean up when not needed
    final medications = ref.watch(medicationsProvider);
    // ...
  }
}
```

#### Key Features

- **Role-Based UI**: Single app, different interfaces per role
- **Offline-First Architecture**: All data cached locally
- **Background Sync**: Automatic sync when online
- **Conflict Resolution**: CRDT-based or last-write-wins
- **Local Notifications**: Scheduled medication reminders
- **Biometric Authentication**: Face ID / Fingerprint
- **End-to-End Encryption**: Sensitive data encrypted
- **Optimized Performance**: Lazy loading, caching, efficient rendering

---

### 2. Backend API (Next.js)

#### Project Structure

```
/app
  /api
    /auth
      /[...nextauth]      # NextAuth.js routes
      /google             # Google OAuth
    /v1
      /patients           # Patient endpoints
      /prescriptions      # Prescription management
      /doses              # Dose tracking
      /connections        # Doctor/Family connections
      /sync               # Offline sync endpoints
      /notifications      # Push notification management
    /graphql              # GraphQL endpoint
  /webhooks               # Third-party webhooks

/lib
  /db                     # Prisma client
  /auth                   # Auth utilities
  /services               # Business logic services
  /middleware             # Custom middleware
  /utils                  # Helper functions

/prisma
  schema.prisma           # Database schema
  /migrations             # Database migrations
```

#### API Design Principles

- **RESTful Endpoints**: Standard CRUD operations
- **GraphQL**: Complex queries and real-time subscriptions
- **API Versioning**: `/api/v1`, `/api/v2`
- **Rate Limiting**: Per-user and per-IP limits
- **Request Validation**: Zod schemas for all inputs
- **Error Handling**: Standardized error responses
- **Pagination**: Cursor-based pagination
- **Filtering & Sorting**: Query parameter support

---

### 3. Database (PostgreSQL)

#### Schema Design Highlights

```sql
-- Core tables with security considerations
users (
  id UUID PRIMARY KEY,
  email VARCHAR UNIQUE,
  google_id VARCHAR UNIQUE,
  role ENUM('patient', 'doctor', 'family'),
  encrypted_data JSONB,  -- Encrypted sensitive data
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

prescriptions (
  id UUID PRIMARY KEY,
  patient_id UUID REFERENCES users(id),
  doctor_id UUID REFERENCES users(id),
  version INTEGER,
  parent_version_id UUID REFERENCES prescriptions(id),
  status ENUM('draft', 'active', 'paused', 'inactive'),
  is_urgent BOOLEAN,
  encrypted_details JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

dose_events (
  id UUID PRIMARY KEY,
  prescription_id UUID REFERENCES prescriptions(id),
  scheduled_time TIMESTAMP,
  taken_time TIMESTAMP,
  status ENUM('due', 'taken_on_time', 'taken_late', 'missed', 'skipped'),
  sync_status ENUM('synced', 'pending'),
  created_at TIMESTAMP
)

connections (
  id UUID PRIMARY KEY,
  requester_id UUID REFERENCES users(id),
  target_id UUID REFERENCES users(id),
  connection_type ENUM('doctor', 'family'),
  status ENUM('pending', 'accepted', 'rejected', 'revoked'),
  permission_level ENUM('not_allowed', 'request', 'selected', 'allowed'),
  created_at TIMESTAMP
)

audit_logs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  action VARCHAR,
  resource_type VARCHAR,
  resource_id UUID,
  metadata JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP
)
```

#### Database Security Features

- **Row-Level Security (RLS)**: PostgreSQL policies
- **Encryption at Rest**: Transparent Data Encryption
- **Encrypted Columns**: Sensitive data encrypted
- **Audit Logging**: All data access logged
- **Connection Pooling**: PgBouncer for efficiency
- **Backup Strategy**: Automated daily backups

---


## 🔐 Security Architecture

### Defense in Depth Strategy

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: Network Security                             │
│  • WAF (Cloudflare)                                    │
│  • DDoS Protection                                     │
│  • IP Whitelisting for Admin                           │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  Layer 2: API Gateway Security                         │
│  • Rate Limiting (100 req/min per user)                │
│  • Request Size Limits                                 │
│  • API Key Validation                                  │
│  • JWT Verification                                    │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  Layer 3: Application Security                         │
│  • Input Validation (Zod)                              │
│  • SQL Injection Prevention (Prisma ORM)               │
│  • XSS Protection                                      │
│  • CSRF Tokens                                         │
│  • Content Security Policy                             │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  Layer 4: Authentication & Authorization               │
│  • OAuth 2.0 + OpenID Connect                          │
│  • JWT with Short Expiry (15 min)                      │
│  • Refresh Tokens (7 days)                             │
│  • Role-Based Access Control (RBAC)                    │
│  • Attribute-Based Access Control (ABAC)               │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  Layer 5: Data Security                                │
│  • Encryption at Rest (AES-256)                        │
│  • Encryption in Transit (TLS 1.3)                     │
│  • Field-Level Encryption                              │
│  • Database Row-Level Security                         │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│  Layer 6: Monitoring & Audit                           │
│  • Comprehensive Audit Logging                         │
│  • Anomaly Detection                                   │
│  • Security Event Monitoring                           │
│  • Compliance Reporting                                │
└─────────────────────────────────────────────────────────┘
```

### Authentication Flow

#### Google OAuth + JWT Flow

```
┌──────────┐                                    ┌──────────┐
│  Flutter │                                    │  Google  │
│   App    │                                    │  OAuth   │
└────┬─────┘                                    └────┬─────┘
     │                                               │
     │ 1. Initiate Google Sign-In                    │
     ├──────────────────────────────────────────────>│
     │                                               │
     │ 2. User Authenticates                         │
     │                                               │
     │ 3. Return Authorization Code                  │
     │<──────────────────────────────────────────────┤
     │                                               │
     │                  ┌──────────┐                 │
     │                  │ Next.js  │                 │
     │                  │  Backend │                 │
     │                  └────┬─────┘                 │
     │                       │                       │
     │ 4. Send Auth Code     │                       │
     ├──────────────────────>│                       │
     │                       │                       │
     │                       │ 5. Exchange Code      │
     │                       │   for Tokens          │
     │                       ├──────────────────────>│
     │                       │                       │
     │                       │ 6. Return Tokens      │
     │                       │<──────────────────────┤
     │                       │                       │
     │                       │ 7. Verify & Create    │
     │                       │    User Session       │
     │                       │                       │
     │ 8. Return JWT Tokens  │                       │
     │    (Access + Refresh) │                       │
     │<──────────────────────┤                       │
     │                       │                       │
     │ 9. Store Tokens       │                       │
     │    Securely           │                       │
     │                       │                       │
```

### Security Best Practices Implementation

#### 1. Authentication Security

```typescript
// JWT Configuration
{
  accessToken: {
    expiresIn: '15m',
    algorithm: 'RS256',  // Asymmetric encryption
    issuer: 'dastern.com',
    audience: 'dastern-mobile-app'
  },
  refreshToken: {
    expiresIn: '7d',
    rotationEnabled: true,  // Rotate on each use
    reuseDetection: true    // Detect token theft
  }
}
```

#### 2. Password Security (if email/password enabled)

- **Hashing**: Argon2id (winner of Password Hashing Competition)
- **Salt**: Unique per user, cryptographically random
- **Pepper**: Application-wide secret
- **Password Policy**: 
  - Minimum 12 characters
  - Mix of uppercase, lowercase, numbers, symbols
  - Check against breached password database (HaveIBeenPwned API)

#### 3. API Security Headers

```typescript
// Security Headers
{
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'X-XSS-Protection': '1; mode=block',
  'Content-Security-Policy': "default-src 'self'",
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(), microphone=(), camera=()'
}
```

#### 4. Rate Limiting Strategy

| Endpoint Type | Rate Limit | Window |
|--------------|------------|--------|
| **Authentication** | 5 attempts | 15 minutes |
| **Read Operations** | 100 requests | 1 minute |
| **Write Operations** | 30 requests | 1 minute |
| **Sync Operations** | 10 requests | 1 minute |
| **File Upload** | 5 uploads | 5 minutes |

#### 5. Data Encryption

**At Rest:**
```typescript
// Field-level encryption for sensitive data
const encryptedData = {
  medicalHistory: encrypt(data.medicalHistory, userKey),
  prescriptionDetails: encrypt(data.prescriptionDetails, userKey),
  personalNotes: encrypt(data.personalNotes, userKey)
}
```

**In Transit:**
- TLS 1.3 only
- Perfect Forward Secrecy (PFS)
- Certificate pinning in mobile app

#### 6. Access Control

**Role-Based Access Control (RBAC):**
```typescript
enum Role {
  PATIENT = 'patient',
  DOCTOR = 'doctor',
  FAMILY = 'family',
  ADMIN = 'admin'
}

enum Permission {
  READ_OWN_DATA = 'read:own',
  WRITE_OWN_DATA = 'write:own',
  READ_PATIENT_DATA = 'read:patient',
  WRITE_PRESCRIPTION = 'write:prescription',
  MANAGE_CONNECTIONS = 'manage:connections'
}
```

**Attribute-Based Access Control (ABAC):**
```typescript
// Permission check example
function canAccessPrescription(user, prescription) {
  // Patient owns the prescription
  if (prescription.patientId === user.id) return true;
  
  // Doctor has connection with ALLOWED permission
  if (user.role === 'doctor') {
    const connection = getConnection(user.id, prescription.patientId);
    return connection?.permissionLevel === 'ALLOWED';
  }
  
  // Family has connection and permission
  if (user.role === 'family') {
    const connection = getConnection(user.id, prescription.patientId);
    return connection?.status === 'accepted';
  }
  
  return false;
}
```

---

## 💾 Data Architecture

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    MOBILE APP                           │
│                                                         │
│  ┌──────────────┐         ┌──────────────┐            │
│  │   UI Layer   │────────>│ Local SQLite │            │
│  └──────────────┘         └──────┬───────┘            │
│         │                        │                     │
│         │                        │                     │
│  ┌──────▼──────────────────────┐ │                     │
│  │   Sync Manager              │ │                     │
│  │                             │ │                     │
│  │  • Conflict Resolution      │ │                     │
│  │  • Queue Management         │ │                     │
│  │  • Retry Logic              │ │                     │
│  └──────┬──────────────────────┘ │                     │
│         │                        │                     │
└─────────┼────────────────────────┼─────────────────────┘
          │                        │
          │ HTTPS                  │ Read
          │                        │
┌─────────▼────────────────────────▼─────────────────────┐
│                   API LAYER                             │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Sync Endpoint                          │  │
│  │                                                  │  │
│  │  1. Receive client changes                      │  │
│  │  2. Validate & authenticate                     │  │
│  │  3. Resolve conflicts (server wins / CRDT)      │  │
│  │  4. Apply changes to database                   │  │
│  │  5. Return server state                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                  DATABASE LAYER                         │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │         PostgreSQL Primary                     │    │
│  │                                                │    │
│  │  • Write operations                            │    │
│  │  • Transactional integrity                     │    │
│  └────────────────┬───────────────────────────────┘    │
│                   │                                     │
│                   │ Streaming Replication               │
│                   │                                     │
│  ┌────────────────▼───────────────────────────────┐    │
│  │         PostgreSQL Read Replicas               │    │
│  │                                                │    │
│  │  • Read operations                             │    │
│  │  • Analytics queries                           │    │
│  └────────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Offline Sync Strategy

#### Conflict Resolution Algorithm

```typescript
interface SyncRecord {
  id: string;
  localVersion: number;
  serverVersion: number;
  lastSyncedAt: Date;
  data: any;
}

function resolveConflict(local: SyncRecord, server: SyncRecord) {
  // Strategy 1: Last Write Wins (LWW)
  if (local.updatedAt > server.updatedAt) {
    return { winner: 'local', action: 'overwrite_server' };
  }
  
  // Strategy 2: Server Always Wins (for prescriptions)
  if (server.resourceType === 'prescription') {
    return { winner: 'server', action: 'overwrite_local' };
  }
  
  // Strategy 3: Merge (for dose events)
  if (server.resourceType === 'dose_event') {
    return { winner: 'merge', action: 'merge_both' };
  }
  
  // Strategy 4: Manual Resolution Required
  return { winner: 'none', action: 'require_user_input' };
}
```

#### Sync Queue Management

```typescript
interface SyncQueue {
  pending: SyncOperation[];
  inProgress: SyncOperation[];
  failed: SyncOperation[];
  completed: SyncOperation[];
}

// Retry strategy with exponential backoff
const retryConfig = {
  maxRetries: 5,
  initialDelay: 1000,      // 1 second
  maxDelay: 60000,         // 1 minute
  backoffMultiplier: 2
};
```

---

## 📱 Offline-First Strategy

### Local Storage Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  FLUTTER APP STORAGE                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  SQLite Database (Drift)                         │  │
│  │                                                  │  │
│  │  Tables:                                         │  │
│  │  • users                                         │  │
│  │  • prescriptions                                 │  │
│  │  • dose_events                                   │  │
│  │  • connections                                   │  │
│  │  • sync_queue                                    │  │
│  │  • audit_logs_cache                              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Secure Storage (flutter_secure_storage)        │  │
│  │                                                  │  │
│  │  • JWT Access Token                             │  │
│  │  • JWT Refresh Token                            │  │
│  │  • Encryption Keys                              │  │
│  │  • Biometric Auth Token                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Shared Preferences                              │  │
│  │                                                  │  │
│  │  • User Preferences                             │  │
│  │  • App Settings                                 │  │
│  │  • Last Sync Timestamp                          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  File System                                     │  │
│  │                                                  │  │
│  │  • Cached Images                                │  │
│  │  • Downloaded Documents                         │  │
│  │  • Logs                                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Offline Reminder System

```typescript
// Schedule local notifications for reminders
class OfflineReminderService {
  async scheduleReminders(prescription: Prescription) {
    const doseEvents = generateDoseSchedule(prescription);
    
    for (const event of doseEvents) {
      await scheduleLocalNotification({
        id: event.id,
        title: `Time to take ${prescription.medicationName}`,
        body: `Dosage: ${prescription.dosage}`,
        scheduledDate: event.scheduledTime,
        payload: JSON.stringify(event),
        sound: 'default',
        badge: 1
      });
    }
  }
  
  async handleMissedDose(doseEvent: DoseEvent) {
    // Store missed dose locally
    await db.doseEvents.update({
      where: { id: doseEvent.id },
      data: { 
        status: 'missed',
        syncStatus: 'pending'
      }
    });
    
    // Queue for sync when online
    await syncQueue.add({
      type: 'missed_dose',
      data: doseEvent,
      priority: 'high'
    });
  }
}
```

---

## 📈 Scalability Design

### Horizontal Scaling Strategy

```
┌─────────────────────────────────────────────────────────┐
│                   LOAD BALANCER                         │
│              (Nginx / AWS ALB / Kong)                   │
│                                                         │
│  • Round Robin                                          │
│  • Health Checks                                        │
│  • SSL Termination                                      │
└────────────┬────────────────────────────────────────────┘
             │
             ├──────────┬──────────┬──────────┬──────────┐
             │          │          │          │          │
┌────────────▼───┐ ┌────▼────┐ ┌──▼──────┐ ┌─▼────────┐ │
│  Next.js API   │ │Next.js  │ │Next.js  │ │Next.js   │ │
│   Instance 1   │ │Instance │ │Instance │ │Instance  │ │
│                │ │    2    │ │    3    │ │    N     │ │
│  • Stateless   │ │         │ │         │ │          │ │
│  • Auto-scale  │ │         │ │         │ │          │ │
└────────────────┘ └─────────┘ └─────────┘ └──────────┘ │
             │          │          │          │          │
             └──────────┴──────────┴──────────┴──────────┘
                                  │
┌─────────────────────────────────▼───────────────────────┐
│              DATABASE CONNECTION POOL                   │
│                    (PgBouncer)                          │
└─────────────────────────────────────────────────────────┘
```

### Caching Strategy

```
┌─────────────────────────────────────────────────────────┐
│                   CACHING LAYERS                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 1: CDN Cache (CloudFront / Cloudflare)          │
│  • Static assets                                        │
│  • Public content                                       │
│  • TTL: 1 year                                          │
│                                                         │
│  Layer 2: API Gateway Cache                             │
│  • GET responses                                        │
│  • Public endpoints                                     │
│  • TTL: 5 minutes                                       │
│                                                         │
│  Layer 3: Redis Cache                                   │
│  • User sessions                                        │
│  • Frequently accessed data                             │
│  • Rate limiting counters                               │
│  • TTL: 15 minutes - 1 hour                             │
│                                                         │
│  Layer 4: Application Cache                             │
│  • In-memory cache (Node.js)                            │
│  • Database query results                               │
│  • TTL: 1-5 minutes                                     │
│                                                         │
│  Layer 5: Database Query Cache                          │
│  • PostgreSQL query cache                               │
│  • Materialized views                                   │
│  • Refresh: On-demand / Scheduled                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Database Scaling

#### Read/Write Splitting

```typescript
// Prisma configuration for read replicas
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL  // Primary (writes)
    }
  }
});

const prismaRead = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_READ_URL  // Replica (reads)
    }
  }
});

// Usage
async function getPrescriptions(userId: string) {
  // Use read replica for queries
  return prismaRead.prescription.findMany({
    where: { patientId: userId }
  });
}

async function createPrescription(data: any) {
  // Use primary for writes
  return prisma.prescription.create({ data });
}
```

#### Partitioning Strategy

```sql
-- Partition audit_logs by date for better performance
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    user_id UUID,
    action VARCHAR,
    created_at TIMESTAMP
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE audit_logs_2026_01 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE audit_logs_2026_02 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
```

### Auto-Scaling Configuration

```yaml
# Kubernetes HPA (Horizontal Pod Autoscaler)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: dastern-api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: dastern-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---


## 🔌 Third-Party Integrations

### Required Services

| Service | Provider | Purpose | Alternatives |
|---------|----------|---------|--------------|
| **Authentication** | Google OAuth | Social login | Auth0, Firebase Auth |
| **Push Notifications** | Firebase Cloud Messaging | Real-time alerts | OneSignal, Pusher |
| **Email Service** | SendGrid / AWS SES | Transactional emails | Mailgun, Postmark |
| **SMS Service** | Twilio | SMS notifications | AWS SNS, Vonage |
| **File Storage** | AWS S3 | Document storage | MinIO (self-hosted), Google Cloud Storage |
| **CDN** | CloudFront / Cloudflare | Content delivery | Fastly, Akamai |
| **Monitoring** | Datadog / New Relic | APM & logging | Grafana + Prometheus |
| **Error Tracking** | Sentry | Error monitoring | Rollbar, Bugsnag |
| **Analytics** | Mixpanel / Amplitude | User analytics | PostHog (self-hosted) |
| **Payment** | Stripe | Subscription billing | PayPal, Paddle |

### Integration Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   NEXT.JS BACKEND                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Integration Service Layer                │  │
│  │                                                  │  │
│  │  ┌────────────┐  ┌────────────┐  ┌───────────┐ │  │
│  │  │   Auth     │  │   Email    │  │    SMS    │ │  │
│  │  │  Service   │  │  Service   │  │  Service  │ │  │
│  │  └────────────┘  └────────────┘  └───────────┘ │  │
│  │                                                  │  │
│  │  ┌────────────┐  ┌────────────┐  ┌───────────┐ │  │
│  │  │   Push     │  │  Storage   │  │  Payment  │ │  │
│  │  │  Service   │  │  Service   │  │  Service  │ │  │
│  │  └────────────┘  └────────────┘  └───────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌──────▼───────┐
│   Google     │  │   Firebase   │  │   SendGrid   │
│   OAuth      │  │     FCM      │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌──────▼───────┐
│    Twilio    │  │     AWS      │  │    Stripe    │
│              │  │      S3      │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

### Firebase Cloud Messaging Setup

```typescript
// Backend: Send push notification
import admin from 'firebase-admin';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function sendPushNotification(
  userId: string,
  notification: {
    title: string;
    body: string;
    data?: Record<string, string>;
  }
) {
  const user = await getUserDeviceTokens(userId);
  
  const message = {
    notification: {
      title: notification.title,
      body: notification.body
    },
    data: notification.data,
    tokens: user.deviceTokens,
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'medication_reminders'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1
        }
      }
    }
  };
  
  const response = await admin.messaging().sendMulticast(message);
  
  // Handle failed tokens
  if (response.failureCount > 0) {
    await handleFailedTokens(response.responses, user.deviceTokens);
  }
  
  return response;
}
```

### Email Service Integration

```typescript
// SendGrid integration
import sgMail from '@sendgrid/mail';

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

async function sendEmail(to: string, template: EmailTemplate) {
  const msg = {
    to,
    from: 'noreply@dastern.com',
    templateId: template.id,
    dynamicTemplateData: template.data,
    trackingSettings: {
      clickTracking: { enable: true },
      openTracking: { enable: true }
    }
  };
  
  await sgMail.send(msg);
}

// Email templates
enum EmailTemplate {
  WELCOME = 'd-xxx',
  CONNECTION_REQUEST = 'd-yyy',
  PRESCRIPTION_UPDATE = 'd-zzz',
  MISSED_DOSE_ALERT = 'd-aaa'
}
```

### Payment Integration (Stripe)

```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16'
});

// Create subscription
async function createSubscription(
  userId: string,
  plan: 'premium' | 'family_premium'
) {
  const customer = await stripe.customers.create({
    metadata: { userId }
  });
  
  const priceId = plan === 'premium' 
    ? process.env.STRIPE_PREMIUM_PRICE_ID
    : process.env.STRIPE_FAMILY_PRICE_ID;
  
  const subscription = await stripe.subscriptions.create({
    customer: customer.id,
    items: [{ price: priceId }],
    payment_behavior: 'default_incomplete',
    expand: ['latest_invoice.payment_intent']
  });
  
  return subscription;
}

// Webhook handler
async function handleStripeWebhook(event: Stripe.Event) {
  switch (event.type) {
    case 'customer.subscription.created':
      await handleSubscriptionCreated(event.data.object);
      break;
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object);
      break;
    case 'customer.subscription.deleted':
      await handleSubscriptionCancelled(event.data.object);
      break;
    case 'invoice.payment_succeeded':
      await handlePaymentSucceeded(event.data.object);
      break;
    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object);
      break;
  }
}
```

---

## 🚀 Deployment Architecture

### Container Architecture

```yaml
# docker-compose.yml
version: '3.8'

services:
  # PostgreSQL Primary
  postgres-primary:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: dastern
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "-E UTF8 --locale=en_US.UTF-8"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    command: >
      postgres
      -c wal_level=replica
      -c max_wal_senders=3
      -c max_replication_slots=3
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # PostgreSQL Read Replica
  postgres-replica:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    depends_on:
      - postgres-primary
    command: >
      bash -c "
      until pg_basebackup -h postgres-primary -D /var/lib/postgresql/data -U replicator -Fp -Xs -P -R; do
        echo 'Waiting for primary to be ready...'
        sleep 5
      done
      postgres
      "

  # Redis Cache
  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 256mb --maxmemory-policy allkeys-lru
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # RabbitMQ Message Queue
  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD}
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  # Next.js API
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres-primary:5432/dastern
      DATABASE_READ_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres-replica:5432/dastern
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      RABBITMQ_URL: amqp://${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@rabbitmq:5672
      NEXTAUTH_SECRET: ${NEXTAUTH_SECRET}
      NEXTAUTH_URL: ${NEXTAUTH_URL}
      GOOGLE_CLIENT_ID: ${GOOGLE_CLIENT_ID}
      GOOGLE_CLIENT_SECRET: ${GOOGLE_CLIENT_SECRET}
    depends_on:
      - postgres-primary
      - redis
      - rabbitmq
    ports:
      - "3000:3000"
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  # Nginx Load Balancer
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - api
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres-data:
  redis-data:
  rabbitmq-data:
```

### Kubernetes Deployment (Production)

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dastern-api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dastern-api
  template:
    metadata:
      labels:
        app: dastern-api
    spec:
      containers:
      - name: api
        image: dastern/api:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: dastern-api-service
  namespace: production
spec:
  selector:
    app: dastern-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
```

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Run security audit
        run: npm audit --audit-level=high

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t dastern/api:${{ github.sha }} .
      
      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push dastern/api:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/dastern-api api=dastern/api:${{ github.sha }}
          kubectl rollout status deployment/dastern-api
```

---

## 📊 Monitoring & Observability

### Monitoring Stack

```
┌─────────────────────────────────────────────────────────┐
│                  MONITORING LAYERS                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Application Performance Monitoring (APM)        │  │
│  │  • Datadog / New Relic                           │  │
│  │  • Request tracing                               │  │
│  │  • Performance metrics                           │  │
│  │  • Database query analysis                       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Error Tracking                                  │  │
│  │  • Sentry                                        │  │
│  │  • Real-time error alerts                        │  │
│  │  • Stack trace analysis                          │  │
│  │  • Release tracking                              │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Infrastructure Monitoring                       │  │
│  │  • Prometheus + Grafana                          │  │
│  │  • CPU, Memory, Disk metrics                     │  │
│  │  • Container health                              │  │
│  │  • Network metrics                               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Log Aggregation                                 │  │
│  │  • ELK Stack (Elasticsearch, Logstash, Kibana)  │  │
│  │  • Centralized logging                           │  │
│  │  • Log search & analysis                         │  │
│  │  • Audit trail                                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Uptime Monitoring                               │  │
│  │  • Pingdom / UptimeRobot                         │  │
│  │  • Endpoint availability                         │  │
│  │  • Response time tracking                        │  │
│  │  • SSL certificate monitoring                    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Key Metrics to Monitor

#### Application Metrics

```typescript
// Custom metrics tracking
import { Counter, Histogram, Gauge } from 'prom-client';

// API request metrics
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

// Business metrics
const prescriptionCreated = new Counter({
  name: 'prescriptions_created_total',
  help: 'Total number of prescriptions created',
  labelNames: ['doctor_id', 'patient_id']
});

const doseEventTracked = new Counter({
  name: 'dose_events_tracked_total',
  help: 'Total number of dose events tracked',
  labelNames: ['status', 'prescription_id']
});

const activeUsers = new Gauge({
  name: 'active_users_total',
  help: 'Number of currently active users',
  labelNames: ['role']
});

// Sync metrics
const syncQueueSize = new Gauge({
  name: 'sync_queue_size',
  help: 'Number of items in sync queue',
  labelNames: ['status']
});
```

#### Database Metrics

- Query performance (slow queries > 1s)
- Connection pool utilization
- Replication lag
- Table sizes and growth
- Index usage statistics

#### Infrastructure Metrics

- CPU utilization (target: < 70%)
- Memory usage (target: < 80%)
- Disk I/O
- Network throughput
- Container restart count

### Alerting Rules

```yaml
# Prometheus alerting rules
groups:
  - name: dastern_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_code=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors/sec"

      # Database connection issues
      - alert: DatabaseConnectionPoolExhausted
        expr: database_connections_active / database_connections_max > 0.9
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Database connection pool nearly exhausted"

      # High response time
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, http_request_duration_seconds) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "95th percentile response time > 2s"

      # Sync queue backup
      - alert: SyncQueueBackup
        expr: sync_queue_size{status="pending"} > 1000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Sync queue has {{ $value }} pending items"
```

### Logging Strategy

```typescript
// Structured logging with Winston
import winston from 'winston';

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { 
    service: 'dastern-api',
    environment: process.env.NODE_ENV
  },
  transports: [
    // Console output
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    // File output
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error' 
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log' 
    })
  ]
});

// Usage
logger.info('User logged in', {
  userId: user.id,
  email: user.email,
  ipAddress: req.ip,
  userAgent: req.headers['user-agent']
});

logger.error('Database query failed', {
  error: error.message,
  stack: error.stack,
  query: sanitizedQuery,
  userId: user.id
});
```

---

## 🔒 Security Checklist

### Pre-Launch Security Audit

- [ ] **Authentication & Authorization**
  - [ ] OAuth 2.0 properly implemented
  - [ ] JWT tokens with short expiry
  - [ ] Refresh token rotation enabled
  - [ ] RBAC/ABAC policies enforced
  - [ ] Session management secure

- [ ] **Data Protection**
  - [ ] Encryption at rest (AES-256)
  - [ ] Encryption in transit (TLS 1.3)
  - [ ] Field-level encryption for sensitive data
  - [ ] Secure key management
  - [ ] Data backup encrypted

- [ ] **API Security**
  - [ ] Rate limiting implemented
  - [ ] Input validation on all endpoints
  - [ ] SQL injection prevention
  - [ ] XSS protection
  - [ ] CSRF protection
  - [ ] Security headers configured

- [ ] **Infrastructure Security**
  - [ ] WAF configured
  - [ ] DDoS protection enabled
  - [ ] Network segmentation
  - [ ] Firewall rules configured
  - [ ] SSH key-based authentication only
  - [ ] Regular security patches

- [ ] **Monitoring & Compliance**
  - [ ] Audit logging enabled
  - [ ] Security event monitoring
  - [ ] Anomaly detection
  - [ ] GDPR compliance
  - [ ] HIPAA compliance (if applicable)
  - [ ] Regular penetration testing

- [ ] **Mobile App Security**
  - [ ] Certificate pinning
  - [ ] Biometric authentication
  - [ ] Secure storage for tokens
  - [ ] Code obfuscation
  - [ ] Root/jailbreak detection
  - [ ] App signing

---

## 📋 Technology Decision Summary

### Why These Technologies?

| Technology | Reason |
|-----------|--------|
| **Flutter** | Single codebase for iOS/Android, excellent offline support, native performance |
| **Next.js** | Full-stack framework, API routes, excellent DX, TypeScript support, easy deployment |
| **PostgreSQL** | ACID compliance, row-level security, JSON support, mature ecosystem |
| **Docker** | Consistent environments, easy deployment, resource isolation |
| **Redis** | Fast caching, session storage, rate limiting, pub/sub for real-time features |
| **RabbitMQ** | Reliable message queuing, async job processing, retry mechanisms |
| **Prisma** | Type-safe ORM, migrations, excellent DX, prevents SQL injection |
| **NextAuth.js** | OAuth integration, session management, secure by default |

---

## 🚦 Deployment Phases

### Phase 1: MVP (Months 1-3)

- ✅ Basic authentication (Google OAuth)
- ✅ Prescription management
- ✅ Dose tracking
- ✅ Local reminders
- ✅ Basic offline support
- ✅ Single server deployment

### Phase 2: Scale (Months 4-6)

- ✅ Doctor/Family connections
- ✅ Real-time notifications
- ✅ Advanced offline sync
- ✅ Read replicas
- ✅ Redis caching
- ✅ Load balancing

### Phase 3: Enterprise (Months 7-12)

- ✅ Multi-region deployment
- ✅ Advanced analytics
- ✅ Compliance certifications
- ✅ White-label options
- ✅ API for third-party integrations
- ✅ Advanced security features

---

## 📞 Architecture Review & Support

For architecture questions or improvements:

- 📧 Email: architecture@dastern.com
- 📚 Documentation: https://docs.dastern.com
- 💬 Slack: #architecture-team

---

<div align="center">

**Built with security, scalability, and user privacy at the core**

[⬆ Back to Top](#-das-tern---system-architecture)

</div>


---

## 🚀 Performance Optimization Strategy

### Overview

Performance is critical for Das Tern to ensure smooth user experience, especially with offline-first architecture and role-based UI.

**Key Goals:**
- App startup < 2 seconds
- API response time (p95) < 200ms
- 60 FPS UI rendering
- Efficient offline sync
- Minimal battery drain

---

### Frontend Performance (Flutter)

#### 1. App Startup Optimization

```dart
// Parallel initialization
class AppInitializer {
  static Future<void> initialize() async {
    await Future.wait([
      _initDatabase(),
      _initSecureStorage(),
      _initNotifications(),
      _loadUserPreferences(),
    ]);
    
    // Preload role-specific data
    final user = await getUser();
    if (user.role == UserRole.patient) {
      await getMedicationsForToday();
    } else if (user.role == UserRole.doctor) {
      await getConnectedPatients(limit: 20);
    }
  }
}
```

#### 2. Role-Based Code Splitting

```dart
// Lazy load UI based on role
class AppRouter {
  static Route onGenerateRoute(RouteSettings settings) {
    final user = getIt<AuthService>().currentUser;
    
    // Only load relevant code for user's role
    if (user.role == UserRole.patient) {
      return MaterialPageRoute(
        builder: (_) => const PatientDashboard(),
      );
    } else if (user.role == UserRole.doctor) {
      return MaterialPageRoute(
        builder: (_) => const DoctorDashboard(),
      );
    }
  }
}
```

#### 3. Efficient List Rendering

```dart
// Optimized medication list for patients
ListView.builder(
  itemCount: medications.length,
  cacheExtent: 500,  // Pre-render nearby items
  itemBuilder: (context, index) {
    final med = medications[index];
    return MedicationCard(
      key: ValueKey(med.id),  // Preserve widget state
      medication: med,
    );
  },
)

// Separate sections to minimize rebuilds
class PatientDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        MorningMedsSection(),    // Independent rebuild
        AfternoonMedsSection(),  // Independent rebuild
        NightMedsSection(),      // Independent rebuild
      ],
    );
  }
}
```

#### 4. Image Optimization

```dart
// Cached images with compression
CachedNetworkImage(
  imageUrl: medication.imageUrl,
  memCacheWidth: 200,
  memCacheHeight: 200,
  maxWidthDiskCache: 400,
  maxHeightDiskCache: 400,
  placeholder: (context, url) => const ShimmerPlaceholder(),
  errorWidget: (context, url, error) => const DefaultIcon(),
)
```

#### 5. Smart Caching

```dart
// Multi-level cache
class CacheManager {
  final _memoryCache = <String, CacheEntry>{};
  final _diskCache = HiveBox('cache');
  
  Future<T?> get<T>(String key) async {
    // Memory cache (fastest)
    final memEntry = _memoryCache[key];
    if (memEntry != null && !memEntry.isExpired) {
      return memEntry.value as T;
    }
    
    // Disk cache
    final diskEntry = await _diskCache.get(key);
    if (diskEntry != null && !diskEntry.isExpired) {
      _memoryCache[key] = diskEntry;  // Promote to memory
      return diskEntry.value as T;
    }
    
    return null;
  }
}
```

#### 6. Network Request Optimization

```dart
// Request deduplication
class ApiClient {
  final Map<String, Future> _pendingRequests = {};
  
  Future<T> get<T>(String endpoint) async {
    // Prevent duplicate requests
    if (_pendingRequests.containsKey(endpoint)) {
      return _pendingRequests[endpoint] as Future<T>;
    }
    
    final request = _makeRequest<T>(endpoint);
    _pendingRequests[endpoint] = request;
    
    try {
      return await request;
    } finally {
      _pendingRequests.remove(endpoint);
    }
  }
}
```

---

### Backend Performance (Next.js)

#### 1. Response Compression

```typescript
import compression from 'compression';

app.use(compression({
  level: 6,
  threshold: 1024,  // Only compress > 1KB
}));
```

#### 2. Database Query Optimization

```typescript
// Select only needed fields
await prisma.prescription.findMany({
  where: { patientId: userId, status: 'active' },
  select: {
    id: true,
    medicationName: true,
    dosage: true,
    schedule: true,
  },
  take: 20,
});

// Prevent N+1 queries
const patients = await prisma.user.findMany({
  where: { role: 'patient' },
  include: {
    prescriptions: {
      where: { status: 'active' },
      take: 10,
    },
  }
});
```

#### 3. Redis Caching

```typescript
class CacheService {
  async getOrSet<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl: number = 300
  ): Promise<T> {
    const cached = await this.redis.get(key);
    if (cached) return JSON.parse(cached);
    
    const data = await fetcher();
    await this.redis.setex(key, ttl, JSON.stringify(data));
    return data;
  }
}

// Usage
const prescriptions = await cacheService.getOrSet(
  `prescriptions:${userId}`,
  () => prisma.prescription.findMany({ where: { patientId: userId } }),
  300  // 5 minutes
);
```

#### 4. Background Jobs

```typescript
// Offload heavy tasks to queue
const notificationQueue = new Queue('notifications');

await notificationQueue.add('send-missed-dose-alert', {
  patientId: patient.id,
  familyIds: family.map(f => f.id),
}, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 2000 },
});
```

#### 5. Cursor-Based Pagination

```typescript
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const cursor = searchParams.get('cursor');
  const limit = 20;
  
  const items = await prisma.prescription.findMany({
    take: limit + 1,
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    orderBy: { createdAt: 'desc' },
  });
  
  const hasMore = items.length > limit;
  const results = hasMore ? items.slice(0, -1) : items;
  const nextCursor = hasMore ? results[results.length - 1].id : null;
  
  return Response.json({ items: results, nextCursor, hasMore });
}
```

---

### Database Performance

#### 1. Strategic Indexing

```sql
-- Common query patterns
CREATE INDEX idx_prescriptions_patient_status 
  ON prescriptions(patient_id, status) 
  WHERE status = 'active';

CREATE INDEX idx_dose_events_scheduled 
  ON dose_events(prescription_id, scheduled_time) 
  WHERE status IN ('due', 'missed');

CREATE INDEX idx_connections_target_status 
  ON connections(target_id, status) 
  WHERE status = 'accepted';
```

#### 2. Materialized Views

```sql
-- Pre-compute adherence statistics
CREATE MATERIALIZED VIEW patient_adherence_summary AS
SELECT 
  p.patient_id,
  COUNT(CASE WHEN de.status = 'taken_on_time' THEN 1 END) * 100.0 / 
    NULLIF(COUNT(de.id), 0) as adherence_rate,
  COUNT(CASE WHEN de.status = 'missed' THEN 1 END) as missed_count
FROM prescriptions p
LEFT JOIN dose_events de ON de.prescription_id = p.id
WHERE de.scheduled_time > NOW() - INTERVAL '30 days'
GROUP BY p.patient_id;

-- Refresh periodically (cron job)
REFRESH MATERIALIZED VIEW CONCURRENTLY patient_adherence_summary;
```

#### 3. Connection Pooling

```typescript
// PgBouncer configuration
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

// DATABASE_URL=postgresql://user:pass@pgbouncer:6432/dastern?pgbouncer=true
```

---

### Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| **App Startup** | < 2s | < 3s |
| **API Response (p95)** | < 200ms | < 500ms |
| **Database Query (p95)** | < 50ms | < 100ms |
| **Cache Hit Rate** | > 80% | > 60% |
| **Sync Latency** | < 5s | < 10s |
| **UI Frame Rate** | 60 FPS | 30 FPS |

---

### Performance Monitoring

```typescript
// Track key metrics
const metrics = {
  'app.startup.time': 'Time to interactive',
  'api.response.time': 'API response time (p50, p95, p99)',
  'db.query.time': 'Database query time',
  'cache.hit.rate': 'Cache hit rate %',
  'ui.render.time': 'Component render time',
};
```

---

## 🎨 Role-Based UI Architecture

### Single App, Multiple Interfaces

Das Tern uses **one Flutter app** that dynamically loads UI based on user role.

```
┌─────────────────────────────────────────────────────────┐
│                    LOGIN SCREEN                         │
└────────────────────┬────────────────────────────────────┘
                     │
              Fetch User Profile
                     │
         ┌───────────┴───────────┐
         │                       │
    Role: Patient          Role: Doctor
         │                       │
┌────────▼────────┐      ┌───────▼────────┐
│  Patient UI     │      │   Doctor UI    │
│                 │      │                │
│ • Time-based    │      │ • Patient list │
│   schedule      │      │ • Adherence    │
│ • Morning/      │      │   tracking     │
│   Afternoon/    │      │ • Prescription │
│   Night meds    │      │   management   │
│ • Calendar      │      │ • Analytics    │
│ • Quick "Taken" │      │ • Urgent       │
│   button        │      │   updates      │
└─────────────────┘      └────────────────┘
```

### Patient Interface Features

**Time-Based Organization:**
- ☀️ Morning Meds (Blue theme)
- 🌤️ Afternoon Meds (Orange theme)
- 🌙 Night Meds (Dark/Purple theme)

**Quick Actions:**
- One-tap "Taken" button
- Medication cards with images
- Calendar view for adherence
- Offline mode indicator

### Doctor Interface Features

**Patient Management:**
- Connected patients list
- Color-coded adherence indicators (🟢 🟡 🔴)
- Pending connection requests
- Patient detail views

**Prescription Management:**
- Normal prescription edits
- ⚡ Urgent updates (auto-apply)
- Version history
- Analytics dashboard

### Shared Features

Both roles have access to:
- Connections management
- Notifications
- Settings
- Profile

---

## 📱 Offline-First Implementation

### Local Storage Strategy

```
┌─────────────────────────────────────────────────────────┐
│  SQLite Database (Drift)                                │
│  • users, prescriptions, dose_events                    │
│  • connections, sync_queue, audit_logs_cache            │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│  Secure Storage                                         │
│  • JWT tokens, encryption keys, biometric tokens        │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│  Shared Preferences                                     │
│  • User preferences, app settings, last sync time       │
└─────────────────────────────────────────────────────────┘
```

### Sync Strategy

```dart
class SyncManager {
  Future<void> syncIfNeeded() async {
    if (!await connectivity.hasConnection) return;
    
    final lastSync = await getLastSyncTime();
    if (DateTime.now().difference(lastSync) < Duration(minutes: 2)) {
      return;
    }
    
    // Batch sync operations
    await Future.wait([
      syncMedications(),
      syncDoseEvents(),
      syncConnections(),
    ]);
  }
}
```

---

## 🎯 Summary

### Architecture Highlights

1. **Single Flutter App** with role-based UI (Patient/Doctor)
2. **Offline-First** with local SQLite database
3. **Next.js Backend** with REST + GraphQL APIs
4. **PostgreSQL** in Docker with read replicas
5. **Google OAuth** + JWT authentication
6. **Redis** for caching and rate limiting
7. **RabbitMQ** for async job processing
8. **Multi-layer security** with encryption at rest and in transit
9. **Horizontal scaling** with load balancers
10. **Comprehensive monitoring** and performance tracking

### Performance Optimizations

- Lazy loading and code splitting
- Multi-level caching (Memory → Disk → Redis → DB)
- Database indexing and query optimization
- Request deduplication and batching
- Background job processing
- CDN for static assets
- Connection pooling

### Security Features

- OAuth 2.0 + JWT with refresh token rotation
- Field-level encryption for sensitive data
- Row-level security in PostgreSQL
- Rate limiting at multiple layers
- WAF + DDoS protection
- Comprehensive audit logging
- Certificate pinning in mobile app

---

<div align="center">

**Optimized for performance, built for scale, secured by design**

[⬆ Back to Top](#-das-tern---system-architecture)

</div>
