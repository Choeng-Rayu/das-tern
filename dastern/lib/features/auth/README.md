# Feature: auth

> Spec: [`.kiro/specs-v2-flutter-supabase/02-authentication/`](../../../../.kiro/specs-v2-flutter-supabase/02-authentication/)

Authentication flows — sign-up + sign-in via:
- Google native (`google_sign_in` + `signInWithIdToken`)
- Telegram OIDC PKCE (Edge Function `auth-telegram`)
- Email/phone + password (Supabase Auth)

Roles: `PATIENT` and `DOCTOR` (per `ADDENDUM-001`). Apple Sign-In is iOS-phase.

## Folder layout (when implemented)

```
auth/
├── data/
│   ├── auth_repository.dart           # Supabase + secure storage
│   └── auth_repository_impl.dart
├── domain/
│   ├── auth_user.dart                 # freezed entity (id, role, email, ...)
│   └── auth_failure.dart
└── presentation/
    ├── welcome_page.dart              # role selection
    ├── sign_in_page.dart              # 3 methods
    ├── sign_up_page.dart
    ├── otp_verify_page.dart
    └── widgets/
```
