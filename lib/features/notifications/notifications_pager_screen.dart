import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/models/contact_request.dart';
import '../../app/di/service_locator.dart';
import '../profile/profile_detail_screen.dart';
import '../../shared/models/profile.dart';
import '../../shared/widgets/storage_image.dart';

class NotificationsPagerScreen extends StatefulWidget {
  final int initialIndex; // 0: Accepted, 1: Interests, 2: Contact Requests
  const NotificationsPagerScreen({super.key, this.initialIndex = 0});

  @override
  State<NotificationsPagerScreen> createState() =>
      _NotificationsPagerScreenState();
}

class _NotificationsPagerScreenState extends State<NotificationsPagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loadingContacts = true;
  List<ContactRequest> _received = const [];
  List<ContactRequest> _sent = const [];
  // Cache of profile_id -> Profile for pretty names/avatars
  Map<String, Profile> _profilesByProfileId = const {};
  // Per-category seen baselines (store lengths last seen)
  int _seenAccepted = 0;
  int _seenInterests = 0;
  int _seenContacts = 0;
  String? _profileId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _markCurrentTabSeen();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final mat = context.read<MatrimonialProvider>();
      final uid = auth.user?.id;
      _profileId = mat.currentUserProfile?.id;
      if (uid != null) {
        final futures = <Future<void>>[];
        if (mat.shouldReloadReceived())
          futures.add(mat.loadReceivedInterests(uid));
        if (mat.shouldReloadAccepted())
          futures.add(mat.loadAcceptedConnections(uid));
        futures.add(mat.loadSentInterests(uid));
        if (futures.isNotEmpty) await Future.wait(futures);
      }
      await _loadContacts();
      await _loadSeenBaselines();
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _loadingContacts = true);
      final me = context.read<MatrimonialProvider>().currentUserProfile;
      if (me == null) {
        setState(() {
          _received = const [];
          _sent = const [];
          _loadingContacts = false;
          _profilesByProfileId = const {};
        });
        return;
      }
      final r = await sl.contactExchangeService.listReceived(me.id);
      final s = await sl.contactExchangeService.listSent(me.id);
      // Batch fetch display profiles for involved profile_ids
      try {
        final ids = <String>{
          ...r.map((e) => e.requesterProfileId),
          ...s.map((e) => e.targetProfileId),
        }..removeWhere((e) => e.isEmpty);
        if (ids.isNotEmpty) {
          final map = await sl.profileService.getProfilesByProfileIds(
            ids.toList(),
          );
          _profilesByProfileId = map;
        } else {
          _profilesByProfileId = const {};
        }
      } catch (_) {
        _profilesByProfileId = const {};
      }
      if (!mounted) return;
      setState(() {
        _received = r;
        _sent = s;
        _loadingContacts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingContacts = false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mat = context.watch<MatrimonialProvider>();
    final acceptedCount = mat.acceptedConnections.length;
    final interestsCount = mat.receivedInterests.length;
    final contactsPending = _received
        .where((r) => r.status == ContactRequestStatus.pending)
        .length;
    final acceptedUnseen = (acceptedCount - _seenAccepted).clamp(0, 9999);
    final interestsUnseen = (interestsCount - _seenInterests).clamp(0, 9999);
    final contactsUnseen = (contactsPending - _seenContacts).clamp(0, 9999);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            _TabLabel(title: 'Accepted', count: acceptedUnseen),
            _TabLabel(title: 'Interests', count: interestsUnseen),
            _TabLabel(title: 'Contact Requests', count: contactsUnseen),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _AcceptedTab(),
          _InterestsTab(),
          _ContactRequestsTab(
            loading: _loadingContacts,
            received: _received,
            sent: _sent,
            profilesByProfileId: _profilesByProfileId,
            onRefresh: _loadContacts,
          ),
        ],
      ),
    );
  }

  Future<void> _loadSeenBaselines() async {
    if (_profileId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _seenAccepted = prefs.getInt(_key('accepted')) ?? 0;
      _seenInterests = prefs.getInt(_key('interests')) ?? 0;
      _seenContacts = prefs.getInt(_key('contacts')) ?? 0;
    } catch (_) {}
  }

  Future<void> _saveSeenBaselines() async {
    if (_profileId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key('accepted'), _seenAccepted);
      await prefs.setInt(_key('interests'), _seenInterests);
      await prefs.setInt(_key('contacts'), _seenContacts);
    } catch (_) {}
  }

  void _markCurrentTabSeen() {
    if (!mounted) return;
    final mat = context.read<MatrimonialProvider>();
    _profileId ??= mat.currentUserProfile?.id;
    if (_profileId == null) return;
    switch (_tab.index) {
      case 0: // Accepted
        _seenAccepted = mat.acceptedConnections.length;
        break;
      case 1: // Interests
        _seenInterests = mat.receivedInterests.length;
        break;
      case 2: // Contacts
        _seenContacts = _received
            .where((r) => r.status == ContactRequestStatus.pending)
            .length;
        break;
    }
    _saveSeenBaselines();
    setState(() {});
  }

  String _key(String category) =>
      'notif_seen_len_${category}_${_profileId ?? ''}';
}

