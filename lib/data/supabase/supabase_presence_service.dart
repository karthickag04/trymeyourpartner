import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/presence_service.dart';
import '../../models/presence_status.dart';

class SupabasePresenceService implements PresenceService {
  @override
  Future<void> heartbeat({required String myProfileId}) async {
    try {
      await Supabase.instance.client.rpc(
        'heartbeat_presence',
        params: {'p_profile_id': myProfileId},
      );
    } catch (_) {
      // If RPC not available, silently ignore.
    }
  }

  @override
  Future<PresenceStatus> getPresence(String profileId) async {
    try {
      final res = await Supabase.instance.client.rpc(
        'get_presence',
        params: {'p_profile_id': profileId},
      );
      if (res is Map<String, dynamic>) {
        return PresenceStatus.fromJson(res);
      }
      if (res is List && res.isNotEmpty && res.first is Map<String, dynamic>) {
        return PresenceStatus.fromJson(res.first as Map<String, dynamic>);
      }
    } catch (_) {}
    return const PresenceStatus(isOnline: false);
  }
}
