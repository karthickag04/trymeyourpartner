import 'package:flutter/material.dart';
import '../../app/router.dart';
import '../../shared/widgets/storage_image.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../auth/auth_provider.dart';
import '../profile/widgets/profile_card_horizontal.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';
import '../../shared/widgets/state_views.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load interests when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final matrimonialProvider = context.read<MatrimonialProvider>();

      if (authProvider.user != null) {
        matrimonialProvider.loadReceivedInterests(authProvider.user!.id);
        matrimonialProvider.loadSentInterests(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.interestsTitle),
        backgroundColor: context.colors.primaryContainer,
        elevation: 0,
        foregroundColor: context.colors.onPrimaryContainer,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.interestsTabReceived),
            Tab(text: context.l10n.interestsTabSent),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReceivedInterests(), _buildSentInterests()],
      ),
    );
  }

  Widget _buildReceivedInterests() {
    return Consumer<MatrimonialProvider>(
      builder: (context, matrimonialProvider, child) {
        if (matrimonialProvider.isLoading) {
          return LoadingView(message: context.l10n.interestsLoadingReceived);
        }

        final receivedInterests = matrimonialProvider.receivedInterests;

        if (receivedInterests.isEmpty) {
          return EmptyStateView(
            icon: Icons.favorite_border,
            title: context.l10n.interestsReceivedEmptyTitle,
            subtitle: context.l10n.interestsReceivedEmptySubtitle,
          );
        }

        return Container(
          color: context.palette.secondary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receivedInterests.length,
            itemBuilder: (context, index) {
              final profile = receivedInterests[index];
              return ProfileCardHorizontal(
                profile: profile,
                onTap: () => _showProfileDetails(profile),
                onAccept: () => _acceptInterest(profile),
                onReject: () => _declineInterest(profile),
                isShortlisted: false,
                isInterestSent: context
                    .read<MatrimonialProvider>()
                    .isInterestSent(profile.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSentInterests() {
    return Consumer<MatrimonialProvider>(
      builder: (context, matrimonialProvider, child) {
        if (matrimonialProvider.isLoading) {
          return LoadingView(message: context.l10n.interestsLoadingSent);
        }

        final sentInterests = matrimonialProvider.sentInterests;

        if (sentInterests.isEmpty) {
          return EmptyStateView(
            icon: Icons.send_outlined,
            title: context.l10n.interestsSentEmptyTitle,
            subtitle: context.l10n.interestsSentEmptySubtitle,
          );
        }

        return Container(
          color: context.palette.secondary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sentInterests.length,
            itemBuilder: (context, index) {
              final profile = sentInterests[index];
              return ProfileCardHorizontal(
                profile: profile,
                onTap: () => openProfile(context, profile),
                isShortlisted: false,
                isInterestSent: context
                    .read<MatrimonialProvider>()
                    .isInterestSent(profile.id),
              );
            },
          ),
        );
      },
    );
  }

  void _showProfileDetails(dynamic profile) {
    // Show profile details modal - similar to search screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.palette.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: context.palette.surfaceMuted,
                      child: ClipOval(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child:
                              (profile.profileImageUrl != null &&
                                  profile.profileImageUrl!.isNotEmpty)
                              ? StorageImage(
                                  src: profile.profileImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: Center(
                                    child: Text(
                                      profile.name.isNotEmpty
                                          ? profile.name[0].toUpperCase()
                                          : '?',
                                      style: context.styles.heading2,
                                    ),
                                  ),
                                  emptyWidget: Center(
                                    child: Text(
                                      profile.name.isNotEmpty
                                          ? profile.name[0].toUpperCase()
                                          : '?',
                                      style: context.styles.heading2,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    profile.name.isNotEmpty
                                        ? profile.name[0].toUpperCase()
                                        : '?',
                                    style: context.styles.heading2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: context.styles.heading2),
                          Text(
                            context.l10n.profileAgeCity(
                              profile.age as int,
                              profile.city as String,
                            ),
                            style: context.styles.body1.copyWith(
                              color: context.palette.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  (profile.aboutMe as String?) ?? context.l10n.profileNoAbout,
                  style: context.styles.body1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _acceptInterest(dynamic profile) {
    final auth = context.read<AuthProvider>();
    final mat = context.read<MatrimonialProvider>();
    final uid = auth.user?.id;
    if (uid == null) return;
    mat
        .acceptInterest(fromProfileId: profile.id, toAuthUserId: uid)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.interestAccepted(profile.name as String),
              ),
              backgroundColor: context.palette.success,
            ),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.interestAcceptFailed),
              backgroundColor: context.palette.error,
            ),
          );
        });
  }

  void _declineInterest(dynamic profile) {
    final auth = context.read<AuthProvider>();
    final mat = context.read<MatrimonialProvider>();
    final uid = auth.user?.id;
    if (uid == null) return;
    mat
        .rejectInterest(fromProfileId: profile.id, toAuthUserId: uid)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.interestDeclined(profile.name as String),
              ),
              backgroundColor: context.palette.warning,
            ),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.interestDeclineFailed),
              backgroundColor: context.palette.error,
            ),
          );
        });
  }
}
