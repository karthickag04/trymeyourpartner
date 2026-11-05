#!/usr/bin/env bash
# Enforces docs/adr/0001-vendor-portability.md rule 4 for database migrations:
# Supabase-managed objects appear only inside marked blocks, so a new provider
# can skip or replace exactly those lines.
#
#   -- [supabase-only]
#   alter publication supabase_realtime add table public.messages;
#   -- [/supabase-only]
#
# Use public.app_current_user_id() instead of auth.uid(), and link to our own
# tables instead of auth.users.
set -euo pipefail
cd "$(dirname "$0")/.."

# Applied before this check existed. Applied migrations are never edited
# (AGENTS.md rule 3), so these stay exempt; no new names may be added.
LEGACY=(
  20261105000000_baseline.sql
  20261105120000_phase0_security_hardening.sql
  20261106090000_app_settings.sql
  20261106095000_app_identity_helper.sql
  20261106096000_use_app_identity_helper.sql
  20261106100000_phase2_org_and_roles.sql
)

E='([^a-z0-9_]|$)'
PATTERN="auth\\.(uid|jwt|role|email)[[:space:]]*\\(|auth\\.(users|identities|sessions|mfa_[a-z_]+)$E|storage\\.(objects|buckets)$E|supabase_realtime|realtime\\.[a-z_]+|pgsodium|vault\\.[a-z_]+|net\\.http_[a-z]+|supabase_functions|graphql\\.[a-z_]+"

bad=0
DIR="${MIGRATIONS_DIR:-supabase/migrations}"
for f in "$DIR"/*.sql; do
  name=$(basename "$f")
  case " ${LEGACY[*]} " in *" $name "*) continue ;; esac
  hits=$(PAT="$PATTERN" awk '
    BEGIN { pat = ENVIRON["PAT"] }
    /^[[:space:]]*--[[:space:]]*\[supabase-only\]/  { inblock = 1; next }
    /^[[:space:]]*--[[:space:]]*\[\/supabase-only\]/ { inblock = 0; next }
    {
      line = $0
      sub(/--.*/, "", line)
      if (!inblock && tolower(line) ~ pat) printf "%s:%d: %s\n", FILENAME, FNR, $0
    }
    END { if (inblock) printf "%s: [supabase-only] block is not closed\n", FILENAME }
  ' "$f")
  if [ -n "$hits" ]; then
    echo "$hits"
    bad=1
  fi
done

if [ $bad -ne 0 ]; then
  echo "Supabase-specific SQL outside a -- [supabase-only] block (docs/adr/0001-vendor-portability.md rule 4)."
  exit 1
fi
echo "SQL portability check passed (${#LEGACY[@]} applied legacy migrations exempt)."
