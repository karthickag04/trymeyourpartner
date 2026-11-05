import '../../core/services/notification_service.dart';
import 'http_client.dart';

class HttpNotificationService implements NotificationService {
  final ApiClient api;
  HttpNotificationService(this.api);

  // Endpoints assumed for HTTP backend parity
  // GET    /notifications?profileId=...
  // POST   /notifications/mark-read      { notification_id }
  // POST   /notifications/mark-all-read  { profile_id }

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications(
    String profileId,
  ) async {
    final data = await api.get(
      '/notifications',
      query: {'profileId': profileId},
    );
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();
    }
    return const [];
  }

  @override
  Future<void> markRead(String notificationId) async {
    await api.post(
      '/notifications/mark-read',
      body: {'notification_id': notificationId},
    );
  }

  @override
  Future<void> markAllRead(String profileId) async {
    await api.post(
      '/notifications/mark-all-read',
      body: {'profile_id': profileId},
    );
  }
}
