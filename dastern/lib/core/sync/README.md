# Sync engine

> Spec: [`00-overview/design.md`](../../../../.kiro/specs-v2-flutter-supabase/00-overview/design.md) §"Sync engine"
>
> Tasks: Phase 3 (Local storage + sync foundation).

The `SyncEngine` is the only component that writes to Supabase. It owns:

1. **Outbox draining** — drain queued ops on startup and on connectivity restore.
2. **Conflict resolution** — server `updated_at` wins, with the explicit
   exceptions documented in the spec (dose events local-wins;
   prescriptions doctor-wins).
3. **Realtime ingest** — subscribe to Supabase Realtime channels for visible
   tables and merge incoming rows into Drift.
4. **Backoff** — exponential (1s → 2s → 4s … capped 60s, max 5 attempts).

Stub providers will land here in the sync-foundation task. Until then, no
mutation is possible — that's intentional, since the data layer also isn't
wired yet.
