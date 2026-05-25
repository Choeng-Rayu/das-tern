# Das Tern v2 — Flutter + Supabase Specs

> **Spec set for the Das Tern medication-management platform, rebuilt as a single Flutter codebase with Supabase as the managed backend and Google Play Billing for monetization.**

> ⚠️ **Read [`ADDENDUM-001-account-and-connection-refinement.md`](./ADDENDUM-001-account-and-connection-refinement.md) first.** It refines the account model (two roles only — Patient and Doctor) and the connection model (QR scan only, mutual Patient↔Patient peer connections replace v1's "family member" role). Affected specs have been updated inline.

---

## 1. What is this spec set?

This is the **v2** specification for the Das Tern platform. It replaces the v1 multi-service architecture (NestJS backend + PostgreSQL + Bakong Payment service + Python OCR service + AI/LLM service + Flutter app) with a single Flutter application that uses **Supabase** (Postgres, Auth, Storage, Edge Functions, Realtime) as its managed backend, **Google Play Billing** for subscriptions, and a hybrid OCR strategy (on-device + Edge Function cloud fallback).

The v1 specs in `.kiro/specs/` remain intact as historical reference. The v2 specs in `.kiro/specs-v2-flutter-supabase/` are the source of truth for new work.

## 2. Why this stack?

| Concern | v1 stack | v2 stack | Win |
|---|---|---|---|
| App | Flutter | Flutter | Same |
| API | NestJS (custom) | Supabase auto-generated REST + RLS | No backend code to maintain for CRUD |
| DB | Postgres + Prisma | Supabase Postgres (same engine) | Migration path is straightforward |
| Auth | Custom JWT, Google OAuth, Telegram OIDC | Supabase Auth (Google, Apple, Email, Telegram via OIDC) | Battle-tested, MFA built-in |
| Realtime | None | Supabase Realtime channels + `.stream()` | Live peer-Patient/doctor dashboards |
| Storage | Local filesystem | Supabase Storage with RLS | Per-user file access enforced by policy |
| Background server logic | NestJS workers | Supabase Edge Functions (Deno) | Pay-per-invocation, no infra |
| Payment | Bakong (KHQR) | Google Play Billing + Edge Function verifier | Native subscription UX, App Store path ready |
| OCR | Python kiri_ocr microservice | On-device ML Kit + Tesseract (Khmer) + Edge Function → Cloud Vision fallback | No always-on OCR service to run |
| Operational surface | 4 services + nginx + docker-compose | 1 Flutter app + Supabase project | Major reduction |

**Trade-offs we accept:**
- We are coupled to Supabase as a vendor. Mitigated by the fact that the Postgres schema is portable (we own all SQL migrations), Edge Functions are plain Deno HTTP handlers, and Storage is S3-compatible.
- Edge Functions cold-start. Mitigated by keeping verification/webhook logic minimal and using on-device computation wherever possible.
- Google Play Billing on Android first; iOS App Store via the same `in_app_purchase` plugin in a follow-up phase.

## 3. Spec folders (read in this order)

| # | Folder | Purpose |
|---|---|---|
| 00 | `00-overview/` | Architecture, tech stack, project structure, agent-skills setup, monorepo layout |
| 01 | `01-supabase-data-layer/` | Postgres schema (SQL), RLS policies, storage buckets, migrations strategy |
| 02 | `02-authentication/` | Supabase Auth flows (Email OTP, Google native, Apple native, Telegram OIDC), profile bootstrap, role assignment |
| 03 | `03-prescription-medication/` | Prescription + medication CRUD, versioning, urgent-apply, draft → active → paused → inactive lifecycle |
| 04 | `04-reminder-adherence/` | Local notifications, offline-first reminder schedule, dose tracking, adherence calculation, sync queue |
| 05 | `05-family-doctor-connections/` | **QR-only** connections (Patient↔Patient mutual + Doctor↔Patient asymmetric), permission levels, peer check-in, missed-dose alerts via Realtime + push |
| 06 | `06-doctor-dashboard/` | Doctor patient list, adherence indicators, prescription authoring, doctor notes, urgent auto-apply |
| 07 | `07-ocr-prescription-scanning/` | Hybrid OCR pipeline (ML Kit Latin → Tesseract Khmer → Cloud Vision Edge Function fallback), confidence routing, prescription draft generation |
| 08 | `08-google-play-billing/` | `in_app_purchase` plugin integration, server-side verification via Edge Function, RTDN webhook, subscription state machine, family-plan member management |
| 09 | `09-design-system-localization/` | Bilingual (Khmer/English) i18n, light/dark theme, design tokens, reusable widget catalog |

Each folder contains:
- `requirements.md` — User stories + EARS-style acceptance criteria
- `design.md` — Architecture, components, data flow, code patterns
- `tasks.md` — Implementation roadmap with checkpoints

## 4. Source-of-truth principles

These rules apply across every spec in v2.

1. **Patient owns the data.** All viewing/editing by a Doctor or by another Patient (peer / "family") is gated by an explicit, revocable Connection with a `permission_level` set by the patient. Enforced in Postgres via RLS. Per **ADDENDUM-001**, there are only two account roles — `PATIENT` and `DOCTOR` — and "family" is a Patient↔Patient peer connection rather than a separate role.
2. **Offline-first.** Every patient-facing action (create prescription, mark dose taken, snooze reminder) must work offline and sync later. Reminders fire from the device, not the server.
3. **No mutating server logic for CRUD.** Mutations go directly Flutter → Supabase Postgres through RLS-protected tables. Edge Functions only exist for what cannot be safely done from a client: payment verification, OCR proxy with privileged credentials, RTDN webhook ingest, scheduled jobs.
4. **Audit everything.** Every connection change, dose event, prescription change, and data access produces an `audit_logs` row, written by RLS-enforced triggers, never by the client directly.
5. **Bilingual + themed by default.** Every screen ships with Khmer + English strings and supports light/dark before merge.
6. **Cambodia timezone (Asia/Phnom_Penh) is the canonical reminder timezone.** Stored as user preference with default fallback to device timezone.

## 5. Agent skills setup

Per the [Flutter Agent Skills guide](https://docs.flutter.dev/ai/agent-skills), this project uses official Flutter and Dart skills installed under `.agents/skills/` to give AI coding assistants domain expertise.

```bash
# Install official Flutter skills
npx skills add flutter/skills --skill '*' --agent universal

# Install official Dart skills
npx skills add dart-lang/skills --skill '*' --agent universal
```

The skills directory is committed to the repo so every developer/agent gets the same blueprints. See `00-overview/design.md` § "Agent skills" for the full list and project-specific custom skills.

## 6. v1 → v2 migration map

For every v1 spec, here's where its content lives in v2:

| v1 spec | v2 destination | Notes |
|---|---|---|
| `das-tern-backend-api/` | **Removed.** | Supabase auto-REST + Edge Functions replace this entirely. CRUD endpoints become RLS-protected table operations. |
| `das-tern-backend-database/` | `01-supabase-data-layer/` | Schema preserved (same Postgres). Prisma models become SQL migrations. RLS replaces application-level authorization. |
| `telegram-authentication/` | `02-authentication/` § "Telegram OIDC" | OIDC PKCE flow preserved; ID-token verification done in Edge Function `auth-telegram` instead of NestJS. |
| `patient-role-management/` | `03-prescription-medication/` + `04-reminder-adherence/` + `05-family-doctor-connections/` | Split by concern. |
| `reminder-system-adherence-tracking/` | `04-reminder-adherence/` | Server-side reminder queue removed. Local notifications + offline schedule become primary. Adherence calc moves to a Postgres view. |
| `family-connection-missed-dose-alert/` | `05-family-doctor-connections/` | Connection-token table preserved. Nudge moves to Realtime channel + local notification. |
| `doctor-dashboard/` | `06-doctor-dashboard/` | Same UX, queries via RLS-protected views. |
| `ocr-prescription-scanning/` | `07-ocr-prescription-scanning/` | Python kiri_ocr microservice removed. Replaced with on-device ML Kit (Latin) + Tesseract (Khmer) + Edge Function → Google Cloud Vision (handwriting / low-confidence fallback). |
| `bakong-payment` (in v1 docs) | `08-google-play-billing/` | Bakong replaced by Google Play Billing for store-policy compliance. Bakong path can be reintroduced as a side channel for KHR top-ups in a later phase. |
| `global-widget-system-design/` | `09-design-system-localization/` | Carries over with minor cleanup. |
| `ios26-liquid-glass-refactor/` | Folded into `09-design-system-localization/` § "Visual language" | Optional / aesthetic, not blocking MVP. |

## 7. Out of scope for v2 MVP

- AI/LLM medication recommendations (the v1 `ai-llm-service` is parked; OCR-extracted text goes into a structured form, not into an LLM).
- iOS App Store Connect billing (Android Google Play first; iOS uses the same `in_app_purchase` plugin and unlocks with a separate app-store build).
- Bakong KHQR top-ups (Cambodia-local payment can be added as an alternative tier later via a separate edge function and a `payment_provider` column on `subscriptions`).
- Health vitals + vital thresholds + health alerts (Prisma schema includes them; v2 keeps the tables for forward compatibility but defers the UI/logic).

## 8. Reading order for a new contributor

1. `00-overview/design.md` — get the architecture in your head.
2. `01-supabase-data-layer/design.md` — understand the data model and RLS.
3. `02-authentication/design.md` — sign-up + sign-in flow.
4. `03-prescription-medication/` and `04-reminder-adherence/` — the core patient app.
5. `08-google-play-billing/` — monetization.
6. Everything else as it becomes relevant.

---

**Version:** 2.0.0-spec
**Status:** Draft (ready for implementation kickoff)
**Owner:** Das Tern engineering
