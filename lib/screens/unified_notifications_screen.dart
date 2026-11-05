import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/matrimonial_provider.dart';
import '../providers/auth_provider.dart';
import '../models/matrimonial_user.dart';
import '../models/contact_request.dart';
import '../di/service_locator.dart';
import 'notifications_pager_screen.dart';
import '../domain/models/profile.dart';

enum _NotifType { interestRequest, interestAccepted, contactRequest }

class UnifiedNotificationsScreen extends StatefulWidget {
  const UnifiedNotificationsScreen({super.key});

  @override
  State<UnifiedNotificationsScreen> createState() =>
      _UnifiedNotificationsScreenState();
}

class _UnifiedNotificationsScreenState
    extends State<UnifiedNotificationsScreen> {
  bool _loading = true;
  List<_NotificationItem> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final mat = context.read<MatrimonialProvider>();
      final uid = auth.user?.id;
      final me = mat.currentUserProfile;
      if (uid == null || me == null) {
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }
      final futures = <Future<void>>[];
      if (mat.shouldReloadReceived())
        futures.add(mat.loadReceivedInterests(uid));
      if (mat.shouldReloadAccepted())
        futures.add(mat.loadAcceptedConnections(uid));
      if (futures.isNotEmpty) await Future.wait(futures);
      final contacts = await sl.contactExchangeService.listReceived(me.id);
      // Preload names for contact request counterparts
      final contactIds = <String>{
        for (final r in contacts)
          if (r.status == ContactRequestStatus.pending) r.requesterProfileId,
      }..removeWhere((e) => e.isEmpty);
      Map<String, Profile> nameMap = const {};
      if (contactIds.isNotEmpty) {
        try {
          nameMap = await sl.profileService.getProfilesByProfileIds(
            contactIds.toList(),
          );
        } catch (_) {
          nameMap = const {};
        }
      }

      final list = <_NotificationItem>[];
      // Interest requests (received)
      for (final u in mat.receivedInterests) {
        list.add(_NotificationItem(type: _NotifType.interestRequest, other: u));
      }
      // Accepted connections
      for (final u in mat.acceptedConnections) {
        list.add(
          _NotificationItem(type: _NotifType.interestAccepted, other: u),
        );
      }
      // Contact requests (received pending)
      for (final r in contacts) {
        if (r.status == ContactRequestStatus.pending) {
          // Best-effort: try to map requester id to a profile in provider lists
          final match = _findUserById(mat, r.requesterProfileId);
          final prof = nameMap[r.requesterProfileId];
          list.add(
            _NotificationItem(
              type: _NotifType.contactRequest,
              other: match,
              fallbackOtherProfileId: r.requesterProfileId,
              fallbackOtherName: prof?.name,
              contact: r,
            ),
          );
        }
      }

      // Sort newest first using available timestamps; fall back to type order
      int ts(_NotificationItem i) {
        // Prefer contact createdAt when present
        final t = i.contact?.createdAt;
        return t?.millisecondsSinceEpoch ?? 0;
      }

      list.sort((a, b) => ts(b).compareTo(ts(a)));

      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  MatrimonialUser? _findUserById(MatrimonialProvider mat, String id) {
    MatrimonialUser? pick(List<MatrimonialUser> list) =>
        list.where((e) => e.id == id).cast<MatrimonialUser?>().firstOrNull;
    return pick(mat.matchedProfiles) ??
        pick(mat.receivedInterests) ??
        pick(mat.sentInterests) ??
        pick(mat.acceptedConnections) ??
        pick(mat.viewedProfiles) ??
        pick(mat.viewersOfMe) ??
        pick(mat.shortlistedByMe) ??
        pick(mat.shortlistedMe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const _Empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _Tile(item: _items[index], onChanged: _load),
              ),
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  final _NotificationItem item;
  final VoidCallback onChanged;
  const _Tile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final mat = context.read<MatrimonialProvider>();
    final auth = context.read<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    final otherName =
        item.other?.displayName ??
        (item.fallbackOtherName != null && item.fallbackOtherName!.isNotEmpty
            ? item.fallbackOtherName!
            : (item.fallbackOtherProfileId != null
                  ? 'Profile ${item.fallbackOtherProfileId}'
                  : 'Someone'));

    IconData icon;
    String title;
    String subtitle;
    List<Widget> trailing = [];

    switch (item.type) {
      case _NotifType.interestRequest:
        icon = Icons.favorite_border;
        title = 'New interest from $otherName';
        subtitle = 'Tap to view profile';
        trailing = [
          TextButton(
            onPressed: () async {
              final uid = auth.user?.id;
              final other = item.other;
              if (uid == null || other == null) return;
              await mat.acceptInterest(
                fromProfileId: other.id,
                toAuthUserId: uid,
              );
              if (context.mounted) onChanged();
            },
            child: const Text('Accept'),
          ),
          TextButton(
            onPressed: () async {
              final uid = auth.user?.id;
              final other = item.other;
              if (uid == null || other == null) return;
              await mat.rejectInterest(
                fromProfileId: other.id,
                toAuthUserId: uid,
              );
              if (context.mounted) onChanged();
            },
            child: const Text('Decline'),
          ),
        ];
        break;
      case _NotifType.interestAccepted:
        icon = Icons.handshake_outlined;
        title = '$otherName accepted your interest';
        subtitle = 'Start a conversation';
        break;
      case _NotifType.contactRequest:
        icon = Icons.contact_phone_outlined;
        title = 'Contact request from $otherName';
        subtitle = 'Approve to share contact number';
        trailing = [
          TextButton(
            onPressed: () async {
              final me = mat.currentUserProfile;
              final r = item.contact;
              if (me == null || r == null) return;
              await sl.contactExchangeService.decline(
                me.id,
                r.requesterProfileId,
              );
              if (context.mounted) onChanged();
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () async {
              final me = mat.currentUserProfile;
              final r = item.contact;
              if (me == null || r == null) return;
              await sl.contactExchangeService.accept(
                me.id,
                r.requesterProfileId,
              );
              if (context.mounted) onChanged();
            },
            child: const Text('Approve'),
          ),
        ];
        break;
    }

    String fmt(DateTime dt) {
      try {
        final locale = Localizations.localeOf(context).toString();
        // Show time if today, else short date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final d = DateTime(dt.year, dt.month, dt.day);
        if (d == today) return DateFormat.jm(locale).format(dt);
        return DateFormat.yMMMd(locale).format(dt);
      } catch (_) {
        return dt.toLocal().toString();
      }
    }

    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (item.contact?.createdAt != null)
            Text(
              fmt(item.contact!.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      onTap: () {
        // Always open the pager, focusing the relevant tab
        final index = switch (item.type) {
          _NotifType.interestAccepted => 0,
          _NotifType.interestRequest => 1,
          _NotifType.contactRequest => 2,
        };
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NotificationsPagerScreen(initialIndex: index),
          ),
        );
      },
      trailing: trailing.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: trailing),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No notifications yet.'),
      ),
    );
  }
}

class _NotificationItem {
  final _NotifType type;
  final MatrimonialUser? other;
  final String? fallbackOtherProfileId;
  final String? fallbackOtherName;
  final ContactRequest? contact;
  const _NotificationItem({
    required this.type,
    required this.other,
    this.fallbackOtherProfileId,
    this.fallbackOtherName,
    this.contact,
  });
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
