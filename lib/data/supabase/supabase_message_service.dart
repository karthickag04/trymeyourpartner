import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/message_service.dart';

class SupabaseMessageService implements MessageService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getInbox(String myProfileId) async {
    final res = await _client
        .from('profile_interactions')
        .select()
        .or('from_profile_id.eq.$myProfileId,to_profile_id.eq.$myProfileId')
        .eq('interaction_type', 'message')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<List<Map<String, dynamic>>> getThread(
    String myProfileId,
    String otherProfileId,
  ) async {
    final res = await _client
        .from('profile_interactions')
        .select()
        .or(
          'and(from_profile_id.eq.$myProfileId,to_profile_id.eq.$otherProfileId),and(from_profile_id.eq.$otherProfileId,to_profile_id.eq.$myProfileId)',
        )
        .eq('interaction_type', 'message')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> sendMessage(
    String fromProfileId,
    String toProfileId,
    String text,
  ) async {
    await _client.from('profile_interactions').insert({
      'from_profile_id': fromProfileId,
      'to_profile_id': toProfileId,
      'interaction_type': 'message',
      'message': text,
    });
  }

  @override
  Future<int> getUnreadCount(String myProfileId) async {
    try {
      final res = await _client
          .from('message_receipts')
          .select('id')
          .eq('receiver_profile_id', myProfileId)
          .filter('read_at', 'is', null);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<int> getThreadUnreadCount(
    String myProfileId,
    String otherProfileId,
  ) async {
    try {
      // Count receipts where receiver is me and message is from other
      final res = await _client
          .from('message_receipts')
          .select('id, sender_profile_id, receiver_profile_id, read_at')
          .eq('receiver_profile_id', myProfileId)
          .eq('sender_profile_id', otherProfileId)
          .filter('read_at', 'is', null);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> markMessagesRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    try {
      await _client.rpc(
        'mark_messages_read',
        params: {'p_message_ids': messageIds},
      );
    } catch (_) {}
  }

  @override
  Future<Map<String, int>> getBatchThreadUnreadCounts(
    String myProfileId,
    List<String> otherProfileIds,
  ) async {
    if (otherProfileIds.isEmpty) return {};
    try {
      // Fetch all unread receipts to me where sender in others
      final res = await _client
          .from('message_receipts')
          .select('sender_profile_id')
          .eq('receiver_profile_id', myProfileId)
          .filter('read_at', 'is', null)
          .inFilter('sender_profile_id', otherProfileIds);
      final counts = <String, int>{for (final id in otherProfileIds) id: 0};
      for (final row in (res as List)) {
        final sender = (row['sender_profile_id'] ?? '').toString();
        if (sender.isEmpty) continue;
        counts[sender] = (counts[sender] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      // Fallback: per-thread calls
      final futures = otherProfileIds.map((peer) async {
        final n = await getThreadUnreadCount(myProfileId, peer);
        return MapEntry(peer, n);
      });
      final results = await Future.wait(futures);
      return {for (final e in results) e.key: e.value};
    }
  }
}
