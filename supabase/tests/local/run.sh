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
  if [ "$pass" = 1 ]; then
    $P -v ON_ERROR_STOP=1 -f "$HERE/10_seed.sql"
    $P -v ON_ERROR_STOP=1 -f "$HERE/11_seed_staff.sql"
  fi
done

OUT=$( { $P -At -f "$HERE/20_checks.sql"; $P -At -f "$HERE/21_staff_checks.sql"; } 2>&1 | sed 's/^psql:[^:]*:[0-9]*: //')
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
# Phase 2: staff tables, scopes, MFA, audit log, access token hook
for t in staff_accounts branches teams agents permissions role_permissions audit_log; do
  expect "member $t|0"                                               # members get nothing
done
expect "member staff profile|none"
expect "ERROR:  NOT_STAFF"                                           # members cannot write the audit log
expect "ERROR:  new row violates row-level security policy for table \"branches\""
expect "ERROR:  permission denied for function custom_access_token_hook"
expect "staffY staff_accounts|1|Staff Y"                            # staff: own row only
expect "staffY branches|BRY"                                         # ... and own branch
expect "staffY audit_log|0"
expect "bmX aal1 staff_accounts|1"                                   # before MFA: own row only
expect "bmX aal1 permissions|[]"
expect "ERROR:  MFA_REQUIRED"
expect "bmX staff_accounts|BM X,Staff X"                             # branch manager: own branch
expect "bmX sees branch Y staff|0"                                   # ... never another branch
expect "bmX branches|BRX"
expect "bmX has roles.manage|f"
expect "bmX profile|branch_manager|Branch X"
[ "$(grep -cF 'new row violates row-level security policy for table "staff_accounts"' <<<"$OUT")" = 2 ] \
  || { echo "MISSING EXPECTED: branch manager blocked twice (system_admin, other branch)"; exit 1; }
expect "bmX created staff|1"
expect "bmX own role after self-promote|branch_manager"
expect "ERROR:  new row violates row-level security policy for table \"role_permissions\""
expect "sysadmin staff_accounts|5"                                   # system_admin: everything
expect "sysadmin permission count|20|20"
expect "staff granted reports.operations|1"
expect "sysadmin grants kept|t"                                      # system_admin grants are locked
expect "audit pii entry|branch_manager|member_pii.view|bbbbbbbb-0000-0000-0000-000000000002|support call"
expect "audit rp changes|2"
expect "audit staff insert by bmX|1"
[ "$(grep -cF 'ERROR:  permission denied for table audit_log' <<<"$OUT")" = 3 ] \
  || { echo "MISSING EXPECTED: audit_log rejects UPDATE, DELETE and INSERT through the API"; exit 1; }
[ "$(grep -cF 'ERROR:  AUDIT_LOG_IS_APPEND_ONLY' <<<"$OUT")" = 2 ] \
  || { echo "MISSING EXPECTED: audit_log append-only for the table owner"; exit 1; }
expect "audit tampered rows|0"
expect '"team_id": null, "branch_id": "0000000a-0000-0000-0000-00000000000a", "staff_role": "branch_manager"'
expect "hook member unchanged|t"
expect "hook disabled staff unchanged|t"
expect "disabled staff sees|0"
expect "bmX settings change|false"                                    # only platform.settings may edit
expect "sysadmin aal1 settings change|false"                         # ... and only after MFA
expect "ERROR:  permission denied for table app_settings"            # only the value column is editable
expect "sysadmin settings change|Back soon|33333333-3333-3333-3333-333333333333"
expect "settings audit|system_admin|maintenance|false|Back soon"
expect "settings audit entries|2"
OUT2=$($P -At -f "$HERE/30_app_settings_checks.sql" 2>&1 | sed 's/^psql:[^:]*:[0-9]*: //')
echo "$OUT2"
expect2() { grep -qF -- "$1" <<<"$OUT2" || { echo "MISSING EXPECTED: $1"; exit 1; }; }
expect2 "anon reads settings|5"
# A member's update matches no rows: staff with platform.settings may edit values (Phase 2),
# so the column is granted and row-level security decides; "maintenance still off" checks it.
expect2 "maintenance still off|false"
expect2 "raised quota|1 more, then CONTACT_LIMIT_REACHED"
expect2 "feature off|FEATURE_DISABLED"
expect2 "identity helper|t"
expect2 "identity helper signed out|t"
expect2 "auth.uid remaining|0"

echo "All database checks passed."
