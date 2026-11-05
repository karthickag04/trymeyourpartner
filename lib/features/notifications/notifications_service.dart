import 'package:flutter/foundation.dart';

import '../../app/di/service_locator.dart';

/// Notifications for the signed-in member, through the backend-neutral
/// RealtimeService and NotificationService (docs/adr/0001-vendor-portability.md).
class NotificationsService {
  Object? _handle;

  void dispose() {
    final h = _handle;
    _handle = null;
    if (h != null) sl.realtimeService.unsubscribe(h);
  }

  /// Calls [onInsert] for each new notification for [profileId].
  Future<void> subscribeForProfile({
    required String profileId,
    required void Function(Map<String, dynamic> row) onInsert,
  }) async {
    dispose();
    _handle = await sl.realtimeService.subscribeNotifications(
      profileId,
      onInsert: (row) async {
        try {
          onInsert(row);
        } catch (e) {
          debugPrint('notifications callback error: $e');
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> listNotifications({
    required String profileId,
    int limit = 50,
  }) async {
    final all = await sl.notificationService.fetchNotifications(profileId);
    return all.take(limit).toList();
  }

  Future<void> markRead({required String notificationId}) =>
      sl.notificationService.markRead(notificationId);

  Future<void> markAllRead({required String profileId}) =>
      sl.notificationService.markAllRead(profileId);
}
