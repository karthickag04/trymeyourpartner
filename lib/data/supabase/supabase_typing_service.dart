import '../../core/services/typing_service.dart';

class SupabaseTypingService implements TypingService {
  @override
  Future<void> sendTyping({
    required String myProfileId,
    required String otherProfileId,
    int ttlSeconds = 7,
  }) async {
    // No-op for now; chat typing can be emitted via Supabase Realtime if desired.
    return;
  }

  @override
  Future<bool> isTyping({
    required String myProfileId,
    required String otherProfileId,
  }) async {
    // No built-in query; return false by default.
    return false;
  }
}
