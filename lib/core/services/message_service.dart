abstract class MessageService {
  Future<List<Map<String, dynamic>>> getInbox(String myProfileId);
  Future<List<Map<String, dynamic>>> getThread(
    String myProfileId,
    String otherProfileId,
  );
  Future<void> sendMessage(
    String fromProfileId,
    String toProfileId,
    String text,
  );
  // Count unread messages for this profile (messages where this profile is receiver and not read)
  Future<int> getUnreadCount(String myProfileId);
  // Count unread messages in a specific thread between two profiles
  Future<int> getThreadUnreadCount(String myProfileId, String otherProfileId);
  // Batch unread counts for multiple peers (best-effort; may fallback to per-thread)
  Future<Map<String, int>> getBatchThreadUnreadCounts(
    String myProfileId,
    List<String> otherProfileIds,
  );
  // Mark specific messages as read (best-effort; ignore if backend doesn't support)
  Future<void> markMessagesRead(List<String> messageIds);
}
