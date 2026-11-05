import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../app/di/service_locator.dart';
import 'chat_thread_screen.dart';
import '../../core/services/profile_service.dart';
import '../../shared/widgets/storage_image.dart';
import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final Map<String, int> _unreadByPeer = {};
  bool _loadingBatch = false;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<MatrimonialProvider>().currentUserProfile;
    final myId = me?.id;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.messagesTitle)),
      body: myId == null
          ? Center(child: Text(context.l10n.messagesSignInRequired))
          : FutureBuilder<List<_InboxItem>>(
              future: _fetchInbox(myId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.l10n.messagesLoadFailed),
                        const SizedBox(height: AppDimensions.paddingS),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: Text(context.l10n.commonRetry),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(child: Text(context.l10n.messagesEmpty));
                }
                // Batch-load unread counts once per visible set
                Future.microtask(() => _loadUnreadBatchIfNeeded(myId, items));
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = items[index];
                    final initials =
                        (c.otherName?.isNotEmpty == true
                                ? c.otherName!
                                : c.otherProfileId)
                            .characters
                            .first
                            .toUpperCase();
                    return FutureBuilder<bool?>(
                      future: sl.matrimonialService.isProfileActive(
                        c.otherProfileId,
                      ),
                      builder: (context, activeSnap) {
                        final isActive = activeSnap.data;
                        final showName = (isActive == false)
                            ? context.l10n.profileNotActive
                            : (c.otherName ?? c.otherProfileId);
                        final unread = _unreadByPeer[c.otherProfileId] ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.palette.surfaceMuted,
                            child:
                                (c.otherImageUrl != null &&
                                    c.otherImageUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: StorageImage(
                                        src: c.otherImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Text(initials),
                          ),
                          title: Text(showName),
                          subtitle: Text(
                            c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _fmtTime(c.lastAt.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.palette.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Semantics(
                                    label: context.l10n.unreadCountLabel(
                                      unread,
                                    ),
                                    excludeSemantics: true,
                                    child: Text(
                                      unread > 99
                                          ? context.l10n.countOverflow(99)
                                          : context.formatNumber(unread),
                                      style: context.styles.micro.copyWith(
                                        color: context.colors.onError,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: (isActive == false)
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.l10n.profileNotActiveNow,
                                      ),
                                    ),
                                  );
                                }
                              : () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatThreadScreen(
                                        otherProfileId: c.otherProfileId,
                                        otherName: c.otherName,
                                        otherImageUrl: c.otherImageUrl,
                                      ),
                                    ),
                                  );
                                  // Refresh unread counts after returning
                                  if (!mounted) return;
                                  setState(() {
                                    _unreadByPeer.remove(c.otherProfileId);
                                  });
                                  _loadUnreadBatchIfNeeded(myId, [c]);
                                },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _loadUnreadBatchIfNeeded(
    String myId,
    List<_InboxItem> items,
  ) async {
    if (_loadingBatch) return;
    final missing = <String>[];
    for (final it in items) {
      if (!_unreadByPeer.containsKey(it.otherProfileId)) {
        missing.add(it.otherProfileId);
      }
    }
    if (missing.isEmpty) return;
    _loadingBatch = true;
    try {
      // Prefer batch API to minimize requests
      Map<String, int> res = {};
      try {
        res = await sl.messageService.getBatchThreadUnreadCounts(myId, missing);
      } catch (_) {
        // ignore; fallback below
      }
      // For any peers not in batch response, fallback to per-thread
      final stillMissing = missing.where((id) => !res.containsKey(id)).toList();
      if (stillMissing.isNotEmpty) {
        final futures = stillMissing.map((peer) async {
          try {
            final n = await sl.messageService.getThreadUnreadCount(myId, peer);
            return MapEntry(peer, n);
          } catch (_) {
            try {
              final n = await _fetchThreadUnread(myId, peer);
              return MapEntry(peer, n);
            } catch (_) {
              return MapEntry(peer, 0);
            }
          }
        }).toList();
        final results = await Future.wait(futures);
        for (final e in results) {
          res[e.key] = e.value;
        }
      }
      if (!mounted) return;
      setState(() {
        _unreadByPeer.addAll(res);
      });
    } finally {
      _loadingBatch = false;
    }
  }

  String _fmtTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day);
    return d == today ? context.formatTime(t) : context.formatDate(t);
  }
}

