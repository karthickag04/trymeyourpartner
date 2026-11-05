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
import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';
import '../../shared/widgets/count_badge.dart';
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
    // A deep brand colour in both themes, so the white title stays readable.
    final onBar = context.palette.onImage;
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      backgroundColor: context.palette.brandGradient.first,
      foregroundColor: onBar,
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
                      name != null && name.isNotEmpty
                          ? context.l10n.greetingWithName(greeting, name)
                          : greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.styles.caption.copyWith(
                        color: onBar.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.homeSubtitle,
                style: context.styles.caption.copyWith(
                  color: onBar.withValues(alpha: 0.9),
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
          child: _NotificationsButton(color: onBar),
        ),
        // Messages button with unread badge
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _MessagesButton(color: onBar),
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
      _Stat(
        context.l10n.statMatches,
        p.matchedProfiles.length,
        Icons.favorite_rounded,
      ),
      _Stat(
        context.l10n.statShortlisted,
        p.shortlistedByMe.length,
        Icons.star_rounded,
      ),
      _Stat(
        context.l10n.statViewedYou,
        p.viewersOfMe.length,
        Icons.remove_red_eye_rounded,
      ),
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
    if (h < 12) return context.l10n.greetingMorning;
    if (h < 17) return context.l10n.greetingAfternoon;
    return context.l10n.greetingEvening;
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
        title: context.l10n.homeTopPicks,
        emptyHint: context.l10n.homeEmptyTopPicks,
        items: p.getTopPicks(limit: 10),
        onSeeAll: () => _openMatchesTab(context, 1),
      ),
      // Your matches
      _buildSection(
        context,
        title: context.l10n.homeYourMatches,
        emptyHint: context.l10n.homeEmptyMatches,
        items: p.matchedProfiles,
        onSeeAll: () => _openMatchesTab(context, 0),
      ),
      // Viewed you
      _buildSection(
        context,
        title: context.l10n.homeViewedYou,
        emptyHint: context.l10n.homeEmptyViewedYou,
        items: p.viewersOfMe,
        onSeeAll: () => _openMatchesTab(context, 6),
      ),
      // New this week (See all opens Search with newest filter)
      _buildSection(
        context,
        title: context.l10n.homeNewThisWeek,
        emptyHint: context.l10n.homeEmptyNewThisWeek,
        items: p.newThisWeek,
        onSeeAll: () => _openSearchForNewThisWeek(context),
      ),
      // Viewed by you
      _buildSection(
        context,
        title: context.l10n.homeViewedByYou,
        emptyHint: context.l10n.homeEmptyViewedByYou,
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
    required String emptyHint,
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
              TextButton(
                onPressed: onSeeAll,
                child: Text(context.l10n.homeSeeAll),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
              child: Text(
                emptyHint,
                style: TextStyle(color: context.palette.textSecondary),
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
            color: context.palette.shadow,
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
                  context.l10n.homeCompleteProfileTitle,
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
                  context.l10n.homeCompleteProfileProgress(percent),
                  style: Theme.of(context).textTheme.bodySmall,
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
            label: Text(context.l10n.homeCompleteAction),
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
            color: context.palette.shadow,
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
                  context.l10n.homeDeactivatedTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.homeDeactivatedBody,
                  style: Theme.of(context).textTheme.bodySmall,
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
                    SnackBar(content: Text(context.l10n.profileReactivated)),
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
                  SnackBar(content: Text(context.l10n.profileReactivateFailed)),
                );
              }
            },
            icon: const Icon(Icons.play_circle_fill),
            label: Text(context.l10n.actionReactivate),
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
          tooltip: context.l10n.notificationsTitle,
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
            child: CountBadge(
              count: _combined - _lastSeenCombined,
              semanticLabel: context.l10n.newItemsLabel(
                _combined - _lastSeenCombined,
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
          tooltip: context.l10n.messagesTitle,
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
            child: CountBadge(
              count: _unread,
              semanticLabel: context.l10n.unreadCountLabel(_unread),
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
    final titleText = context.l10n.appName;

    final blackStroke = TextSpan(
      text: titleText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = context.palette.imageScrim,
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
          ..color = context.palette.onImage,
      ),
    );

    final fill = TextSpan(
      text: titleText,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: context.palette.onImage.withValues(alpha: 0.96),
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

    return Semantics(
      label: context.l10n.statLabel(stat.title, stat.count),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.palette.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.palette.shadow,
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
              context.formatNumber(stat.count),
              style: TextStyle(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
