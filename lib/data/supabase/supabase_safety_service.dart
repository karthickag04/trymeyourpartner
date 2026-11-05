import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/safety_service.dart';

class SupabaseSafetyService implements SafetyService {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<void> blockProfile(
    String blockerProfileId,
    String blockedProfileId,
  ) async {
    await _db.from('blocked_profiles').insert({
      'profile_id': blockerProfileId,
      'blocked_profile_id': blockedProfileId,
    });
  }

  @override
  Future<void> unblockProfile(
    String blockerProfileId,
    String blockedProfileId,
  ) async {
    await _db.from('blocked_profiles').delete().match({
      'profile_id': blockerProfileId,
      'blocked_profile_id': blockedProfileId,
    });
  }

  @override
  Future<void> reportProfile(
    String reporterProfileId,
    String reportedProfileId,
    String reason, {
    String? details,
  }) async {
    await _db.from('reports').insert({
      'reporter_id': reporterProfileId,
      'reported_id': reportedProfileId,
      'reason': reason,
      if (details != null) 'details': details,
    });
  }

  @override
  Future<bool> isBlocked(String currentProfileId, String otherProfileId) async {
    final res = await _db
        .from('blocked_profiles')
        .select('id')
        .or('profile_id.eq.$currentProfileId,profile_id.eq.$otherProfileId')
        .or(
          'blocked_profile_id.eq.$currentProfileId,blocked_profile_id.eq.$otherProfileId',
        )
        .limit(1);
    return (res as List).isNotEmpty;
  }
}
