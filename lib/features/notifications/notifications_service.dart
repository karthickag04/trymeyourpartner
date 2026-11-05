import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationsService {
  // Lazily access client to avoid premature Supabase.instance usage
  static SupabaseClient get _client => Supabase.instance.client;
  RealtimeChannel? _channel;

  void dispose() {
    if (_channel != null) {
      try {
        Supabase.instance.client.removeChannel(_channel!);
      } catch (_) {}
      _channel = null;
    }
  }

  // Subscribe to notifications rows for the current user's profile
  Future<void> subscribeForProfile({
    required String profileId,
    required void Function(Map<String, dynamic> row) onInsert,
  }) async {
    // tear down if exists
    dispose();

    final ch = _client.channel('notifications:$profileId');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'profile_id',
        value: profileId,
      ),
      callback: (payload) {
        try {
          onInsert(payload.newRecord);
        } catch (e) {
          debugPrint('notifications callback error: $e');
        }
      },
    );
    ch.subscribe();
    _channel = ch;
  }

  Future<List<Map<String, dynamic>>> listNotifications({
    required String profileId,
    int limit = 50,
  }) async {
    return await _client
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<void> markRead({required String notificationId}) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  Future<void> markAllRead({required String profileId}) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('profile_id', profileId)
        .filter('read_at', 'is', null);
  }
}
