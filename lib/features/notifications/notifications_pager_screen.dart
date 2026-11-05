import 'package:flutter/material.dart';
import '../../app/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/models/contact_request.dart';
import '../../app/di/service_locator.dart';
import '../../shared/models/profile.dart';
import '../../shared/widgets/storage_image.dart';
import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';
import '../../shared/widgets/count_badge.dart';

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
        title: Text(context.l10n.notificationsTitle),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: [
            _TabLabel(
              title: context.l10n.notificationsTabAccepted,
              count: acceptedUnseen,
            ),
            _TabLabel(
              title: context.l10n.notificationsTabInterests,
              count: interestsUnseen,
            ),
            _TabLabel(
              title: context.l10n.notificationsTabContactRequests,
              count: contactsUnseen,
            ),
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
            CountBadge(
              count: count,
              semanticLabel: context.l10n.newItemsLabel(count),
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
          return _EmptyState(
            icon: Icons.handshake_outlined,
            title: context.l10n.acceptedEmptyTitle,
            subtitle: context.l10n.acceptedEmptySubtitle,
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
          return _EmptyState(
            icon: Icons.favorite_border,
            title: context.l10n.interestsEmptyTitle,
            subtitle: context.l10n.interestsEmptySubtitle,
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
                    child: Text(context.l10n.actionDecline),
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
                    child: Text(context.l10n.actionAccept),
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
          _SectionHeader(context.l10n.contactReceivedHeader),
          ...received.map(
            (r) => ListTile(
              leading: _avatarFor(context, r.requesterProfileId),
              title: Text(
                context.l10n.contactFrom(_nameFor(r.requesterProfileId)),
              ),
              subtitle: Text(
                context.l10n.contactRequestedAt(
                  context.formatDateTime(r.createdAt),
                ),
              ),
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
                    child: Text(context.l10n.actionDecline),
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
                    child: Text(context.l10n.actionApprove),
                  ),
                ],
              ),
            ),
          ),
          if (received.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Text(context.l10n.contactNoReceived),
            ),
          const Divider(height: 1),
          _SectionHeader(context.l10n.contactSentHeader),
          ...sent.map(
            (s) => ListTile(
              leading: _avatarFor(context, s.targetProfileId),
              title: Text(context.l10n.contactTo(_nameFor(s.targetProfileId))),
              subtitle: Text(
                context.l10n.contactRequestStatus(
                  _statusLabel(context, s.status),
                ),
              ),
            ),
          ),
          if (sent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Text(context.l10n.contactNoSent),
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

  String _statusLabel(BuildContext context, ContactRequestStatus status) {
    final l = context.l10n;
    return switch (status) {
      ContactRequestStatus.pending => l.contactStatusPending,
      ContactRequestStatus.accepted => l.contactStatusAccepted,
      ContactRequestStatus.declined => l.contactStatusDeclined,
      ContactRequestStatus.cancelled => l.contactStatusCancelled,
    };
  }

  Widget _avatarFor(BuildContext context, String profileId) {
    final p = profilesByProfileId[profileId];
    final title = _nameFor(profileId);
    if (p?.imageUrl != null && p!.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: context.palette.surfaceMuted,
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
        context.l10n.profileAgePlace(
          user.age,
          user.city.isNotEmpty ? user.city : user.district,
        ),
      ),
      trailing: trailing,
      onTap: () => openProfile(context, user),
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
          Icon(icon, size: 64, color: context.palette.textTertiary),
          const SizedBox(height: AppDimensions.paddingSM),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.styles.title.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            subtitle,
            style: context.styles.body2.copyWith(
              color: context.palette.textTertiary,
            ),
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
