import '../../core/services/safety_service.dart';
import 'http_client.dart';

class HttpSafetyService implements SafetyService {
  final ApiClient _api;
  HttpSafetyService(this._api);

  @override
  Future<void> blockProfile(
    String blockerProfileId,
    String blockedProfileId,
  ) async {
    await _api.post(
      '/block',
      body: {'blockerId': blockerProfileId, 'blockedId': blockedProfileId},
    );
  }

  @override
  Future<void> unblockProfile(
    String blockerProfileId,
    String blockedProfileId,
  ) async {
    await _api.delete(
      '/block',
      body: {'blockerId': blockerProfileId, 'blockedId': blockedProfileId},
    );
  }

  @override
  Future<void> reportProfile(
    String reporterProfileId,
    String reportedProfileId,
    String reason, {
    String? details,
  }) async {
    await _api.post(
      '/reports',
      body: {
        'reporterId': reporterProfileId,
        'reportedId': reportedProfileId,
        'reason': reason,
        if (details != null) 'details': details,
      },
    );
  }

  @override
  Future<bool> isBlocked(String currentProfileId, String otherProfileId) async {
    final res = await _api.get(
      '/block/status',
      query: {'a': currentProfileId, 'b': otherProfileId},
    );
    if (res is Map && res['blocked'] is bool) return res['blocked'] as bool;
    return false;
  }
}
