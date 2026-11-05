import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/matrimonial_provider.dart';
import '../models/matrimonial_user.dart';
import '../utils/constants.dart';
import '../widgets/profile_card.dart';
import '../widgets/storage_image.dart';
import 'profile_detail_screen.dart';
import 'search_screen.dart';
import 'matches_screen.dart';
import 'profile_edit_screen.dart';
import 'viewers_screen.dart';

class MatrimonialHomeScreen extends StatefulWidget {
  const MatrimonialHomeScreen({super.key});

  @override
  State<MatrimonialHomeScreen> createState() => _MatrimonialHomeScreenState();
}

class _MatrimonialHomeScreenState extends State<MatrimonialHomeScreen> {
  // One-time render logs for visibility in console
  bool _loggedMatches = false;
  bool _loggedNewThisWeek = false;
  bool _loggedViewedYou = false;
  bool _loggedTopPicks = false;
  bool _loggedRecentlyActive = false;
  bool _loggedNearYou = false;
  bool _loggedSimilar = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  Future<void> _loadHomeData() async {
    final authProvider = context.read<AuthProvider>();
    final matrimonialProvider = context.read<MatrimonialProvider>();
    final userId = authProvider.user?.id;

    if (userId != null) {
      // Load user's matrimonial profile and matches
      await Future.wait([
        matrimonialProvider.loadCurrentUserProfile(userId),
        matrimonialProvider.loadMatches(userId),
        matrimonialProvider.loadReceivedInterests(userId),
        matrimonialProvider.loadShortlistedProfiles(userId),
        matrimonialProvider.loadViewersOfMe(userId),
        matrimonialProvider.loadNewThisWeek(userId),
        matrimonialProvider.loadSimilarToShortlisted(userId),
      ]);
      // Log a summary after data load
      debugPrint(
        '[Home] Data loaded: '
        'matches=${matrimonialProvider.matchedProfiles.length}, '
        'interests=${matrimonialProvider.receivedInterests.length}, '
        'shortlisted=${matrimonialProvider.shortlistedByMe.length}, '
        'viewedYou=${matrimonialProvider.viewersOfMe.length}, '
        'newThisWeek=${matrimonialProvider.newThisWeek.length}, '
        'similar=${matrimonialProvider.similarToShortlisted.length}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AuthProvider, MatrimonialProvider>(
        builder: (context, authProvider, matrimonialProvider, child) {
          final userId = authProvider.user?.id;

          if (userId == null) {
            return _buildSignInPrompt();
          }

          if (matrimonialProvider.isLoading &&
              matrimonialProvider.currentUserProfile == null) {
            return _buildLoadingScreen();
          }

          if (matrimonialProvider.error.isNotEmpty) {
            return _buildErrorScreen(matrimonialProvider.error);
          }

          return RefreshIndicator(
            onRefresh: _loadHomeData,
            child: CustomScrollView(
              slivers: [
                // App Bar with greeting
                _buildAppBar(authProvider, matrimonialProvider),

                // Welcome Section
                _buildWelcomeSection(matrimonialProvider),

                // Quick Stats
                _buildQuickStats(matrimonialProvider),

                // Recent Interests
                if (matrimonialProvider.receivedInterests.isNotEmpty)
                  _buildInterestsSection(matrimonialProvider),

                // New Matches
                if (matrimonialProvider.matchedProfiles.isNotEmpty) ...[
                  if (!_loggedMatches)
                    Builder(
                      builder: (_) {
                        _loggedMatches = true;
                        debugPrint(
                          '[Home] Rendering Matches section: '
                          '${matrimonialProvider.matchedProfiles.length} items',
                        );
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildMatchesSection(matrimonialProvider),
                ],

                // New this week (moved just below Matches)
                if (matrimonialProvider.newThisWeek.isNotEmpty) ...[
                  if (!_loggedNewThisWeek)
                    Builder(
                      builder: (_) {
                        _loggedNewThisWeek = true;
                        debugPrint(
                          '[Home] Rendering New this week: '
                          '${matrimonialProvider.newThisWeek.length} items',
                        );
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildNewThisWeekSection(matrimonialProvider),
                ],

                // People who viewed you (moved up to keep engagement high)
                if (matrimonialProvider.viewersOfMe.isNotEmpty) ...[
                  if (!_loggedViewedYou)
                    Builder(
                      builder: (_) {
                        _loggedViewedYou = true;
                        debugPrint(
                          '[Home] Rendering Viewed you: '
                          '${matrimonialProvider.viewersOfMe.length} items',
                        );
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildViewedYouSection(matrimonialProvider),
                ],

                // Top Picks (ranked locally)
                if (matrimonialProvider.matchedProfiles.isNotEmpty) ...[
                  if (!_loggedTopPicks)
                    Builder(
                      builder: (_) {
                        _loggedTopPicks = true;
                        debugPrint('[Home] Rendering Top Picks section');
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildTopPicksSection(matrimonialProvider),
                ],

                // Recently active (derived from matches)
                if (matrimonialProvider.matchedProfiles.isNotEmpty) ...[
                  if (!_loggedRecentlyActive)
                    Builder(
                      builder: (_) {
                        _loggedRecentlyActive = true;
                        debugPrint('[Home] Rendering Recently active section');
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildRecentlyActiveSection(matrimonialProvider),
                ],

                // Near you (derived from matches)
                if (matrimonialProvider.matchedProfiles.isNotEmpty) ...[
                  if (!_loggedNearYou)
                    Builder(
                      builder: (_) {
                        _loggedNearYou = true;
                        debugPrint('[Home] Rendering Near you section');
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildNearYouSection(matrimonialProvider),
                ],

                // Similar to your shortlisted
                if (matrimonialProvider.similarToShortlisted.isNotEmpty) ...[
                  if (!_loggedSimilar)
                    Builder(
                      builder: (_) {
                        _loggedSimilar = true;
                        debugPrint(
                          '[Home] Rendering Similar to shortlisted: '
                          '${matrimonialProvider.similarToShortlisted.length} items',
                        );
                        return const SizedBox.shrink();
                      },
                    ),
                  _buildSimilarSection(matrimonialProvider),
                ],

                // Profile Completion Prompt
                if (matrimonialProvider.currentUserProfile?.isProfileComplete !=
                    true)
                  _buildProfileCompletionPrompt(),

                // Footer spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.paddingXL),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(
    AuthProvider authProvider,
    MatrimonialProvider matrimonialProvider,
  ) {
    final user = authProvider.user;
    final profile = matrimonialProvider.currentUserProfile;

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    child: ClipOval(
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: (profile?.profileImageUrl?.isNotEmpty == true)
                            ? StorageImage(
                                src: profile!.profileImageUrl,
                                fit: BoxFit.cover,
                                placeholder: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: Center(
                                  child: Text(
                                    user?.email?.isNotEmpty == true
                                        ? user!.email![0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  user?.email?.isNotEmpty == true
                                      ? user!.email![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimensions.paddingM),

                  // Greeting and name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getGreeting(),
                          style: AppTextStyles.subtitle2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          profile?.name ?? user?.email?.split('@')[0] ?? 'User',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (profile?.isVerified == true)
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Profile',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Notification Icon with badge
                  IconButton(
                    onPressed: () => _showNotifications(),
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                        if (matrimonialProvider.receivedInterests.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${matrimonialProvider.receivedInterests.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(MatrimonialProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  'Find Your Perfect Match',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Discover compatible profiles from your community. Connect with people who share your values and preferences.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToSearch(),
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Profiles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToMatches(),
                    icon: const Icon(Icons.people),
                    label: const Text('View Matches'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(MatrimonialProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Profile Views',
                '${provider.currentUserProfile?.totalViews ?? 0}',
                Icons.visibility,
                AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildStatCard(
                'Interests Received',
                '${provider.receivedInterests.length}',
                Icons.favorite,
                AppColors.accent,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: _buildStatCard(
                'Matches',
                '${provider.matchedProfiles.length}',
                Icons.people,
                AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppDimensions.paddingS),
          Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
          Text(
            title,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4; // keep ratio similar to ProfileCard
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Interests', style: AppTextStyles.heading3),
                TextButton(
                  onPressed: () => _navigateToMatches(initialTab: 1),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: provider.receivedInterests.take(5).length,
              itemBuilder: (context, index) {
                final profile = provider.receivedInterests[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onAccept: () => _acceptInterest(profile),
                    onReject: () => _rejectInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                    isInterestSent: provider.isInterestSent(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.currentUserProfile == null
                      ? 'Recommended Profiles'
                      : 'New Matches',
                  style: AppTextStyles.heading3,
                ),
                TextButton(
                  onPressed: () => _navigateToMatches(),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: provider.matchedProfiles.take(5).length,
              itemBuilder: (context, index) {
                final profile = provider.matchedProfiles[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onInterest: () => _sendInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                    isInterestSent: provider.isInterestSent(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewThisWeekSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4;
    final items = provider.newThisWeek.take(10).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New this week', style: AppTextStyles.heading3),
                TextButton(
                  onPressed: () => _openSearchForNewThisWeek(),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final profile = items[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onInterest: () => _sendInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                    isInterestSent: provider.isInterestSent(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4;
    final items = provider.similarToShortlisted.take(10).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Similar to your shortlisted',
                  style: AppTextStyles.heading3,
                ),
                TextButton(
                  onPressed: () => _openSearchForSimilar(),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final profile = items[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onInterest: () => _sendInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                    isInterestSent: provider.isInterestSent(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPicksSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4;
    final items = provider.getTopPicks(limit: 10);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Picks for you', style: AppTextStyles.heading3),
                TextButton(
                  onPressed: () => _navigateToSearch(),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final profile = items[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onInterest: () => _sendInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                    isInterestSent: provider.isInterestSent(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewedYouSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4;
    final items = provider.viewersOfMe.take(10).toList();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('People who viewed you', style: AppTextStyles.heading3),
                TextButton(
                  onPressed: () => _openViewersScreen(),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final profile = items[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onInterest: () => _sendInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                    isInterestSent: provider.isInterestSent(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyActiveSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4;

    // Sort matches by lastActiveAt descending and take 10
    final items =
        provider.matchedProfiles.where((p) => p.lastActiveAt != null).toList()
          ..sort((a, b) => b.lastActiveAt!.compareTo(a.lastActiveAt!));
    final top = items.take(10).toList();

    if (top.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recently active', style: AppTextStyles.heading3),
                TextButton(
                  onPressed: () => _openSearchRecentlyActive(),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: top.length,
              itemBuilder: (context, index) {
                final profile = top[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onInterest: () => _sendInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearYouSection(MatrimonialProvider provider) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final cardWidth =
        (size.width - (AppDimensions.paddingM * 3)) / (isTablet ? 3 : 2);
    final cardHeight = cardWidth * 1.4;

    final me = provider.currentUserProfile;
    if (me == null) return const SliverToBoxAdapter(child: SizedBox());

    final items = provider.matchedProfiles
        .where((p) => p.state.isNotEmpty && p.state == me.state)
        .toList();
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final top = items.take(10).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingL,
              AppDimensions.paddingM,
              AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Near you (${me.state})', style: AppTextStyles.heading3),
                TextButton(
                  onPressed: () => _openSearchNearYou(me.state),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
              ),
              itemCount: top.length,
              itemBuilder: (context, index) {
                final profile = top[index];
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: AppDimensions.paddingM),
                  child: ProfileCard(
                    profile: profile,
                    onTap: () => _navigateToProfileDetail(profile),
                    onInterest: () => _sendInterest(profile),
                    onShortlist: () => _toggleShortlist(profile),
                    isShortlisted: provider.isProfileShortlisted(profile.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSearchRecentlyActive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(
          autoSearch: true,
          // Using recentlyActive flag will prioritize active users
          // The SearchScreen should read and trigger search accordingly
        ),
      ),
    );
    // Persist flag via provider to ensure Search picks it up
    final provider = context.read<MatrimonialProvider>();
    provider.lastSearchRecentlyActive = true;
  }

  void _openSearchNearYou(String state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialStateName: state, autoSearch: true),
      ),
    );
  }

  void _openSearchForNewThisWeek() {
    // Navigate to Search sorted by newest and auto-search
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SearchScreen(initialSortBy: 'newest', autoSearch: true),
      ),
    );
  }

  void _openViewersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewersScreen()),
    );
  }

  void _openSearchForSimilar() {
    final provider = context.read<MatrimonialProvider>();
    // Build signals from shortlisted profiles
    final shortlisted = provider.shortlistedProfiles;
    final castes = {
      for (final p in shortlisted)
        if (p.caste.isNotEmpty) p.caste,
    }.toList();
    // Choose most common state/district
    String? state;
    String? district;
    if (shortlisted.isNotEmpty) {
      final stateCounts = <String, int>{};
      final districtCounts = <String, int>{};
      for (final p in shortlisted) {
        if (p.state.isNotEmpty) {
          stateCounts[p.state] = (stateCounts[p.state] ?? 0) + 1;
        }
        if (p.district.isNotEmpty) {
          districtCounts[p.district] = (districtCounts[p.district] ?? 0) + 1;
        }
      }
      state = stateCounts.entries.isEmpty
          ? null
          : (stateCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))[0]
                .key;
      district = districtCounts.entries.isEmpty
          ? null
          : (districtCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))[0]
                .key;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialStateName: state,
          initialDistrictName: district,
          initialCastes: castes,
          autoSearch: true,
        ),
      ),
    );
  }

  Widget _buildProfileCompletionPrompt() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingM),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: AppColors.warning,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  'Complete Your Profile',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Add more details to your profile to get better matches and increase your visibility.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            ElevatedButton.icon(
              onPressed: () => _navigateToProfileEdit(),
              icon: const Icon(Icons.edit),
              label: const Text('Complete Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TryMeYourPartner'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: AppDimensions.iconXL * 2,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                'Welcome to TryMeYourPartner',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                'Find your perfect life partner from the Indian diaspora community',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              ElevatedButton.icon(
                onPressed: () => _showSignInDialog(),
                icon: const Icon(Icons.login),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingM,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: AppDimensions.paddingM),
            Text('Loading your matches...', style: AppTextStyles.subtitle1),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: AppDimensions.iconXL,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Something went wrong',
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                error,
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              ElevatedButton(
                onPressed: _loadHomeData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateToProfileDetail(MatrimonialUser profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(profile: profile),
      ),
    );
  }

  void _sendInterest(MatrimonialUser profile) {
    final matrimonialProvider = context.read<MatrimonialProvider>();
    matrimonialProvider
        .sendInterest(profile.id)
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Interest sent to ${profile.name}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send interest: $error'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        });
  }

  void _acceptInterest(MatrimonialUser profile) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final provider = context.read<MatrimonialProvider>();
    if (currentUserId == null) return;
    provider
        .acceptInterest(fromProfileId: profile.id, toAuthUserId: currentUserId)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Interest accepted from ${profile.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept interest: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        });
  }

  void _rejectInterest(MatrimonialUser profile) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final provider = context.read<MatrimonialProvider>();
    if (currentUserId == null) return;
    provider
        .rejectInterest(fromProfileId: profile.id, toAuthUserId: currentUserId)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Interest rejected from ${profile.name}'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject interest: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        });
  }

  void _toggleShortlist(MatrimonialUser profile) {
    final matrimonialProvider = context.read<MatrimonialProvider>();
    final wasShortlisted = matrimonialProvider.isProfileShortlisted(profile.id);
    matrimonialProvider.toggleShortlist(profile.id).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasShortlisted ? 'Removed from shortlist' : 'Added to shortlist',
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    });
  }

  void _navigateToSearch() {
    // Open Search screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _navigateToMatches({int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchesScreen()),
    );
  }

  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }

  void _showNotifications() {
    // Show notifications dialog or navigate to notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showSignInDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please restart the app to sign in.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }
}
