import 'dart:async';
import '../../core/services/realtime_service.dart';
import 'http_client.dart';

class HttpRealtimeService implements RealtimeService {
  final ApiClient _api;
  HttpRealtimeService(this._api);

  @override
  Future<Object?> subscribeInterests(
    String profileId, {
    RealtimeCallback? onInsertToMe,
    RealtimeCallback? onUpdateToMe,
    RealtimeCallback? onUpdateFromMe,
    RealtimeCallback? onDeleteToMe,
  }) async {
    final handle = _InterestPollHandle(
      api: _api,
      profileId: profileId,
      onInsertToMe: onInsertToMe,
      onUpdateToMe: onUpdateToMe,
      onDeleteToMe: onDeleteToMe,
    );
    handle.start();
    return handle;
  }

  @override
  Future<Object?> subscribeThreadMessages(
    String myProfileId,
    String otherProfileId, {
    RealtimeCallback? onInsert,
    RealtimeCallback? onReceiptUpdate,
  }) async {
    final handle = _ThreadPollHandle(
      api: _api,
      my: myProfileId,
      other: otherProfileId,
      onInsert: onInsert,
    );
    handle.start();
    return handle;
  }

  @override
  Future<void> unsubscribe(Object? handle) async {
    if (handle is _BasePollHandle) {
      handle.stop();
    }
  }

  @override
  Future<Object?> subscribeNotifications(
    String profileId, {
    RealtimeCallback? onInsert,
  }) async {
    final handle = _NotificationsPollHandle(
      api: _api,
      profileId: profileId,
      onInsert: onInsert,
    );
    handle.start();
    return handle;
  }

  @override
  Future<Object?> subscribeUnreadCounter(
    String myProfileId, {
    RealtimeCallback? onChange,
  }) async {
    final handle = _UnreadPollHandle(
      api: _api,
      my: myProfileId,
      onChange: onChange,
    );
    handle.start();
    return handle;
  }
}

/// Polls GET /notifications and reports rows not seen before
/// (the first poll only records what already exists).
class _NotificationsPollHandle extends _BasePollHandle {
  final ApiClient api;
  final String profileId;
  final RealtimeCallback? onInsert;
  Set<String>? _seen;
  _NotificationsPollHandle({
    required this.api,
    required this.profileId,
    this.onInsert,
  });

  @override
  Duration get interval => const Duration(seconds: 20);

  @override
  void tick() async {
    try {
      final data = await api.get(
        '/notifications',
        query: {'profileId': profileId},
      );
      if (data is! List) return;
      final rows = data
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
      final ids = rows.map((r) => r['id']?.toString() ?? '').toSet();
      final seen = _seen;
      _seen = ids;
      if (seen == null || onInsert == null) return;
      for (final r in rows) {
        if (!seen.contains(r['id']?.toString())) await onInsert!(r);
      }
    } catch (_) {}
  }
}

