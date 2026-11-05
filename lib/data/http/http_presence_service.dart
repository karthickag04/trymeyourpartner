import '../../models/presence_status.dart';
import 'http_client.dart';
import '../../core/services/presence_service.dart';

class HttpPresenceService implements PresenceService {
  final ApiClient _api;
  HttpPresenceService(this._api);

  @override
  Future<void> heartbeat({required String myProfileId}) async {
    await _api.post(
      '/presence/heartbeat',
      body: {
        'profile_id': myProfileId,
        'at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<PresenceStatus> getPresence(String profileId) async {
    final json = await _api.get('/presence/$profileId');
    if (json is Map<String, dynamic>) {
      return PresenceStatus.fromJson(json);
    }
    return const PresenceStatus(isOnline: false);
  }
}
