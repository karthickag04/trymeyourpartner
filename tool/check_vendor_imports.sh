#!/usr/bin/env bash
# Enforces docs/adr/0001-vendor-portability.md: app code reaches Supabase only
# through lib/data/supabase/. Files listed below are legacy exceptions being
# migrated behind interfaces; this list must only shrink.
set -euo pipefail
cd "$(dirname "$0")/.."
ALLOWED=(
  lib/main.dart                                      # Supabase.initialize at start-up
  lib/app/settings/app_settings.dart                 # SupabaseAppSettingsSource (move to lib/data, P1-14)
  lib/shared/services/matrimonial_service.dart       # legacy data access (move to the API, P2-08)
  lib/features/notifications/notifications_service.dart  # realtime (move behind RealtimeService, P1-16)
  lib/features/subscriptions/subscription_service.dart   # contact reveal (move to the API, P2-08)
)
bad=0
while IFS= read -r f; do
  case " ${ALLOWED[*]} " in *" $f "*) continue ;; esac
  echo "Not allowed: $f imports supabase_flutter. Put vendor code in lib/data/supabase/ behind an interface (docs/adr/0001-vendor-portability.md)."
  bad=1
done < <(grep -rl "package:supabase_flutter" lib --include=*.dart | grep -v '^lib/data/supabase/' | sort)
[ $bad -eq 0 ] && echo "Vendor import check passed (${#ALLOWED[@]} legacy exceptions left)."
exit $bad