abstract class _BasePollHandle {
  Timer? _timer;
  Duration get interval;
  void tick();
  void start() {
    _timer?.cancel();
    // Run immediately once, then schedule
    tick();
    _timer = Timer.periodic(interval, (_) => tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

class _InterestPollHandle extends _BasePollHandle {
  final ApiClient api;
  final String profileId;
  final RealtimeCallback? onInsertToMe;
  final RealtimeCallback? onUpdateToMe;
  final RealtimeCallback? onDeleteToMe;
  Set<String> _lastReceived = <String>{};
  _InterestPollHandle({
    required this.api,
    required this.profileId,
    this.onInsertToMe,
    this.onUpdateToMe,
    this.onDeleteToMe,
  });

  @override
  Duration get interval => const Duration(seconds: 20);

  @override
  void tick() async {
    try {
      final data = await api.get('/interests/received');
      final current = <String>{};
      if (data is List) {
        for (final e in data) {
          if (e is Map && e['id'] != null) {
            current.add(e['id'].toString());
          }
        }
      } else if (data is Map && data['items'] is List) {
        for (final e in (data['items'] as List)) {
          if (e is Map && e['id'] != null) {
            current.add(e['id'].toString());
          }
        }
      }

      // New interests to me
      final added = current.difference(_lastReceived);
      if (added.isNotEmpty && onInsertToMe != null) {
        for (final fromId in added) {
          await onInsertToMe!.call({
            'interaction_type': 'interest',
            'status': 'pending',
            'from_profile_id': fromId,
            'to_profile_id': profileId,
          });
        }
      }

      // Removed interests (withdrawn)
      final removed = _lastReceived.difference(current);
      if (removed.isNotEmpty && onDeleteToMe != null) {
        for (final fromId in removed) {
          await onDeleteToMe!.call({
            'interaction_type': 'interest',
            'from_profile_id': fromId,
            'to_profile_id': profileId,
          });
        }
      }

      // Generic updates: if counts changed but no adds/removes detected
      if (!current.containsAll(_lastReceived) ||
          !_lastReceived.containsAll(current)) {
        if (onUpdateToMe != null) {
          await onUpdateToMe!.call({
            'interaction_type': 'interest',
            'to_profile_id': profileId,
          });
        }
      }

      _lastReceived = current;
    } catch (_) {
      // Basic backoff on error to avoid hot loops
      _backoffOnce();
    }
  }

  void _backoffOnce() {
    // jitter between 5s and 15s added once
    _timer?.cancel();
    final extraMs = 5000 + (DateTime.now().millisecond % 10000);
    _timer = Timer(
      Duration(milliseconds: interval.inMilliseconds + extraMs),
      () {
        start();
      },
    );
  }
}

class _ThreadPollHandle extends _BasePollHandle {
  final ApiClient api;
  final String my;
  final String other;
  final RealtimeCallback? onInsert;
  String? _lastSeenId;
  _ThreadPollHandle({
    required this.api,
    required this.my,
    required this.other,
    this.onInsert,
  });

  @override
  Duration get interval => const Duration(seconds: 5);

  @override
  void tick() async {
    try {
      final data = await api.get(
        '/messages/thread',
        query: {'me': my, 'other': other},
      );
      final list = <Map<String, dynamic>>[];
      if (data is List) {
        for (final e in data) {
          if (e is Map) {
            list.add(e.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      }
      if (list.isEmpty) return;
      // Assume list is chronological ascending or we'll sort by created_at if present
      list.sort((a, b) {
        final at = a['created_at']?.toString() ?? '';
        final bt = b['created_at']?.toString() ?? '';
        return at.compareTo(bt);
      });
      // Emit new ones after last seen id
      final newOnes = _filterNew(list);
      if (newOnes.isNotEmpty && onInsert != null) {
        for (final row in newOnes) {
          await onInsert!.call(row);
        }
      }
      // Update last seen id to the last element
      final last = list.last;
      if (last['id'] != null) {
        _lastSeenId = last['id'].toString();
      }
    } catch (_) {
      _backoffOnce();
    }
  }

  List<Map<String, dynamic>> _filterNew(List<Map<String, dynamic>> list) {
    if (_lastSeenId == null) return list; // first tick: emit all
    final idx = list.indexWhere((e) => e['id']?.toString() == _lastSeenId);
    if (idx < 0) return list; // unknown last id; emit all
    if (idx >= list.length - 1) return const [];
    return list.sublist(idx + 1);
  }

  void _backoffOnce() {
    _timer?.cancel();
    final extraMs = 1000 + (DateTime.now().millisecond % 4000);
    _timer = Timer(
      Duration(milliseconds: interval.inMilliseconds + extraMs),
      () {
        start();
      },
    );
  }
}

class _UnreadPollHandle extends _BasePollHandle {
  final ApiClient api;
  final String my;
  final RealtimeCallback? onChange;
  int? _last;
  _UnreadPollHandle({required this.api, required this.my, this.onChange});

  @override
  Duration get interval => const Duration(seconds: 15);

  @override
  void tick() async {
    try {
      final data = await api.get(
        '/messages/unread-count',
        query: {'profileId': my},
      );
      int current = 0;
      if (data is num) current = data.toInt();
      if (data is Map && data['count'] is num)
        current = (data['count'] as num).toInt();
      if (_last == null || current != _last) {
        _last = current;
        if (onChange != null) await onChange!.call({'count': current});
      }
    } catch (_) {
      _backoffOnce();
    }
  }

  void _backoffOnce() {
    _timer?.cancel();
    final extraMs = 1000 + (DateTime.now().millisecond % 4000);
    _timer = Timer(
      Duration(milliseconds: interval.inMilliseconds + extraMs),
      () {
        start();
      },
    );
  }
}
