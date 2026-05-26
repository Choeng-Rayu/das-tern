# docs/SECRETS.md — Required secrets by environment

> **Key names only. Never commit values.**
> Store values in your team's secret manager (1Password, AWS Secrets Manager, etc.)
> and inject them via GitHub Actions secrets or local `.env` files (gitignored).

---

## Flutter app (`--dart-define`)

| Key | Environments | Description |
|---|---|---|
| `SUPABASE_URL` | dev, staging, prod | Supabase project URL (e.g. `https://xyz.supabase.co`) |
| `SUPABASE_ANON_KEY` | dev, staging, prod | Supabase public anon key — safe to ship in the app |
| `APP_ENV` | dev, staging, prod | One of `dev`, `staging`, `prod` |
| `SENTRY_DSN` | staging, prod | Sentry DSN for crash reporting (omit in dev) |

## GitHub Actions secrets

| Secret | Used by | Description |
|---|---|---|
| `SUPABASE_ACCESS_TOKEN` | `supabase-staging-deploy.yml` | Supabase CLI personal access token |
| `SUPABASE_PROJECT_REF_STAGING` | `supabase-staging-deploy.yml` | Staging project reference ID |
| `SUPABASE_URL_STAGING` | `flutter-ci.yml` | Staging Supabase URL |
| `SUPABASE_ANON_KEY_STAGING` | `flutter-ci.yml` | Staging anon key |
| `SUPABASE_URL_PROD` | `android-release.yml` | Production Supabase URL |
| `SUPABASE_ANON_KEY_PROD` | `android-release.yml` | Production anon key |
| `SENTRY_DSN` | `android-release.yml` | Sentry DSN |
| `KEYSTORE_BASE64` | `android-release.yml` | Base64-encoded Android release keystore |
| `KEY_STORE_PASSWORD` | `android-release.yml` | Keystore password |
| `KEY_ALIAS` | `android-release.yml` | Key alias |
| `KEY_PASSWORD` | `android-release.yml` | Key password |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | `android-release.yml` | Google Play service account JSON (plain text) |

## Supabase Edge Function secrets

Set via `supabase secrets set KEY=value --project-ref <ref>`.

| Key | Function | Description |
|---|---|---|
| `TELEGRAM_BOT_CLIENT_ID` | `auth-telegram` | Telegram OAuth app client ID |
| `TELEGRAM_BOT_CLIENT_SECRET` | `auth-telegram` | Telegram OAuth app client secret |
| `SUPABASE_SERVICE_ROLE_KEY` | `auth-telegram` | Supabase service role key (server-side only) |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | `google-play-verify`, `google-play-rtdn` | Google Play service account JSON |
| `RTDN_AUTH_HEADER` | `google-play-rtdn` | Authorization header value for RTDN webhook |
| `GCP_VISION_API_KEY` | `ocr-cloud-vision` | Google Cloud Vision API key |

## Local development

Copy `.env.example` to `.env` (gitignored) and fill in local values:

```bash
cp .env.example .env
```

Then pass them to `flutter run`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=$(grep SUPABASE_URL .env | cut -d= -f2) \
  --dart-define=SUPABASE_ANON_KEY=$(grep SUPABASE_ANON_KEY .env | cut -d= -f2) \
  --dart-define=APP_ENV=dev
```

Or use the VS Code launch configuration in `.vscode/launch.json`.
