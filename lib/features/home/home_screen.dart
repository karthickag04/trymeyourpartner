import 'package:flutter/material.dart';
import '../../app/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../../shared/state/matrimonial_provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../profile/widgets/profile_card.dart';
import '../discovery/search_screen.dart';
import '../notifications/notifications_pager_screen.dart';
import '../../shared/models/contact_request.dart';
import '../discovery/matches_screen.dart';
import '../chat/messages_inbox_screen.dart';
import '../../app/di/service_locator.dart';
import '../profile/profile_edit_screen.dart';
import '../../shared/services/matrimonial_service.dart';
import '../auth/auth_provider.dart';
// no direct model import needed here

class NewMatrimonialHomeScreen extends StatefulWidget {
  const NewMatrimonialHomeScreen({super.key});

  @override
  State<NewMatrimonialHomeScreen> createState() =>
      _NewMatrimonialHomeScreenState();
}

class _NewMatrimonialHomeScreenState extends State<NewMatrimonialHomeScreen> {
  // Horizontal panels UX; no section index needed.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MatrimonialProvider>(
        builder: (context, p, _) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, p),
              _buildQuickStats(context, p),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              _buildVerticalSections(context, p),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, MatrimonialProvider p) {
    final name = p.currentUserProfile?.displayName;
    final greeting = _greeting();
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      backgroundColor: scheme.primary,
      expandedHeight: 120,
      title: _StyledAppTitle(fontSize: 22),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 36,
            bottom: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$greeting${name != null && name.isNotEmpty ? ", $name" : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Try Me For Your Partner Selection',
                style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Notifications button with combined badge (interests + pending contact requests)
        Padding(
          padding: const EdgeInsets.only(right: 0),
          child: _NotificationsButton(color: scheme.onPrimary),
        ),
        // Messages button with unread badge
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _MessagesButton(color: scheme.onPrimary),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildQuickStats(
    BuildContext context,
    MatrimonialProvider p,
  ) {
    // Only key stats; notification count removed
    final stats = [
      _Stat('Matches', p.matchedProfiles.length, Icons.favorite_rounded),
      _Stat('Shortlisted', p.shortlistedByMe.length, Icons.star_rounded),
      _Stat('Viewed You', p.viewersOfMe.length, Icons.remove_red_eye_rounded),
    ];
    final profile = p.currentUserProfile;
    final pct = profile == null ? null : p.completionPercent(profile);
    final isDeactivated = profile != null && profile.isActive == false;
    final showBanner =
        profile != null && (isDeactivated || (pct != null && pct < 100));
    return SliverToBoxAdapter(
      child: Column(
        children: [
          if (showBanner)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: isDeactivated
                  ? _ReactivateProfileBanner()
                  : _IncompleteProfileBanner(percent: pct ?? 0),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  for (int i = 0; i < stats.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 4,
                          right: i == stats.length - 1 ? 0 : 4,
                        ),
                        child: _StatPill(stat: stats[i]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ---- Section switcher UI (replaced by horizontal panels) ----

  // ---- Vertical multi-list home ----
  SliverToBoxAdapter _buildVerticalSections(
    BuildContext context,
    MatrimonialProvider p,
  ) {
    final sections = <Widget>[
      // Top Picks
      _buildSection(
        context,
        title: 'Top picks for you',
        items: p.getTopPicks(limit: 10),
        onSeeAll: () => _openMatchesTab(context, 1),
      ),
      // Your matches
      _buildSection(
        context,
        title: 'Your matches',
        items: p.matchedProfiles,
        onSeeAll: () => _openMatchesTab(context, 0),
      ),
      // Viewed you
      _buildSection(
        context,
        title: 'Viewed you',
        items: p.viewersOfMe,
        onSeeAll: () => _openMatchesTab(context, 6),
      ),
      // New this week (See all opens Search with newest filter)
      _buildSection(
        context,
        title: 'New this week',
        items: p.newThisWeek,
        onSeeAll: () => _openSearchForNewThisWeek(context),
      ),
      // Viewed by you
      _buildSection(
        context,
        title: 'Viewed by you',
        items: p.viewedProfiles,
        onSeeAll: () => _openMatchesTab(context, 5),
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: sections),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<MatrimonialUser> items,
    required VoidCallback onSeeAll,
  }) {
    final p = Provider.of<MatrimonialProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
              child: Text(
                _emptyHintFor(title),
                style: TextStyle(color: Colors.grey[700]),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final u = items[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(
                      right: index == items.length - 1 ? 0 : 12,
                    ),
                    child: ProfileCard(
                      profile: u,
                      onTap: () => _navigateToProfileDetail(context, u),
                      isShortlisted: p.isProfileShortlisted(u.id),
                      isInterestSent: p.isInterestSent(u.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _emptyHintFor(String title) {
    switch (title) {
      case 'Top picks for you':
        return 'No top picks yet. We\'ll show highly compatible profiles here soon.';
      case 'Your matches':
        return 'No matches yet. Update your preferences or try searching.';
      case 'Viewed you':
        return 'No one has viewed your profile yet.';
      case 'New this week':
        return 'No new profiles in the last 7 days yet.';
      case 'Viewed by you':
        return 'Start viewing profiles to see them here.';
      default:
        return 'Nothing to show yet.';
    }
  }

  // Navigation helpers
  void _navigateToProfileDetail(BuildContext context, MatrimonialUser profile) {
    openProfile(context, profile);
  }

  void _openMatchesTab(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MatchesScreen(initialTabIndex: index)),
    );
  }

  void _openSearchForNewThisWeek(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(
          initialSortBy: 'newest',
          initialJoinedWithinDays: 7,
          autoSearch: true,
        ),
      ),
    );
  }
}

class _IncompleteProfileBanner extends StatelessWidget {
  final int percent;
  const _IncompleteProfileBanner({required this.percent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (percent.clamp(0, 100)) / 100.0,
                    minHeight: 8,
                    backgroundColor: scheme.primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$percent% complete · Get better matches with full details',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class _ReactivateProfileBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = context.read<MatrimonialProvider>();
    final me = p.currentUserProfile;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.pause_circle_filled, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your profile is deactivated',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reactivate your profile to send/receive messages and appear in searches.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () async {
              if (me == null) return;
              try {
                final ok = await MatrimonialService.reactivateProfile(me.id);
                if (!context.mounted) return;
                if (ok) {
                  final authUserId =
                      context.read<AuthProvider>().user?.id ?? '';
                  await p.forceRefreshUserData(authUserId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile reactivated')),
                  );
                  // After reactivation, encourage completion
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to reactivate: $e')),
                );
              }
            },
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }
}

class _MessagesButton extends StatefulWidget {
  final Color color;
  const _MessagesButton({required this.color});

  @override
  State<_MessagesButton> createState() => _MessagesButtonState();
}

class _NotificationsButton extends StatefulWidget {
  final Color color;
  const _NotificationsButton({required this.color});

  @override
  State<_NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<_NotificationsButton> {
  int _combined = 0;
  bool _loading = false;
  Timer? _poll;
  int _lastSeenCombined = 0;
  String? _lastProfileId;
  bool _baselineLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
    // If profile switches, load baseline for that profile
    final p = context.read<MatrimonialProvider>();
    final pid = p.currentUserProfile?.id;
    if (pid != null && pid != _lastProfileId) {
      _lastProfileId = pid;
      _baselineLoaded = false;
      _loadSeenBaseline(pid);
    }
  }

  @override
  void initState() {
    super.initState();
    // Lightweight polling to keep badge live across backends
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final mat = context.read<MatrimonialProvider>();
      final me = mat.currentUserProfile;
      final interests = mat.receivedInterests.length;
      final accepted = mat.acceptedConnections.length;
      int pendingContacts = 0;
      if (me != null) {
        try {
          final received = await sl.contactExchangeService.listReceived(me.id);
          pendingContacts = received
              .where((r) => r.status == ContactRequestStatus.pending)
              .length;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _combined = interests + accepted + pendingContacts);
      // Initialize baseline on first load for this profile to avoid stale spikes
      if (!_baselineLoaded && me != null) {
        final prefs = await SharedPreferences.getInstance();
        final key = _prefsKey(me.id);
        if (!prefs.containsKey(key)) {
          await prefs.setInt(key, _combined);
          if (mounted) setState(() => _lastSeenCombined = _combined);
        }
        _baselineLoaded = true;
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> _loadSeenBaseline(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefsKey(profileId);
      final v = prefs.getInt(key) ?? 0;
      if (!mounted) return;
      setState(() => _lastSeenCombined = v);
    } catch (_) {}
  }

  Future<void> _saveSeenBaseline(String profileId, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey(profileId), value);
    } catch (_) {}
  }

  String _prefsKey(String profileId) => 'notif_last_seen_combined_$profileId';

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () async {
            // Mark current combined as seen before navigating
            final pid = context
                .read<MatrimonialProvider>()
                .currentUserProfile
                ?.id;
            if (pid != null) {
              await _saveSeenBaseline(pid, _combined);
              if (mounted) setState(() => _lastSeenCombined = _combined);
            }
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationsPagerScreen(),
              ),
            );
            // refresh badge when returning
            _refresh();
          },
          icon: Icon(Icons.notifications, color: widget.color),
        ),
        // Show unseen, not total
        if ((_combined - _lastSeenCombined) > 0)
          Positioned(
            right: 4,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                (() {
                  final unseen = _combined - _lastSeenCombined;
                  final v = unseen < 0 ? 0 : unseen;
                  return v > 99 ? '99+' : '$v';
                })(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    _poll = null;
    super.dispose();
  }
}

class _MessagesButtonState extends State<_MessagesButton> {
  int _unread = 0;
  String? _lastProfileId;
  Object? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.read<MatrimonialProvider>();
    final currentId = p.currentUserProfile?.id;
    if (currentId != null && currentId != _lastProfileId) {
      // Profile changed: tear down previous subscription and reload
      if (_sub != null) {
        try {
          sl.realtimeService.unsubscribe(_sub);
        } catch (_) {}
        _sub = null;
      }
      _lastProfileId = currentId;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final p = context.read<MatrimonialProvider>();
      final my = p.currentUserProfile?.id;
      if (my == null) return;
      _lastProfileId = my;
      final cnt = await sl.messageService.getUnreadCount(my);
      if (!mounted) return;
      setState(() => _unread = cnt);
      // Start realtime/poll subscription for live updates
      _sub ??= await sl.realtimeService.subscribeUnreadCounter(
        my,
        onChange: (_) async {
          try {
            final newCnt = await sl.messageService.getUnreadCount(my);
            if (mounted) setState(() => _unread = newCnt);
          } catch (_) {}
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_sub != null) {
      try {
        sl.realtimeService.unsubscribe(_sub);
      } catch (_) {}
      _sub = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesInboxScreen()),
            );
            // Refresh badge when returning
            _load();
          },
          icon: Icon(Icons.chat_bubble_outline, color: widget.color),
        ),
        if (_unread > 0)
          Positioned(
            right: 4,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _unread > 99 ? '99+' : '$_unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StyledAppTitle extends StatelessWidget {
  final double fontSize;
  const _StyledAppTitle({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    const titleText = 'TryMeYourPartner';

    final blackStroke = TextSpan(
      text: titleText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = Colors.black,
      ),
    );

    final whiteStroke = TextSpan(
      text: titleText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.02
          ..color = Colors.white,
      ),
    );

    final fill = TextSpan(
      text: titleText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: const Color.fromARGB(255, 246, 246, 246),
      ),
    );

    return Stack(
      children: [
        RichText(text: blackStroke),
        RichText(text: whiteStroke),
        RichText(text: fill),
      ],
    );
  }
}

class _Stat {
  final String title;
  final int count;
  final IconData icon;
  const _Stat(this.title, this.count, this.icon);
}

class _StatPill extends StatelessWidget {
  final _Stat stat;
  const _StatPill({required this.stat});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.of(context).size.width;
    double scale = width / 400.0;
    if (scale < 0.8) scale = 0.8; // keep readability
    if (scale > 1.0) scale = 1.0; // stay compact

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 16 * scale, color: primary),
          SizedBox(width: 6 * scale),
          Text(
            '${stat.count}',
            style: TextStyle(
              fontSize: 13 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