class _InboxItem {
  final String otherProfileId;
  final String lastMessage;
  final DateTime lastAt;
  final String? otherName;
  final String? otherImageUrl;

  _InboxItem({
    required this.otherProfileId,
    required this.lastMessage,
    required this.lastAt,
    this.otherName,
    this.otherImageUrl,
  });
}

Future<List<_InboxItem>> _fetchInbox(String myProfileId) async {
  final rows = await sl.messageService.getInbox(myProfileId);
  // Keep latest message per other profile
  final Map<String, _InboxItem> map = {};
  for (final row in rows) {
    final from = row['from_profile_id']?.toString();
    final to = row['to_profile_id']?.toString();
    final other = from == myProfileId ? to : from;
    if (other == null || other.isEmpty) continue;
    final text = (row['message'] ?? '').toString();
    final at =
        DateTime.tryParse(row['created_at']?.toString() ?? '') ??
        DateTime.now();
    final existing = map[other];
    if (existing == null || at.isAfter(existing.lastAt)) {
      map[other] = _InboxItem(
        otherProfileId: other,
        lastMessage: text,
        lastAt: at,
      );
    }
  }
  // Enrich with names/photos using ProfileService
  final otherIds = map.keys.toList();
  final enriched = await _enrichProfiles(otherIds);
  final merged = map.values.map((item) {
    final p = enriched[item.otherProfileId];
    return _InboxItem(
      otherProfileId: item.otherProfileId,
      lastMessage: item.lastMessage,
      lastAt: item.lastAt,
      otherName: p?.name,
      otherImageUrl: p?.imageUrl,
    );
  }).toList()..sort((a, b) => b.lastAt.compareTo(a.lastAt));
  return merged;
}

// Unread per thread: count receipts where receiver == myProfileId, from other
Future<int> _fetchThreadUnread(
  String myProfileId,
  String otherProfileId,
) async {
  // Prefer dedicated service API for performance; fallback to client-side count
  try {
    final count = await sl.messageService.getThreadUnreadCount(
      myProfileId,
      otherProfileId,
    );
    return count;
  } catch (_) {
    try {
      final thread = await sl.messageService.getThread(
        myProfileId,
        otherProfileId,
      );
      int unread = 0;
      for (final row in thread) {
        final to = row['to_profile_id']?.toString();
        final readAt = row['read_at']?.toString();
        if (to == myProfileId && (readAt == null || readAt.isEmpty)) {
          unread += 1;
        }
      }
      return unread;
    } catch (_) {
      return 0;
    }
  }
}

// Helper to fetch multiple profiles and map by id
Future<Map<String, _LiteProfile>> _enrichProfiles(List<String> ids) async {
  final ProfileService ps = sl.profileService;
  try {
    // Inbox keys are profile_ids, so fetch by profile ids
    final map = await ps.getProfilesByProfileIds(ids);
    return map.map((id, p) {
      // Image URL not part of Profile model; keep null unless added later
      return MapEntry(id, _LiteProfile(name: p.name, imageUrl: null));
    });
  } catch (_) {
    // Fall back to per-id fetch if batch is unsupported
    final Map<String, _LiteProfile> out = {};
    for (final id in ids) {
      try {
        final p = await ps.getProfileByProfileId(id);
        if (p != null) out[id] = _LiteProfile(name: p.name, imageUrl: null);
      } catch (_) {}
    }
    return out;
  }
}

class _LiteProfile {
  final String name;
  final String? imageUrl;
  const _LiteProfile({required this.name, this.imageUrl});
}
