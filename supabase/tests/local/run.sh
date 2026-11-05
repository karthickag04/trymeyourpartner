#!/usr/bin/env bash
# Builds the schema in a plain Postgres from the migrations (baseline first),
# applies every migration twice
# (they must be re-runnable), then runs the access-rule checks.
# Usage: PGHOST=... PGPORT=... PGUSER=postgres supabase/tests/local/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HERE="$ROOT/supabase/tests/local"
DB="${TEST_DB:-tmyp_ci}"
export PGOPTIONS="-c client_min_messages=warning"
psql -q -v ON_ERROR_STOP=1 -d postgres -c "drop database if exists $DB" -c "create database $DB"
P="psql -q -X -d $DB"

$P -v ON_ERROR_STOP=1 -f "$HERE/00_supabase_stub.sql" 2>&1 | grep -v -i "wal_level\|logical" || true

$P -c "alter database $DB set search_path = \"\$user\", public, extensions"
P="psql -q -X -d $DB -v VERBOSITY=terse"   # reconnect so the search path applies

# Pass 1 builds the schema from the baseline; seed test data; pass 2 re-applies
# everything on top of data (every migration must be re-runnable).
for pass in 1 2; do
  for m in "$ROOT"/supabase/migrations/*.sql; do
    echo "apply (pass $pass): $(basename "$m")"
    $P -v ON_ERROR_STOP=1 -f "$m"
  done
  [ "$pass" = 1 ] && $P -v ON_ERROR_STOP=1 -f "$HERE/10_seed.sql"
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
expect "quota|stopped after 4 new reveals: CONTACT_LIMIT_REACHED"
expect "archived email|b@x.com"
OUT2=$($P -At -f "$HERE/30_app_settings_checks.sql" 2>&1 | sed 's/^psql:[^:]*:[0-9]*: //')
echo "$OUT2"
expect2() { grep -qF -- "$1" <<<"$OUT2" || { echo "MISSING EXPECTED: $1"; exit 1; }; }
expect2 "anon reads settings|5"
expect2 "ERROR:  permission denied for table app_settings"
expect2 "maintenance still off|false"
expect2 "raised quota|1 more, then CONTACT_LIMIT_REACHED"
expect2 "feature off|FEATURE_DISABLED"
expect2 "identity helper|t"
expect2 "identity helper signed out|t"
expect2 "auth.uid remaining|0"

echo "All database checks passed."
