#!/usr/bin/env bash
# Builds the schema in a plain Postgres, applies every migration twice
# (they must be re-runnable), then runs the access-rule checks.
# Usage: PGHOST=... PGPORT=... PGUSER=postgres supabase/tests/local/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HERE="$ROOT/supabase/tests/local"
DB="${TEST_DB:-tmyp_ci}"
psql -q -v ON_ERROR_STOP=1 -d postgres -c "drop database if exists $DB" -c "create database $DB"
P="psql -q -X -d $DB"

$P -v ON_ERROR_STOP=1 -f "$HERE/00_supabase_stub.sql" 2>&1 | grep -v -i "wal_level\|logical" || true

# Historical schema scripts. Some reference Supabase-only objects (storage
# buckets) and fail harmlessly here, so errors are reported but not fatal.
load() { $P -f "$1" 2>&1 | grep ERROR | sed "s#^#  [schema] #" || true; }
load "$ROOT/supabase_matrimonial_complete.sql"
for f in registration_extensions subscriptions_and_contacts contact_exchange verifications \
         reports_and_blocks saved_searches notifications message_receipts presence icebreakers \
         deleted_users insert_or_increment_view insert_shortlist upsert_contact_info \
         allow_multiple_messages fix_shortlist_select_target block_rls_enforcement; do
  load "$ROOT/sql/$f.sql"
done
$P -v ON_ERROR_STOP=1 -f "$HERE/10_seed.sql"

for pass in 1 2; do
  for m in "$ROOT"/supabase/migrations/*.sql; do
    echo "apply (pass $pass): $(basename "$m")"
    $P -v ON_ERROR_STOP=1 -f "$m"
  done
done

OUT=$($P -At -f "$HERE/20_checks.sql" 2>&1 | sed 's/^psql:[^:]*:[0-9]*: //')
echo "$OUT"

expect() { grep -qF -- "$1" <<<"$OUT" || { echo "MISSING EXPECTED: $1"; exit 1; }; }
expect "ERROR:  permission denied for table matrimonial_profiles"   # anon cannot read profiles
expect "anon states|10"                                              # public lookups still work
expect "ERROR:  permission denied for function delete_profile_and_related"
expect "emails visible|0"
expect "A after self-verify|A2|f|0"
expect "ERROR:  permission denied for table subscriptions"
expect "ERROR:  permission denied for table verifications"
expect "A active plan|free|"
expect "A reads B contact_info directly|0"
expect '"phone_number" : "9000000002"'
expect "reveals used|1"
expect "CANNOT_REVEAL_SELF"
expect "NOT_AUTHORIZED"
expect "B views counter|1"
expect "B still exists|1"
expect "stopped after 4 new reveals: CONTACT_LIMIT_REACHED"
expect "archived email|b@x.com"
echo "All database checks passed."
