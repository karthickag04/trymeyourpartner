import '../../shared/models/presence_status.dart';

abstract class PresenceService {
  Future<void> heartbeat({required String myProfileId});
  Future<PresenceStatus> getPresence(String profileId);
}
