# TryMeYourPartner

Matrimony platform for the Tamil and wider Indian diaspora. One Flutter codebase for
Android, iOS and Web, on a Supabase backend (Postgres, Auth, Storage, Realtime).

- Product strategy, gap analysis and the phased plan: [`docs/PRODUCT_STRATEGY_AND_ROADMAP.md`](docs/PRODUCT_STRATEGY_AND_ROADMAP.md)
- **What's done and what's next:** [`docs/PROGRESS_TRACKER.md`](docs/PROGRESS_TRACKER.md)
- Backend API: [`backend/README.md`](backend/README.md)
- Staying portable away from Supabase: [`docs/adr/0001-vendor-portability.md`](docs/adr/0001-vendor-portability.md)
- Database migrations and how to apply them: [`supabase/README.md`](supabase/README.md)
- Browser end-to-end tests: [`e2e/README.md`](e2e/README.md)

## Requirements

- Flutter **3.32.8** (the version in `.metadata`; newer versions do not build the locked packages)
- A Supabase project with the migrations in `supabase/migrations/` applied

## Configure

The app reads its settings at build time from a `.env` file (never committed):

```bash
cp .env.example .env
```

Then set `SUPABASE_KEY` to the project's **publishable** key (`sb_publishable_…`, Supabase
dashboard → Settings → API Keys). Never use the secret key in the app.

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

On Windows, `run_app.bat` does the same.

## Check

```bash
flutter analyze
flutter test
flutter build web --dart-define-from-file=.env
```

## Theming and languages

**Design tokens.** Colours, spacing, radii and text styles live in
`lib/shared/theme/`. `tokens.dart` defines the brand colour roles
(`AppPalette`, with a light and a dark value for each), spacing and radius
constants (`AppDimensions`), and shorthands for widgets:
`context.palette.textSecondary`, `context.colors.primary`,
`context.styles.body2`. `theme.dart` builds the light and dark `ThemeData`
from them. Screens should not use raw `Color(...)`, `Colors.*` or
`TextStyle(fontSize: ...)`; add a token instead. Every text colour token must
keep a 4.5:1 contrast ratio against the backgrounds in both themes, and
`test/theme_tokens_test.dart` fails if it does not.

**Theme and language choice.** `lib/app/preferences/user_preferences.dart`
holds the member's theme mode (System / Light / Dark) and language, saved on
the device. Members change them under Profile → Settings; the language can
also be picked on the sign-in and registration screens. Without a choice the
app uses the admin's default language (`AppSettings.defaultLocale`).

**Translations.** Every user-visible string is in `lib/l10n/app_en.arb`
(English, the template) and `lib/l10n/app_ta.arb` (Tamil). To add one:

1. Add the key to both ARB files (placeholders and plurals use ICU syntax; see
   `profilesFound` for a plural).
2. Run `flutter gen-l10n` (also runs on `flutter pub get`); the generated
   `app_localizations*.dart` files are committed.
3. Use it as `context.l10n.yourKey` (import `lib/l10n/l10n.dart`).

Format dates and numbers with `lib/l10n/formatters.dart`
(`context.formatDate`, `context.relativeTime`, `context.formatNumber`) so they
follow the language. Fixed option values (religion, marital status, gender
and similar) stay in English in the database; show them with
`context.optionLabel(value)` from `lib/l10n/option_labels.dart`. Tamil text
uses the Noto Sans Tamil font (via google_fonts).

## Project layout

| Path | What it holds |
|---|---|
| `lib/app/` | App setup: Supabase config, dependency injection, settings, theme and language preferences |
| `lib/l10n/` | Translations (ARB files), generated localizations, date/number formatters |
| `lib/features/<feature>/` | Screens, state and widgets per feature: `auth`, `onboarding`, `home`, `profile`, `discovery`, `interests`, `chat`, `notifications`, `subscriptions` |
| `lib/shared/` | Code used by several features: models, theme, shared state and services, widgets |
| `lib/core/services/` | Backend-neutral service interfaces |
| `lib/data/supabase/`, `lib/data/http/` | Supabase and HTTP implementations of those interfaces (see `docs/BACKEND_SWITCH.md`) |
| `supabase/migrations/` | Versioned database changes, applied in order |
| `supabase/tests/` | SQL checks of the access rules |
| `archive/` | Superseded SQL scripts kept for reference (the baseline migration replaces them) |
| `backend/api/` | NestJS backend API (Supabase token auth, OpenAPI at `/docs`) |
| `e2e/` | Playwright tests that drive the web build |
| `docs/` | Product and architecture documents |
