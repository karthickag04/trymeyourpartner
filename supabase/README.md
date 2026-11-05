# Database migrations

Migrations in `migrations/` are plain SQL, named `<timestamp>_<description>.sql`, and
safe to run more than once. Apply them in timestamp order.

## Applying a migration

1. Open the Supabase dashboard → **SQL Editor** for the **staging** project.
2. Paste the migration file and run it. Check the app against staging.
3. Repeat on the production project.

With the Supabase CLI linked to a project, `supabase db push` applies pending files.

## History

| Migration | What it does |
|---|---|
| `20261105120000_phase0_security_hardening.sql` | Phase 0 fixes from `docs/PRODUCT_STRATEGY_AND_ROADMAP.md` §2: no anonymous access to member data, no self-granted verification/plans, server-side contact reveal with quota, caller checks on delete/restore, email no longer copied into the shared profile row. |

The older scripts in `sql/`, `archive/sql/` and the root `supabase_*.sql` files describe how
the current schema was built. Phase 1 replaces them with a baseline migration.