class _TabLabel extends StatelessWidget {
  final String title;
  final int count;
  const _TabLabel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final show = count > 0;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(title)),
          ),
          if (show) ...[
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 20, maxWidth: 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AcceptedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MatrimonialProvider>(
      builder: (context, mat, _) {
        final items = mat.acceptedConnections;
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No accepted connections yet',
            subtitle: 'When interests are accepted, they appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final u = items[index];
            return _ProfileTile(u, trailing: const Icon(Icons.chevron_right));
          },
        );
      },
    );
  }
}

class _InterestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MatrimonialProvider, AuthProvider>(
      builder: (context, mat, auth, _) {
        final items = mat.receivedInterests;
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border,
            title: 'No new requests',
            subtitle: 'Interests received will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = items[index];
            return _ProfileTile(
              p,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      final uid = auth.user?.id;
                      if (uid == null) return;
                      await mat.rejectInterest(
                        fromProfileId: p.id,
                        toAuthUserId: uid,
                      );
                    },
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final uid = auth.user?.id;
                      if (uid == null) return;
                      await mat.acceptInterest(
                        fromProfileId: p.id,
                        toAuthUserId: uid,
                      );
                    },
                    child: const Text('Accept'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ContactRequestsTab extends StatelessWidget {
  final bool loading;
  final List<ContactRequest> received;
  final List<ContactRequest> sent;
  final Future<void> Function() onRefresh;
  final Map<String, Profile> profilesByProfileId;
  const _ContactRequestsTab({
    required this.loading,
    required this.received,
    required this.sent,
    required this.profilesByProfileId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final mat = context.read<MatrimonialProvider>();
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          const _SectionHeader('Received (approve/decline)'),
          ...received.map(
            (r) => ListTile(
              leading: _avatarFor(r.requesterProfileId),
              title: Text('From: ${_nameFor(r.requesterProfileId)}'),
              subtitle: Text('Requested at: ${r.createdAt.toLocal()}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      final me = mat.currentUserProfile;
                      if (me == null) return;
                      await sl.contactExchangeService.decline(
                        me.id,
                        r.requesterProfileId,
                      );
                      await onRefresh();
                    },
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final me = mat.currentUserProfile;
                      if (me == null) return;
                      await sl.contactExchangeService.accept(
                        me.id,
                        r.requesterProfileId,
                      );
                      await onRefresh();
                    },
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ),
          ),
          if (received.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No received requests.'),
            ),
          const Divider(height: 1),
          const _SectionHeader('Sent (pending)'),
          ...sent.map(
            (s) => ListTile(
              leading: _avatarFor(s.targetProfileId),
              title: Text('To: ${_nameFor(s.targetProfileId)}'),
              subtitle: Text('Status: ${s.status.value}'),
            ),
          ),
          if (sent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No sent requests.'),
            ),
        ],
      ),
    );
  }

  String _nameFor(String profileId) {
    final p = profilesByProfileId[profileId];
    if (p == null) return profileId;
    return (p.name.isNotEmpty ? p.name : profileId);
  }

  Widget _avatarFor(String profileId) {
    final p = profilesByProfileId[profileId];
    final title = _nameFor(profileId);
    if (p?.imageUrl != null && p!.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
        child: ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: StorageImage(src: p.imageUrl!, fit: BoxFit.cover),
          ),
        ),
      );
    }
    return CircleAvatar(
      child: Text(
        title.isNotEmpty ? title.characters.first.toUpperCase() : '?',
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final MatrimonialUser user;
  final Widget? trailing;
  const _ProfileTile(this.user, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(user.displayName.isNotEmpty ? user.displayName : user.name),
      subtitle: Text(
        '${user.age} · ${user.city.isNotEmpty ? user.city : user.district}',
      ),
      trailing: trailing,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: user)),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}
