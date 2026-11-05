import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/realtime_service.dart';

class SupabaseRealtimeService implements RealtimeService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Object?> subscribeInterests(
    String profileId, {
    RealtimeCallback? onInsertToMe,
    RealtimeCallback? onUpdateToMe,
    RealtimeCallback? onUpdateFromMe,
    RealtimeCallback? onDeleteToMe,
  }) async {
    final channel = _client.channel('interactions:$profileId');

    if (onInsertToMe != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'profile_interactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'to_profile_id',
          value: profileId,
        ),
        callback: (payload) async {
          final row = payload.newRecord;
          await onInsertToMe(row);
        },
      );
    }

    if (onUpdateToMe != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profile_interactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'to_profile_id',
          value: profileId,
        ),
        callback: (payload) async {
          final row = payload.newRecord;
          await onUpdateToMe(row);
        },
      );
    }

    if (onUpdateFromMe != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profile_interactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'from_profile_id',
          value: profileId,
        ),
        callback: (payload) async {
          final row = payload.newRecord;
          await onUpdateFromMe(row);
        },
      );
    }

    if (onDeleteToMe != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'profile_interactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'to_profile_id',
          value: profileId,
        ),
        callback: (payload) async {
          final row = payload.oldRecord;
          await onDeleteToMe(row);
        },
      );
    }

    channel.subscribe();
    return channel;
  }

  @override
  Future<void> unsubscribe(Object? handle) async {
    if (handle is RealtimeChannel) {
      Supabase.instance.client.removeChannel(handle);
    }
  }

  @override
  Future<Object?> subscribeNotifications(
    String profileId, {
    RealtimeCallback? onInsert,
  }) async {
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
      callback: (payload) async {
        if (onInsert != null) await onInsert(payload.newRecord);
      },
    );
    ch.subscribe();
    return ch;
  }

  @override
  Future<Object?> subscribeThreadMessages(
    String myProfileId,
    String otherProfileId, {
    RealtimeCallback? onInsert,
    RealtimeCallback? onReceiptUpdate,
  }) async {
    final ch = _client.channel('chat:$myProfileId:$otherProfileId');
    if (onInsert != null) {
      // Inserts where either direction matches the thread
      ch.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'profile_interactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'from_profile_id',
          value: myProfileId,
        ),
        callback: (payload) async => onInsert(payload.newRecord),
      );
      ch.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'profile_interactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'to_profile_id',
          value: myProfileId,
        ),
        callback: (payload) async => onInsert(payload.newRecord),
      );
      ch.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'profile_interactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'from_profile_id',
          value: otherProfileId,
        ),
        callback: (payload) async => onInsert(payload.newRecord),
      );
    }
    if (onReceiptUpdate != null) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'message_receipts',
        callback: (payload) async => onReceiptUpdate(payload.newRecord),
      );
    }
    ch.subscribe();
    return ch;
  }

  @override
  Future<Object?> subscribeUnreadCounter(
    String myProfileId, {
    RealtimeCallback? onChange,
  }) async {
    final ch = _client.channel('unread:$myProfileId');
    // New messages to me
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'profile_interactions',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'to_profile_id',
        value: myProfileId,
      ),
      callback: (payload) async {
        final row = payload.newRecord;
        if (row['interaction_type'] == 'message' && onChange != null) {
          await onChange.call(row);
        }
      },
    );
    // Receipts updates affecting me (read/delivered)
    ch.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'message_receipts',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_profile_id',
        value: myProfileId,
      ),
      callback: (payload) async {
        if (onChange != null) await onChange.call(payload.newRecord);
      },
    );
    // Also covers new receipts inserted for me
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'message_receipts',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_profile_id',
        value: myProfileId,
      ),
      callback: (payload) async {
        if (onChange != null) await onChange.call(payload.newRecord);
      },
    );
    ch.subscribe();
    return ch;
  }
}
