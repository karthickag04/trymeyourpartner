#!/usr/bin/env bash
# P1-22: no empty catch blocks. An error the app recovers from is reported
# with reportError (lib/shared/errors/report_error.dart); anything the member
# asked to save must fail visibly. An empty catch is how the caste bug hid
# (docs/PROGRESS_TRACKER.md, Bugs).
set -euo pipefail
cd "$(dirname "$0")/.."
PATTERN='catch \([A-Za-z_]+(, *[A-Za-z_]+)?\) *\{ *\}'
hits=$(grep -rnE "$PATTERN" lib apps/admin_console/lib --include=*.dart || true)
if [ -n "$hits" ]; then
  echo "$hits"
  echo "Empty catch blocks found. Report the error (reportError) or rethrow it; never drop it."
  exit 1
fi
echo "Silent catch check passed (no empty catch blocks)."
