import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/theme/constants.dart';
import '../profile/widgets/profile_card_horizontal.dart';
import '../profile/profile_detail_screen.dart';
import '../profile/profile_edit_screen.dart';
import 'search_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, this.initialTabIndex});

  final int? initialTabIndex;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _pageIndex = 0;
  bool _loadingOnce = false;
  bool _inFlight = false;
  bool _loadedInterests = false;
  bool _loadedShortlistedByMe = false;
  bool _loadedShortlistedYou = false;
  bool _loadedViewed = false;
  bool _loadedViewedYou = false;
  bool _loadedAccepted = false;
  // Top Picks is computed from matches; no network load needed

  @override
  void initState() {
    super.initState();
    // Pages: Matches, Top Picks, Interests, Shortlisted By You, Shortlisted You, Viewed, Viewed You, Accepted
    _pageIndex = (widget.initialTabIndex ?? 0).clamp(0, 7);
    _pageController = PageController(initialPage: _pageIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
    _loadTabData(_pageIndex);
  }

  Future<void> _loadMatches() async {
    final authProvider = context.read<AuthProvider>();
    final matrimonialProvider = context.read<MatrimonialProvider>();
    final userId = authProvider.user?.id;

    if (userId != null) {
      if (_inFlight) return;
      _inFlight = true;
      // Load matches list only to reduce churn
      await matrimonialProvider.loadMatches(userId);
      _loadingOnce = true;
      _inFlight = false;
    } else {
      debugPrint('❌ MatchesScreen: No user ID found');
    }
  }

  Future<void> _loadTabData(int index) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;
    final provider = context.read<MatrimonialProvider>();
    try {
      if (index == 1) {
        // Top Picks tab – computed locally from matches, nothing to load
        return;
      } else if (index == 2 && !_loadedInterests) {
        await provider.loadReceivedInterests(userId);
        setState(() => _loadedInterests = true);
      } else if (index == 3 && !_loadedShortlistedByMe) {
        await provider.loadShortlistedProfiles(userId);
        setState(() => _loadedShortlistedByMe = true);
      } else if (index == 4 && !_loadedShortlistedYou) {
        await provider.loadShortlistedProfiles(userId);
        setState(() => _loadedShortlistedYou = true);
      } else if (index == 5 && !_loadedViewed) {
        await provider.loadViewedProfiles(userId);
        setState(() => _loadedViewed = true);
      } else if (index == 6 && !_loadedViewedYou) {
        await provider.loadViewersOfMe(userId);
        setState(() => _loadedViewedYou = true);
      } else if (index == 7 && !_loadedAccepted) {
        await provider.loadAcceptedConnections(userId);
        setState(() => _loadedAccepted = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userId = authProvider.user?.id;

        if (userId == null) {
          return _buildSignInPrompt();
        }

        return Scaffold(
          appBar: AppBar(
            title: _buildPagerHeader(context),
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: Consumer<MatrimonialProvider>(
            builder: (context, matrimonialProvider, child) {
              return RefreshIndicator(
                onRefresh: () async {
                  final idx = _pageIndex;
                  if (idx == 0) return _loadMatches();
                  final authProvider = context.read<AuthProvider>();
                  final userId = authProvider.user?.id;
                  if (userId == null) return;
                  if (idx == 1) {
                    // Top Picks – nothing to refresh from network; re-rank matches
                    await matrimonialProvider.loadMatches(userId);
                  } else if (idx == 2) {
                    debugPrint('🔄 Refreshing Interests tab');
                    await matrimonialProvider.loadReceivedInterests(userId);
                    setState(() => _loadedInterests = true);
                  } else if (idx == 3) {
                    debugPrint('🔄 Refreshing Shortlisted By You tab');
                    await matrimonialProvider.loadShortlistedProfiles(userId);
                    setState(() => _loadedShortlistedByMe = true);
                  } else if (idx == 4) {
                    debugPrint('🔄 Refreshing Shortlisted You tab');
                    await matrimonialProvider.loadShortlistedProfiles(userId);
                    setState(() => _loadedShortlistedYou = true);
                  } else if (idx == 5) {
                    debugPrint('🔄 Refreshing Viewed tab');
                    await matrimonialProvider.loadViewedProfiles(userId);
                    setState(() => _loadedViewed = true);
                  } else if (idx == 6) {
                    debugPrint('🔄 Refreshing Viewed You tab');
                    await matrimonialProvider.loadViewersOfMe(userId);
                    setState(() => _loadedViewedYou = true);
                  } else if (idx == 7) {
                    debugPrint('🔄 Refreshing Accepted tab');
                    await matrimonialProvider.loadAcceptedConnections(userId);
                    setState(() => _loadedAccepted = true);
                  }
                },
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _pageIndex = i);
                    _loadTabData(i);
                  },
                  children: [
                    _buildMatchesTab(matrimonialProvider),
                    _buildTopPicksTab(matrimonialProvider),
                    _buildInterestsTab(matrimonialProvider),
                    _buildShortlistedByMeTab(matrimonialProvider),
                    _buildShortlistedYouTab(matrimonialProvider),
                    _buildViewedTab(matrimonialProvider),
                    _buildViewedYouTab(matrimonialProvider),
                    _buildAcceptedTab(matrimonialProvider),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildPagerHeader(BuildContext context) {
    const labels = [
      'Matches',
      'Top Picks',
      'Interests',
      'Shortlisted By You',
      'Shortlisted You',
      'Viewed',
      'Viewed You',
      'Accepted',
    ];
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (i) {
              setState(() => _pageIndex = i);
              _pageController.jumpToPage(i);
              _loadTabData(i);
            },
            itemBuilder: (context) => [
              for (int i = 0; i < labels.length; i++)
                PopupMenuItem<int>(value: i, child: Text(labels[i])),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_left_rounded, color: Colors.white),
            onPressed: () {
              final i = (_pageIndex - 1) % labels.length;
              final next = i < 0 ? i + labels.length : i;
              setState(() => _pageIndex = next);
              _pageController.jumpToPage(next);
              _loadTabData(next);
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                labels[_pageIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right_rounded, color: Colors.white),
            onPressed: () {
              final next = (_pageIndex + 1) % labels.length;
              setState(() => _pageIndex = next);
              _pageController.jumpToPage(next);
              _loadTabData(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
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
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                'Sign In Required',
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                'Sign in to find your perfect match and connect with compatible profiles',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              ElevatedButton.icon(
                onPressed: () => _showSignInDialog(context),
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
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

  Widget _buildMatchesTab(MatrimonialProvider provider) {
    if (!_loadingOnce && provider.matchedProfiles.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.error.isNotEmpty) {
      return _buildErrorState(provider.error);
    }

    if (provider.matchedProfiles.isEmpty) {
      return _buildEmptyState(
        'No Matches Yet',
        'Complete your profile to get better matches',
        Icons.people_outline,
        'Complete Profile',
        () => _navigateToProfileCompletion(),
      );
    }

    return _buildProfileList(provider.matchedProfiles);
  }

  Widget _buildInterestsTab(MatrimonialProvider provider) {
    if (!_loadedInterests && provider.receivedInterests.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.receivedInterests.isEmpty) {
      return _buildEmptyState(
        'No Interests Received',
        'Your profile will receive interests from compatible matches',
        Icons.favorite_border,
        'Improve Profile',
        () => _navigateToProfileCompletion(),
      );
    }
    return _buildInterestsList(provider.receivedInterests);
  }

  Widget _buildTopPicksTab(MatrimonialProvider provider) {
    // Top Picks reuses matches and ranks them client-side
    if (!_loadingOnce && provider.matchedProfiles.isEmpty) {
      return _buildLoadingState();
    }
    final topPicks = provider.getTopPicks(limit: 50);
    if (topPicks.isEmpty) {
      return _buildEmptyState(
        'No Top Picks yet',
        'We’ll show highly compatible profiles here once matches are available',
        Icons.recommend_outlined,
        'Refresh Matches',
        _loadMatches,
      );
    }
    return _buildProfileList(topPicks);
  }

  Widget _buildShortlistedByMeTab(MatrimonialProvider provider) {
    if (!_loadedShortlistedByMe && provider.shortlistedByMe.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.shortlistedByMe.isEmpty) {
      return _buildEmptyState(
        'No Shortlisted Profiles',
        'Start browsing profiles and shortlist the ones you like',
        Icons.star_border,
        'Browse Profiles',
        () async {
          final authProvider = context.read<AuthProvider>();
          final userId = authProvider.user?.id;
          if (userId != null) {
            await provider.loadShortlistedProfiles(userId);
            setState(() => _loadedShortlistedByMe = true);
          }
          _switchToSearchTab();
        },
      );
    }

    return _buildProfileList(provider.shortlistedByMe);
  }

  Widget _buildShortlistedYouTab(MatrimonialProvider provider) {
    if (!_loadedShortlistedYou && provider.shortlistedMe.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.shortlistedMe.isEmpty) {
      return _buildEmptyState(
        'No One Shortlisted You Yet',
        'As more people discover your profile, you\'ll see them here',
        Icons.star_outline,
        'Improve Profile',
        () => _navigateToProfileCompletion(),
      );
    }

    return _buildProfileList(provider.shortlistedMe);
  }

  Widget _buildViewedTab(MatrimonialProvider provider) {
    if (!_loadedViewed && provider.viewedProfiles.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.viewedProfiles.isEmpty) {
      return _buildEmptyState(
        'No Profile Views',
        'Start viewing profiles to see them here',
        Icons.visibility_off,
        'Browse Profiles',
        () async {
          final authProvider = context.read<AuthProvider>();
          final userId = authProvider.user?.id;
          if (userId != null) {
            await provider.loadViewedProfiles(userId);
            setState(() => _loadedViewed = true);
          }
          _switchToSearchTab();
        },
      );
    }

    return _buildProfileList(provider.viewedProfiles);
  }

  Widget _buildViewedYouTab(MatrimonialProvider provider) {
    if (!_loadedViewedYou && provider.viewersOfMe.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.viewersOfMe.isEmpty) {
      return _buildEmptyState(
        'No Profile Views Yet',
        'We\'ll show people who viewed your profile here',
        Icons.remove_red_eye_outlined,
        'Refresh',
        () async {
          final authProvider = context.read<AuthProvider>();
          final userId = authProvider.user?.id;
          if (userId != null) {
            await provider.loadViewersOfMe(userId);
            setState(() => _loadedViewedYou = true);
          }
        },
      );
    }

    return _buildProfileList(provider.viewersOfMe);
  }

  Widget _buildAcceptedTab(MatrimonialProvider provider) {
    if (!_loadedAccepted && provider.acceptedConnections.isEmpty) {
      return _buildLoadingState();
    }

    if (provider.acceptedConnections.isEmpty) {
      return _buildEmptyState(
        'No Accepted Connections',
        'Accepted interests will appear here',
        Icons.handshake_outlined,
        'Refresh',
        () async {
          final authProvider = context.read<AuthProvider>();
          final userId = authProvider.user?.id;
          if (userId != null) {
            await provider.loadAcceptedConnections(userId);
            setState(() => _loadedAccepted = true);
          }
        },
      );
    }

    return _buildProfileList(provider.acceptedConnections);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: AppDimensions.paddingM),
          Text('Loading matches...', style: AppTextStyles.subtitle1),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
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
              onPressed: _loadMatches,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String description,
    IconData icon,
    String actionText,
    VoidCallback onAction,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXL * 1.5,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              title,
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              description,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            ElevatedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileList(List<MatrimonialUser> profiles) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final matrimonialProvider = context.read<MatrimonialProvider>();
          return ProfileCardHorizontal(
            profile: profile,
            onTap: () {
              matrimonialProvider.viewProfile(profile.id, profile: profile);
              _navigateToProfileDetail(profile);
            },
            onInterest: () => _sendInterest(profile),
            onShortlist: () => _toggleShortlist(profile),
            isShortlisted: matrimonialProvider.isProfileShortlisted(profile.id),
            isInterestSent: matrimonialProvider.isInterestSent(profile.id),
          );
        },
      ),
    );
  }

  Widget _buildInterestsList(List<MatrimonialUser> profiles) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final matrimonialProvider = context.read<MatrimonialProvider>();
          return ProfileCardHorizontal(
            profile: profile,
            onTap: () => _navigateToProfileDetail(profile),
            onAccept: () => _acceptInterest(profile),
            onReject: () => _rejectInterest(profile),
            onShortlist: () => _toggleShortlist(profile),
            isShortlisted: matrimonialProvider.isProfileShortlisted(profile.id),
            isInterestSent: matrimonialProvider.isInterestSent(profile.id),
          );
        },
      ),
    );
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

  void _acceptInterest(MatrimonialUser profile) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final provider = context.read<MatrimonialProvider>();
    if (currentUserId == null) return;
    provider
        .acceptInterest(fromProfileId: profile.id, toAuthUserId: currentUserId)
        .then((_) {
          if (!mounted) return;
          // Optimistically remove from current list
          setState(() {});
          // Ensure list is refreshed
          provider.loadReceivedInterests(currentUserId);
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
          // Optimistically update UI
          setState(() {});
          provider.loadReceivedInterests(currentUserId);
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

  void _showSignInDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please restart the app to sign in.'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _navigateToProfileCompletion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }

  void _switchToSearchTab() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }
}
