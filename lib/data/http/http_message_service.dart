import '../../core/services/message_service.dart';
import 'http_client.dart';

class HttpMessageService implements MessageService {
  final ApiClient api;
  HttpMessageService(this.api);

  @override
  Future<List<Map<String, dynamic>>> getInbox(String myProfileId) async {
    final data = await api.get(
      '/messages/inbox',
      query: {'profileId': myProfileId},
    );
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();
    }
    throw Exception('Unexpected inbox response');
  }

  @override
  Future<List<Map<String, dynamic>>> getThread(
    String myProfileId,
    String otherProfileId,
  ) async {
    final data = await api.get(
      '/messages/thread',
      query: {'me': myProfileId, 'other': otherProfileId},
    );
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();
    }
    throw Exception('Unexpected thread response');
  }

  @override
  Future<void> sendMessage(
    String fromProfileId,
    String toProfileId,
    String text,
  ) async {
    await api.post(
      '/messages/send',
      body: {
        'from_profile_id': fromProfileId,
        'to_profile_id': toProfileId,
        'message': text,
      },
    );
  }

  @override
  Future<int> getUnreadCount(String myProfileId) async {
    final data = await api.get(
      '/messages/unread-count',
      query: {'profileId': myProfileId},
    );
    if (data is num) {
      return data.toInt();
    }
    if (data is Map && data['count'] is num) {
      return (data['count'] as num).toInt();
    }
    return 0;
  }

  @override
  Future<int> getThreadUnreadCount(
    String myProfileId,
    String otherProfileId,
  ) async {
    try {
      final data = await api.get(
        '/messages/thread-unread',
        query: {'me': myProfileId, 'other': otherProfileId},
      );
      if (data is num) return data.toInt();
      if (data is Map && data['count'] is num)
        return (data['count'] as num).toInt();
    } catch (_) {
      // Fallback to client-side calculation using thread rows
      try {
        final rows = await getThread(myProfileId, otherProfileId);
        int unread = 0;
        for (final row in rows) {
          final to = row['to_profile_id']?.toString();
          final readAt = row['read_at']?.toString();
          if (to == myProfileId && (readAt == null || readAt.isEmpty)) {
            unread += 1;
          }
        }
        return unread;
      } catch (_) {}
    }
    return 0;
  }

  @override
  Future<void> markMessagesRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    await api.post('/messages/mark-read', body: {'message_ids': messageIds});
  }

  @override
  Future<Map<String, int>> getBatchThreadUnreadCounts(
    String myProfileId,
    List<String> otherProfileIds,
  ) async {
    if (otherProfileIds.isEmpty) return {};
    // Try dedicated batch endpoint first
    try {
      final data = await api.post(
        '/messages/thread-unread-batch',
        body: {'me': myProfileId, 'others': otherProfileIds},
      );
      if (data is Map) {
        // Normalize values to int
        return data.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {
      // fall back to per-thread calls below
    }

    // Fallback: do per-peer requests (still in parallel)
    final futures = otherProfileIds.map((peer) async {
      final n = await getThreadUnreadCount(myProfileId, peer);
      return MapEntry(peer, n);
    });
    final results = await Future.wait(futures);
    return {for (final e in results) e.key: e.value};
  }
}
