# Local storage — Drift (SQLite)

> Spec: [`00-overview/design.md`](../../../../../.kiro/specs-v2-flutter-supabase/00-overview/design.md) §"Local DB"
>
> Tasks: `0-overview/tasks.md` Phase 3 (Local storage + sync foundation).

This folder is intentionally empty until the sync-foundation task lands.
At that point the team will add:

- `app_database.dart` — `AppDatabase` extending `_$AppDatabase`
- `tables/outbox.dart` — `OutboxEntries` table
- `tables/...` — one Drift table per Postgres table the app caches
- `daos/outbox_dao.dart`
- `daos/...`

Drift's code generation (`drift_dev`) regenerates `app_database.g.dart` —
that file is **committed** so CI builds don't run codegen by default.
