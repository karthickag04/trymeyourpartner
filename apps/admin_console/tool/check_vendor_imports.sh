#!/usr/bin/env bash
# docs/adr/0001-vendor-portability.md: the console reaches its provider only
# through lib/data/ (behind ConsoleAuth and ConsoleData in lib/src/services/).
set -euo pipefail
cd "$(dirname "$0")/.."
bad=$(grep -rl "package:supabase_flutter\|package:supabase/\|package:gotrue\|package:postgrest" lib test --include=*.dart | grep -v '^lib/data/' || true)
if [ -n "$bad" ]; then
  echo "Provider packages imported outside lib/data/ (see docs/adr/0001-vendor-portability.md):"
  echo "$bad"
  exit 1
fi
echo "Vendor import check passed (provider code only in lib/data/)."
