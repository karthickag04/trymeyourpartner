import 'package:flutter/material.dart';
import '../../app/router.dart';
import 'package:provider/provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/theme/constants.dart';
import '../../shared/services/matrimonial_service.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../subscriptions/subscription_service.dart';
import '../../app/di/service_locator.dart';
import '../../shared/models/contact_request.dart';
import '../auth/auth_provider.dart';
import '../chat/widgets/presence_indicator.dart';
import '../../shared/widgets/storage_image.dart';

class ProfileDetailScreen extends StatelessWidget {
  final MatrimonialUser profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Track view on open (fire & forget)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MatrimonialProvider>();
      // ignore: unawaited_futures
      provider.viewProfile(profile.id, profile: profile);
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showMoreOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(),

            // Basic Info
            _buildSection('Basic Information', _buildBasicInfo()),

            // About
            if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty)
              _buildSection(
                'About Me',
                Text(profile.aboutMe!, style: AppTextStyles.body2),
              ),

            // Family Info
            _buildSection('Family Information', _buildFamilyInfo()),

            // Partner Preferences
            _buildSection('Partner Preferences', _buildPartnerPreferences()),

            // Similar Profiles
            _buildSection(
              'Similar Profiles',
              _SimilarProfilesList(base: profile),
            ),

            // Contact Actions
            _buildContactActions(context),
            _buildRevealAndMessage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final List<String> images = (profile.photoUrls.isNotEmpty)
        ? profile.photoUrls
        : ((profile.profileImageUrl != null &&
                  profile.profileImageUrl!.isNotEmpty)
              ? [profile.profileImageUrl!]
              : <String>[]);

    int current = 0; // capture across StatefulBuilder rebuilds
    PageController?
    controller; // lazily initialized and kept within the StatefulBuilder closure
    return Container(
      width: double.infinity,
      height: 300,
      color: AppColors.surface,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              if (images.isEmpty)
                _buildDefaultAvatar()
              else
                Positioned.fill(
                  child: PageView.builder(
                    controller: controller ??= PageController(
                      initialPage: current,
                    ),
                    itemCount: images.length,
                    onPageChanged: (i) {
                      current = i;
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final src = images[index];
                      return StorageImage(
                        src: src,
                        fit: BoxFit.cover,
                        errorWidget: _buildDefaultAvatar(),
                        emptyWidget: _buildDefaultAvatar(),
                      );
                    },
                  ),
                ),

              // Left/Right arrow controls (centered vertically)
              if (images.length > 1) ...[
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (controller == null) return;
                          final prev = (current - 1).clamp(
                            0,
                            images.length - 1,
                          );
                          if (prev != current) {
                            controller!.animateToPage(
                              prev,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (controller == null) return;
                          final next = (current + 1).clamp(
                            0,
                            images.length - 1,
                          );
                          if (next != current) {
                            controller!.animateToPage(
                              next,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],

              // Page indicator (dots)
              if (images.length > 1)
                Positioned(
                  bottom: 8,
                  right: 0,
                  left: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) {
                      final active = i == current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 10 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),

              // Bottom-right image counter (e.g., 2/3)
              if (images.isNotEmpty)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(current + 1).clamp(1, images.length)}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Gradient Overlay
              IgnorePointer(
                ignoring: true,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Profile Info Overlay (non-interactive to keep swipes working)
              Positioned(
                bottom: AppDimensions.paddingL,
                left: AppDimensions.paddingL,
                right: AppDimensions.paddingL,
                child: IgnorePointer(
                  ignoring: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.name,
                              style: AppTextStyles.heading2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (profile.isVerified)
                            const Icon(
                              Icons.verified,
                              color: AppColors.success,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.age} years old',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PresenceIndicator(
                        profileId: profile.id,
                        textColor: Colors.white70,
                        pollEvery: const Duration(seconds: 60),
                      ),
                      Text(
                        '${profile.district}, ${profile.state}',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // withOpacity deprecated; use withValues to adjust alpha
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: AppDimensions.paddingM),
          content,
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        _buildInfoRow('Religion', profile.religion),
        _buildInfoRow('Caste', profile.caste),
        if (profile.subCaste.isNotEmpty)
          _buildInfoRow('Sub Caste', profile.subCaste),
        _buildInfoRow('Education', profile.education),
        _buildInfoRow('Occupation', profile.occupation),
        _buildInfoRow('Working Location', profile.workingLocation),
        if (profile.annualIncome != null)
          _buildInfoRow(
            'Annual Income',
            '₹${profile.annualIncome!.toStringAsFixed(0)} LPA',
          ),
        _buildInfoRow('Height', profile.heightInFeetInches),
        if (profile.weight != null)
          _buildInfoRow('Weight', '${profile.weight!.toStringAsFixed(0)} kg'),
        _buildInfoRow('Marital Status', profile.maritalStatus),
        if (profile.languages.isNotEmpty)
          _buildInfoRow('Languages', profile.languages.join(', ')),
        if (profile.hobbies.isNotEmpty)
          _buildInfoRow('Hobbies', profile.hobbies.join(', ')),
      ],
    );
  }

  Widget _buildFamilyInfo() {
    return Column(
      children: [
        if (profile.familyInfo.fatherName != null)
          _buildInfoRow('Father Name', profile.familyInfo.fatherName!),
        if (profile.familyInfo.fatherOccupation != null)
          _buildInfoRow(
            'Father Occupation',
            profile.familyInfo.fatherOccupation!,
          ),
        if (profile.familyInfo.motherName != null)
          _buildInfoRow('Mother Name', profile.familyInfo.motherName!),
        if (profile.familyInfo.motherOccupation != null)
          _buildInfoRow(
            'Mother Occupation',
            profile.familyInfo.motherOccupation!,
          ),
        if (profile.familyInfo.numberOfBrothers != null)
          _buildInfoRow(
            'Brothers',
            profile.familyInfo.numberOfBrothers.toString(),
          ),
        if (profile.familyInfo.numberOfSisters != null)
          _buildInfoRow(
            'Sisters',
            profile.familyInfo.numberOfSisters.toString(),
          ),
        if (profile.familyInfo.familyType != null)
          _buildInfoRow('Family Type', profile.familyInfo.familyType!),
        if (profile.familyInfo.familyValues != null)
          _buildInfoRow('Family Values', profile.familyInfo.familyValues!),
        if (profile.familyInfo.familyStatus != null)
          _buildInfoRow('Family Status', profile.familyInfo.familyStatus!),
        if (profile.familyInfo.familyDetails != null &&
            profile.familyInfo.familyDetails!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingS),
            child: Text(
              profile.familyInfo.familyDetails!,
              style: AppTextStyles.body2,
            ),
          ),
      ],
    );
  }

  Widget _buildPartnerPreferences() {
    return Column(
      children: [
        if (profile.partnerPreference.minAge != null ||
            profile.partnerPreference.maxAge != null)
          _buildInfoRow(
            'Preferred Age',
            '${profile.partnerPreference.minAge ?? 18} - ${profile.partnerPreference.maxAge ?? 60} years',
          ),
        if (profile.partnerPreference.minHeight != null ||
            profile.partnerPreference.maxHeight != null)
          _buildInfoRow(
            'Preferred Height',
            '${profile.partnerPreference.minHeight ?? 140} - ${profile.partnerPreference.maxHeight ?? 200} cm',
          ),
        if (profile.partnerPreference.preferredStates.isNotEmpty)
          _buildInfoRow(
            'Preferred States',
            profile.partnerPreference.preferredStates.join(', '),
          ),
        if (profile.partnerPreference.preferredCastes.isNotEmpty)
          _buildInfoRow(
            'Preferred Castes',
            profile.partnerPreference.preferredCastes.join(', '),
          ),
        if (profile.partnerPreference.preferredEducation.isNotEmpty)
          _buildInfoRow(
            'Preferred Education',
            profile.partnerPreference.preferredEducation.join(', '),
          ),
        if (profile.partnerPreference.preferredOccupation.isNotEmpty)
          _buildInfoRow(
            'Preferred Occupation',
            profile.partnerPreference.preferredOccupation.join(', '),
          ),
        if (profile.partnerPreference.minIncome != null ||
            profile.partnerPreference.maxIncome != null)
          _buildInfoRow(
            'Preferred Income',
            '₹${profile.partnerPreference.minIncome ?? 0} - ₹${profile.partnerPreference.maxIncome ?? 'No limit'} LPA',
          ),
        if (profile.partnerPreference.otherPreferences != null &&
            profile.partnerPreference.otherPreferences!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Other Preferences:', style: AppTextStyles.subtitle2),
                const SizedBox(height: 4),
                Text(
                  profile.partnerPreference.otherPreferences!,
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body2)),
        ],
      ),
    );
  }

  Widget _buildContactActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _sendInterest(context);
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Send Interest'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingM,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _addToShortlist(context),
              icon: const Icon(Icons.star),
              label: const Text('Shortlist'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingM,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealAndMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Capture navigation and messenger early to avoid using context after awaits
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final me = context
                    .read<MatrimonialProvider>()
                    .currentUserProfile;
                if (me == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please login'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                final blocked = await sl.safetyService.isBlocked(
                  me.id,
                  profile.id,
                );
                // Use captured nav & messenger instead of context after await
                if (blocked) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You cannot reveal contact for a blocked profile',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                // Contact exchange handshake gating
                final status = await sl.contactExchangeService.getStatus(
                  me.id,
                  profile.id,
                );
                // Ensure navigator is still mounted before using its context
                if (!nav.mounted) return;
                switch (status) {
                  case ContactHandshakeStatus.accepted:
                    _revealContact(nav.context);
                    break;
                  case ContactHandshakeStatus.sentPending:
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Contact request pending')),
                    );
                    break;
                  case ContactHandshakeStatus.receivedPending:
                    _promptAcceptContact(nav.context, myId: me.id);
                    break;
                  case ContactHandshakeStatus.declined:
                  case ContactHandshakeStatus.cancelled:
                  case ContactHandshakeStatus.none:
                    _sendContactRequest(nav.context, myId: me.id);
                    break;
                }
              },
              icon: const Icon(Icons.contact_phone),
              label: const Text('Reveal / Request Contact'),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final me = context
                    .read<MatrimonialProvider>()
                    .currentUserProfile;
                if (me == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please login to send a message'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                // Activity gating: self and other
                final meActive =
                    await sl.matrimonialService.isProfileActive(me.id) ?? true;
                final otherActive =
                    await sl.matrimonialService.isProfileActive(profile.id) ??
                    true;
                if (!meActive) {
                  if (!nav.mounted) return;
                  final reactivate = await showDialog<bool>(
                    context: nav.context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Profile inactive'),
                      content: const Text(
                        'Your profile is deactivated. Reactivate now to send messages?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Not now'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Reactivate'),
                        ),
                      ],
                    ),
                  );
                  if (reactivate == true) {
                    try {
                      final ok = await MatrimonialService.reactivateProfile(
                        me.id,
                      );
                      if (ok) {
                        final auth = context.read<AuthProvider>();
                        await context
                            .read<MatrimonialProvider>()
                            .forceRefreshUserData(auth.user?.id ?? '');
                        if (!nav.mounted) return;
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Profile reactivated'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _openMessage(nav.context);
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to reactivate: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                  return;
                }
                if (!otherActive) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This profile is not active. Messaging is temporarily disabled.',
                      ),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                final blocked = await sl.safetyService.isBlocked(
                  me.id,
                  profile.id,
                );
                if (blocked) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Messaging is disabled for blocked profiles',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (!nav.mounted) return;
                _openMessage(nav.context);
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Message'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendContactRequest(
    BuildContext context, {
    required String myId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sl.contactExchangeService.request(myId, profile.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contact request sent')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    }
  }

  Future<void> _promptAcceptContact(
    BuildContext context, {
    required String myId,
  }) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Accept contact request?'),
        content: Text('Accept contact exchange with ${profile.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sl.contactExchangeService.accept(myId, profile.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contact request accepted')),
      );
      // Immediately reveal now that handshake is accepted
      if (!nav.mounted) return;
      _revealContact(nav.context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    }
  }

  void _sendInterest(BuildContext context) {
    final provider = context.read<MatrimonialProvider>();
    final messenger = ScaffoldMessenger.of(context);
    provider
        .sendInterest(profile.id)
        .then((_) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Interest sent to ${profile.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        })
        .catchError((e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to send interest: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        });
  }

  void _addToShortlist(BuildContext context) {
    final provider = context.read<MatrimonialProvider>();
    final already = provider.isProfileShortlisted(profile.id);
    final messenger = ScaffoldMessenger.of(context);
    provider
        .toggleShortlist(profile.id)
        .then((_) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                already ? 'Removed from shortlist' : 'Added to shortlist',
              ),
              backgroundColor: AppColors.accent,
            ),
          );
        })
        .catchError((e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to update shortlist: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        });
  }

  Future<void> _revealContact(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final my = context.read<MatrimonialProvider>().currentUserProfile;
      if (my == null) throw Exception('Please login');
      final contact = await SubscriptionService.revealContact(profile.id);
      if (!nav.mounted) return;
      showModalBottomSheet(
        context: nav.context,
        isScrollControlled: true,
        builder: (_) => SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact details', style: AppTextStyles.subtitle1),
                const SizedBox(height: 8),
                if (contact.isEmpty)
                  const Text('This member has not added a phone number yet.'),
                if ((contact.phoneNumber ?? '').isNotEmpty)
                  Text('Phone: ${contact.phoneNumber}'),
                if ((contact.whatsappNumber ?? '').isNotEmpty)
                  Text('WhatsApp: ${contact.whatsappNumber}'),
              ],
            ),
          ),
        ),
      );
    } on ContactLimitReached {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Contact reveal limit reached. Upgrade your plan.'),
          backgroundColor: AppColors.warning,
        ),
      );
    } on FeatureUnavailable {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Contact reveal is not available right now.'),
        ),
      );
    } on ContactUnavailable {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('This profile is not available.'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not reveal contact. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openMessage(BuildContext context) {
    final my = context.read<MatrimonialProvider>().currentUserProfile;
    if (my == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to send a message'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final nav = Navigator.of(context);
    showModalBottomSheet(
      context: nav.context,
      isScrollControlled: true,
      builder: (ctx) {
        final nav = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Message ${profile.name}', style: AppTextStyles.subtitle1),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    try {
                      // Use DI-based message service
                      await sl.messageService.sendMessage(
                        my.id,
                        profile.id,
                        text,
                      );
                      nav.pop();
                      // Use captured messenger to avoid async gap warning
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Message sent'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to send message: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: const Text('Block Profile'),
              onTap: () {
                Navigator.pop(context);
                _blockProfile(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: AppColors.error),
              title: const Text('Report Profile'),
              onTap: () {
                Navigator.pop(context);
                _reportProfile(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _blockProfile(BuildContext context) {
    final me = context.read<MatrimonialProvider>().currentUserProfile;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block profile?'),
        content: Text(
          'You will no longer see ${profile.name}, and they won\'t be able to contact you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await sl.safetyService.blockProfile(me.id, profile.id);
                if (!context.mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Profile blocked'),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Optionally pop details after blocking
                final nav = Navigator.of(context);
                if (nav.canPop()) nav.pop();
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to block: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _reportProfile(BuildContext context) {
    final me = context.read<MatrimonialProvider>().currentUserProfile;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final reasonCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            TextField(
              controller: detailsCtrl,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await sl.safetyService.reportProfile(
                  me.id,
                  profile.id,
                  reason,
                  details: detailsCtrl.text.trim().isEmpty
                      ? null
                      : detailsCtrl.text.trim(),
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to report: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _SimilarProfilesList extends StatefulWidget {
  final MatrimonialUser base;
  const _SimilarProfilesList({required this.base});

  @override
  State<_SimilarProfilesList> createState() => _SimilarProfilesListState();
}

class _SimilarProfilesListState extends State<_SimilarProfilesList> {
  List<MatrimonialUser> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await MatrimonialService.getSimilarProfiles(
        widget.base,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Text(
        'No similar profiles found yet.',
        style: AppTextStyles.body2,
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final p = _items[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => openProfile(context, p),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        child:
                            (p.profileImageUrl != null &&
                                p.profileImageUrl!.isNotEmpty)
                            ? ClipOval(
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: StorageImage(
                                    src: p.profileImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.age} • ${p.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.caste,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
