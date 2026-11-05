import '../../core/services/typing_service.dart';
import 'http_client.dart';

class HttpTypingService implements TypingService {
  final ApiClient _api;
  HttpTypingService(this._api);

  @override
  Future<void> sendTyping({
    required String myProfileId,
    required String otherProfileId,
    int ttlSeconds = 7,
  }) async {
    await _api.post(
      '/typing',
      body: {
        'thread_key': _threadKey(myProfileId, otherProfileId),
        'expires_at': DateTime.now()
            .toUtc()
            .add(Duration(seconds: ttlSeconds))
            .toIso8601String(),
      },
    );
  }

  @override
  Future<bool> isTyping({
    required String myProfileId,
    required String otherProfileId,
  }) async {
    final json = await _api.get(
      '/typing',
      query: {'thread_key': _threadKey(myProfileId, otherProfileId)},
    );
    if (json is Map<String, dynamic>) {
      final v = json['typing'] ?? json['is_typing'] ?? json['isTyping'];
      if (v is bool) return v;
    }
    return false;
  }

  String _threadKey(String a, String b) {
    return (a.compareTo(b) <= 0) ? '$a:$b' : '$b:$a';
  }
}
