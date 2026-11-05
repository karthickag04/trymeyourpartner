abstract class NotificationService {
  Future<List<Map<String, dynamic>>> fetchNotifications(String profileId);
  Future<void> markRead(String notificationId);
  Future<void> markAllRead(String profileId);
}
