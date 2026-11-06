#!/usr/bin/env bash
# Enforces docs/adr/0001-vendor-portability.md rules 1 and 2 for backend/api:
# provider code lives in src/supabase/ only. Files listed below are legacy
# exceptions; P2-10 moved data access to src/db, and the rest goes when
# tokens are verified by JWKS only (owner step: asymmetric JWT keys);
# these lists must only shrink.
set -euo pipefail
cd "$(dirname "$0")/../backend/api"

# Files outside src/supabase/ that use the Supabase client directly. Data goes
# through src/db (P2-10); only token checks in "provider" mode remain.
CLIENT_USERS=(
  src/admin/admin.module.ts  # provides SupabaseClient to TokenVerifier
  src/app.module.ts          # provides SupabaseClient to TokenVerifier
  src/auth/token-verifier.ts # "provider" mode until the project has asymmetric JWT keys
)
# Files outside src/supabase/ that name Supabase endpoints (/rest/v1, /auth/v1 …).
ENDPOINT_USERS=(
  src/auth/token-verifier.ts # "provider" verification mode, documented fallback
  src/config.ts              # default token issuer when JWT_ISSUER is not set
)

bad=0
outside() { grep -rlE "$1" src test --include=*.ts | grep -v '^src/supabase/' | sort || true; }

while IFS= read -r f; do
  [ -z "$f" ] && continue
  echo "Not allowed: $f imports a Supabase package. Provider code belongs in src/supabase/."
  bad=1
done < <(outside "from '@supabase/|require\('@supabase/")

while IFS= read -r f; do
  [ -z "$f" ] && continue
  case " ${CLIENT_USERS[*]} " in *" $f "*) continue ;; esac
  case "$f" in test/*) continue ;; esac
  echo "Not allowed: $f uses the Supabase client directly. Depend on our own interface instead (P2-10)."
  bad=1
done < <(outside "from '(\.\./|\./)+supabase/")

while IFS= read -r f; do
  [ -z "$f" ] && continue
  case " ${ENDPOINT_USERS[*]} " in *" $f "*) continue ;; esac
  case "$f" in test/*) continue ;; esac
  echo "Not allowed: $f names a Supabase endpoint. Keep provider URLs in src/supabase/."
  bad=1
done < <(outside "/(rest|auth|storage|realtime|functions)/v1")

if grep -qE '"@supabase/' package.json; then
  echo "Not allowed: package.json depends on a Supabase package (ADR 0001 rule 2: the API talks to PostgreSQL)."
  bad=1
fi

[ $bad -eq 0 ] && echo "API vendor check passed (${#CLIENT_USERS[@]} legacy client users, ${#ENDPOINT_USERS[@]} endpoint mentions left)."
exit $bad
