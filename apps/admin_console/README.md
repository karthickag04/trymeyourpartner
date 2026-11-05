# TryMeYourPartner admin console

Flutter Web app for staff: system admins, super admins, admins, branch managers,
team leads, staff and agents. Sign-in is email + password, then an authenticator
app code (TOTP); every staff page needs that MFA-verified session.

See [`docs/ADMIN_CONSOLE.md`](../../docs/ADMIN_CONSOLE.md) for roles, sign-in and
how to create the first system admin.

## Configure and run

```bash
cd apps/admin_console
cp .env.example .env          # set SUPABASE_KEY to the publishable key
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

## Check

```bash
tool/check_vendor_imports.sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --dart-define-from-file=.env --no-web-resources-cdn
```

## Layout

| Path | What it holds |
|---|---|
| `lib/src/services/` | `ConsoleAuth` (sign-in, MFA) and `ConsoleData` interfaces; the rest of the app depends only on these |
| `lib/data/supabase/` | Their Supabase implementations: the only place that imports `supabase_flutter` (ADR 0001, checked by `tool/check_vendor_imports.sh` in CI) |
| `lib/src/session/` | Sign-in flow: password → staff check → TOTP enrol/verify |
| `lib/src/navigation.dart` | Console sections and the permission each needs |
| `lib/src/screens/` | Sign-in, MFA, refusal, dashboard, staff list, roles & permissions, settings |
| `test/` | Widget tests with an in-memory backend (no network) |
