import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/notification_service.dart';

class SupabaseNotificationService implements NotificationService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications(
    String profileId,
  ) async {
    final res = await _client
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAllRead(String profileId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('profile_id', profileId);
  }
}
