# Secure storage

> Spec: [`00-overview/design.md`](../../../../../.kiro/specs-v2-flutter-supabase/00-overview/design.md) §Requirement 7

Wraps `flutter_secure_storage` for:

- Supabase session token (`access_token`, `refresh_token`)
- Any client-side encryption keys (e.g., for outbox payloads if encrypted at rest)

Keys never leave secure storage. The wrapper is added in the auth task
(`02-authentication`).
