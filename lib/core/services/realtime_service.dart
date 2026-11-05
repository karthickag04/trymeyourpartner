typedef VoidAsync = Future<void> Function();

typedef RealtimeCallback = Future<void> Function(Map<String, dynamic> row);

abstract class RealtimeService {
  /// Subscribe to interest-related events for a given profile_id.
  /// Returns an opaque handle to later unsubscribe.
  Future<Object?> subscribeInterests(
    String profileId, {
    RealtimeCallback? onInsertToMe,
    RealtimeCallback? onUpdateToMe,
    RealtimeCallback? onUpdateFromMe,
    RealtimeCallback? onDeleteToMe,
  });

  /// Subscribe to realtime message inserts and receipt updates for a chat thread
  /// between [myProfileId] and [otherProfileId]. Returns an opaque handle.
  Future<Object?> subscribeThreadMessages(
    String myProfileId,
    String otherProfileId, {
    RealtimeCallback? onInsert,
    RealtimeCallback? onReceiptUpdate,
  });

  /// Subscribe to global message unread counter changes for a profile.
  /// Implementation may use realtime changes or polling. The callback is
  /// invoked on any potential change; consumers should re-query the count.
  Future<Object?> subscribeUnreadCounter(
    String myProfileId, {
    RealtimeCallback? onChange,
  });

  /// Subscribe to new notifications for a profile. Returns an opaque handle.
  Future<Object?> subscribeNotifications(
    String profileId, {
    RealtimeCallback? onInsert,
  });

  Future<void> unsubscribe(Object? handle);
}
