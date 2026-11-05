import 'package:flutter/material.dart';
import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
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
        backgroundColor: context.palette.primary,
        foregroundColor: context.palette.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: context.l10n.moreOptions,
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
            _buildProfileHeader(context),

            // Basic Info
            _buildSection(
              context,
              context.l10n.sectionBasicInfo,
              _buildBasicInfo(context),
            ),

            // About
            if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty)
              _buildSection(
                context,
                context.l10n.sectionAboutMe,
                Text(profile.aboutMe!, style: context.styles.body2),
              ),

            // Family Info
            _buildSection(
              context,
              context.l10n.sectionFamilyInfo,
              _buildFamilyInfo(context),
            ),

            // Partner Preferences
            _buildSection(
              context,
              context.l10n.sectionPartnerPreferences,
              _buildPartnerPreferences(context),
            ),

            // Similar Profiles
            _buildSection(
              context,
              context.l10n.sectionSimilarProfiles,
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

  Widget _buildProfileHeader(BuildContext context) {
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
      color: context.palette.surface,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Stack(
            children: [
              if (images.isEmpty)
                _buildDefaultAvatar(context)
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
                        errorWidget: _buildDefaultAvatar(context),
                        emptyWidget: _buildDefaultAvatar(context),
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
                        color: context.palette.imageScrim.withValues(
                          alpha: 0.35,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: context.l10n.previousPhoto,
                        icon: Icon(
                          Icons.chevron_left,
                          color: context.palette.onImage,
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
                        color: context.palette.imageScrim.withValues(
                          alpha: 0.35,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: context.l10n.nextPhoto,
                        icon: Icon(
                          Icons.chevron_right,
                          color: context.palette.onImage,
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
                              ? context.palette.onImage
                              : context.palette.onImage.withValues(alpha: 0.5),
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
                      color: context.palette.imageScrim.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.photoCounter(
                        (current + 1).clamp(1, images.length),
                        images.length,
                      ),
                      style: context.styles.caption.copyWith(
                        color: context.palette.onImage,
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
                        context.palette.imageScrim.withValues(alpha: 0.7),
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
                              style: context.styles.heading2.copyWith(
                                color: context.palette.onImage,
                              ),
                            ),
                          ),
                          if (profile.isVerified)
                            Icon(
                              Icons.verified,
                              color: context.palette.success,
                              size: 24,
                              semanticLabel: context.l10n.badgeVerified,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.ageYearsOld(profile.age),
                        style: context.styles.subtitle1.copyWith(
                          color: context.palette.onImage.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      PresenceIndicator(
                        profileId: profile.id,
                        textColor: context.palette.onImage.withValues(
                          alpha: 0.85,
                        ),
                        pollEvery: const Duration(seconds: 60),
                      ),
                      Text(
                        context.l10n.placeDistrictState(
                          profile.district,
                          profile.state,
                        ),
                        style: context.styles.body2.copyWith(
                          color: context.palette.onImage.withValues(
                            alpha: 0.85,
                          ),
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

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // withOpacity deprecated; use withValues to adjust alpha
      color: context.palette.accent.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: context.palette.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: context.palette.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.heading3),
          const SizedBox(height: AppDimensions.paddingM),
          content,
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Column(
      children: [
        _buildInfoRow(context, context.l10n.fieldReligion, profile.religion),
        _buildInfoRow(context, context.l10n.fieldCaste, profile.caste),
        if (profile.subCaste.isNotEmpty)
          _buildInfoRow(context, context.l10n.fieldSubCaste, profile.subCaste),
        _buildInfoRow(context, context.l10n.fieldEducation, profile.education),
        _buildInfoRow(
          context,
          context.l10n.fieldOccupation,
          profile.occupation,
        ),
        _buildInfoRow(
          context,
          context.l10n.fieldWorkingLocation,
          profile.workingLocation,
        ),
        if (profile.annualIncome != null)
          _buildInfoRow(
            context,
            context.l10n.fieldAnnualIncome,
            context.l10n.incomeLpa(
              context.formatNumber(profile.annualIncome!.round()),
            ),
          ),
        _buildInfoRow(
          context,
          context.l10n.fieldHeight,
          profile.heightInFeetInches,
        ),
        if (profile.weight != null)
          _buildInfoRow(
            context,
            context.l10n.fieldWeight,
            context.l10n.weightKg(
              context.formatNumber(profile.weight!.round()),
            ),
          ),
        _buildInfoRow(
          context,
          context.l10n.fieldMaritalStatus,
          profile.maritalStatus,
        ),
        if (profile.languages.isNotEmpty)
          _buildInfoRow(
            context,
            context.l10n.fieldLanguages,
            profile.languages.join(', '),
          ),
        if (profile.hobbies.isNotEmpty)
          _buildInfoRow(
            context,
            context.l10n.fieldHobbies,
            profile.hobbies.join(', '),
          ),
      ],
    );
  }

  Widget _buildFamilyInfo(BuildContext context) {
    return Column(
      children: [
        if (profile.familyInfo.fatherName != null)
          _buildInfoRow(
            context,
            context.l10n.fieldFatherName,
            profile.familyInfo.fatherName!,
          ),
        if (profile.familyInfo.fatherOccupation != null)
          _buildInfoRow(
            context,
            context.l10n.fieldFatherOccupation,
            profile.familyInfo.fatherOccupation!,
          ),
        if (profile.familyInfo.motherName != null)
          _buildInfoRow(
            context,
            context.l10n.fieldMotherName,
            profile.familyInfo.motherName!,
          ),
        if (profile.familyInfo.motherOccupation != null)
          _buildInfoRow(
            context,
            context.l10n.fieldMotherOccupation,
            profile.familyInfo.motherOccupation!,
          ),
        if (profile.familyInfo.numberOfBrothers != null)
          _buildInfoRow(
            context,
            context.l10n.fieldBrothers,
            profile.familyInfo.numberOfBrothers.toString(),
          ),
        if (profile.familyInfo.numberOfSisters != null)
          _buildInfoRow(
            context,
            context.l10n.fieldSisters,
            profile.familyInfo.numberOfSisters.toString(),
          ),
        if (profile.familyInfo.familyType != null)
          _buildInfoRow(
            context,
            context.l10n.fieldFamilyType,
            profile.familyInfo.familyType!,
          ),
        if (profile.familyInfo.familyValues != null)
          _buildInfoRow(
            context,
            context.l10n.fieldFamilyValues,
            profile.familyInfo.familyValues!,
          ),
        if (profile.familyInfo.familyStatus != null)
          _buildInfoRow(
            context,
            context.l10n.fieldFamilyStatus,
            profile.familyInfo.familyStatus!,
          ),
        if (profile.familyInfo.familyDetails != null &&
            profile.familyInfo.familyDetails!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingS),
            child: Text(
              profile.familyInfo.familyDetails!,
              style: context.styles.body2,
            ),
          ),
      ],
    );
  }

  Widget _buildPartnerPreferences(BuildContext context) {
    return Column(
      children: [
        if (profile.partnerPreference.minAge != null ||
            profile.partnerPreference.maxAge != null)
          _buildInfoRow(
            context,
            context.l10n.fieldPreferredAge,
            context.l10n.ageRange(
              profile.partnerPreference.minAge ?? 18,
              profile.partnerPreference.maxAge ?? 60,
            ),
          ),
        if (profile.partnerPreference.minHeight != null ||
            profile.partnerPreference.maxHeight != null)
          _buildInfoRow(
            context,
            context.l10n.fieldPreferredHeight,
            context.l10n.heightRangeCm(
              context.formatNumber(profile.partnerPreference.minHeight ?? 140),
              context.formatNumber(profile.partnerPreference.maxHeight ?? 200),
            ),
          ),
        if (profile.partnerPreference.preferredStates.isNotEmpty)
          _buildInfoRow(
            context,
            context.l10n.fieldPreferredStates,
            profile.partnerPreference.preferredStates.join(', '),
          ),
        if (profile.partnerPreference.preferredCastes.isNotEmpty)
          _buildInfoRow(
            context,
            context.l10n.fieldPreferredCastes,
            profile.partnerPreference.preferredCastes.join(', '),
          ),
        if (profile.partnerPreference.preferredEducation.isNotEmpty)
          _buildInfoRow(
            context,
            context.l10n.fieldPreferredEducation,
            profile.partnerPreference.preferredEducation.join(', '),
          ),
        if (profile.partnerPreference.preferredOccupation.isNotEmpty)
          _buildInfoRow(
            context,
            context.l10n.fieldPreferredOccupation,
            profile.partnerPreference.preferredOccupation.join(', '),
          ),
        if (profile.partnerPreference.minIncome != null ||
            profile.partnerPreference.maxIncome != null)
          _buildInfoRow(
            context,
            context.l10n.fieldPreferredIncome,
            context.l10n.incomeRangeLpa(
              context.formatNumber(profile.partnerPreference.minIncome ?? 0),
              profile.partnerPreference.maxIncome == null
                  ? context.l10n.noLimit
                  : context.formatNumber(profile.partnerPreference.maxIncome!),
            ),
          ),
        if (profile.partnerPreference.otherPreferences != null &&
            profile.partnerPreference.otherPreferences!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.paddingS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.fieldOtherPreferences,
                  style: context.styles.subtitle2,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.partnerPreference.otherPreferences!,
                  style: context.styles.body2,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: context.styles.body2.copyWith(
                fontWeight: FontWeight.w500,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: context.styles.body2)),
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
              label: Text(context.l10n.actionSendInterest),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.accent,
                foregroundColor: context.palette.onPrimary,
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
              label: Text(context.l10n.actionShortlist),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.warning,
                side: BorderSide(color: context.palette.warning),
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
                    SnackBar(
                      content: Text(context.l10n.pleaseSignIn),
                      backgroundColor: context.palette.error,
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
                    SnackBar(
                      content: Text(context.l10n.blockedNoReveal),
                      backgroundColor: context.palette.error,
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
                      SnackBar(
                        content: Text(context.l10n.contactRequestPending),
                      ),
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
              label: Text(context.l10n.actionRevealContact),
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
                    SnackBar(
                      content: Text(context.l10n.signInToMessage),
                      backgroundColor: context.palette.error,
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
                      title: Text(context.l10n.profileInactiveTitle),
                      content: Text(
                        context.l10n.profileInactiveReactivatePrompt,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: Text(context.l10n.actionNotNow),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: Text(context.l10n.actionReactivate),
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
                          SnackBar(
                            content: Text(context.l10n.profileReactivated),
                            backgroundColor: context.palette.success,
                          ),
                        );
                        _openMessage(nav.context);
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.profileReactivateFailed),
                          backgroundColor: context.palette.error,
                        ),
                      );
                    }
                  }
                  return;
                }
                if (!otherActive) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.messagingDisabledInactive),
                      backgroundColor: context.palette.warning,
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
                    SnackBar(
                      content: Text(context.l10n.messagingDisabledBlocked),
                      backgroundColor: context.palette.error,
                    ),
                  );
                  return;
                }
                if (!nav.mounted) return;
                _openMessage(nav.context);
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(context.l10n.actionMessage),
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
        SnackBar(content: Text(context.l10n.contactRequestSent)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.contactRequestFailed)),
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
        title: Text(context.l10n.acceptContactTitle),
        content: Text(context.l10n.acceptContactBody(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(context.l10n.commonNo),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(context.l10n.actionAccept),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sl.contactExchangeService.accept(myId, profile.id);
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.contactRequestAccepted)),
      );
      // Immediately reveal now that handshake is accepted
      if (!nav.mounted) return;
      _revealContact(nav.context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.contactAcceptFailed)),
      );
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
              content: Text(context.l10n.interestSentTo(profile.name)),
              backgroundColor: context.palette.success,
            ),
          );
        })
        .catchError((e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(context.l10n.interestSendFailed),
              backgroundColor: context.palette.error,
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
                already
                    ? context.l10n.shortlistRemoved
                    : context.l10n.shortlistAdded,
              ),
              backgroundColor: context.palette.accent,
            ),
          );
        })
        .catchError((e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(context.l10n.shortlistFailed),
              backgroundColor: context.palette.error,
            ),
          );
        });
  }

  Future<void> _revealContact(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final my = context.read<MatrimonialProvider>().currentUserProfile;
      if (my == null) throw Exception(context.l10n.pleaseSignIn);
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
                Text(
                  context.l10n.contactDetailsTitle,
                  style: context.styles.subtitle1,
                ),
                const SizedBox(height: 8),
                if (contact.isEmpty) Text(context.l10n.contactNoPhone),
                if ((contact.phoneNumber ?? '').isNotEmpty)
                  Text(context.l10n.contactPhone(contact.phoneNumber!)),
                if ((contact.whatsappNumber ?? '').isNotEmpty)
                  Text(context.l10n.contactWhatsapp(contact.whatsappNumber!)),
              ],
            ),
          ),
        ),
      );
    } on ContactLimitReached {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.contactLimitUpgrade),
          backgroundColor: context.palette.warning,
        ),
      );
    } on FeatureUnavailable {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.contactRevealUnavailable)),
      );
    } on ContactUnavailable {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileNotAvailable),
          backgroundColor: context.palette.error,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.contactRevealFailed),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  void _openMessage(BuildContext context) {
    final my = context.read<MatrimonialProvider>().currentUserProfile;
    if (my == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.signInToMessage),
          backgroundColor: context.palette.error,
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
              Text(
                context.l10n.messageTo(profile.name),
                style: context.styles.subtitle1,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: context.l10n.messageHintLong,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(context.l10n.chatSend),
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
                        SnackBar(
                          content: Text(context.l10n.messageSent),
                          backgroundColor: context.palette.success,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.messageSendFailed),
                          backgroundColor: context.palette.error,
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
              leading: Icon(Icons.block, color: context.palette.error),
              title: Text(context.l10n.blockProfileAction),
              onTap: () {
                Navigator.pop(context);
                _blockProfile(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.report, color: context.palette.error),
              title: Text(context.l10n.reportProfileAction),
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
        SnackBar(
          content: Text(context.l10n.pleaseSignIn),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.blockProfileTitle),
        content: Text(context.l10n.blockProfileBody(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await sl.safetyService.blockProfile(me.id, profile.id);
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.profileBlocked),
                    backgroundColor: context.palette.success,
                  ),
                );
                // Optionally pop details after blocking
                final nav = Navigator.of(context);
                if (nav.canPop()) nav.pop();
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.blockFailed),
                    backgroundColor: context.palette.error,
                  ),
                );
              }
            },
            child: Text(context.l10n.actionBlock),
          ),
        ],
      ),
    );
  }

  void _reportProfile(BuildContext context) {
    final me = context.read<MatrimonialProvider>().currentUserProfile;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSignIn),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }
    final reasonCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.reportProfileTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(labelText: context.l10n.reportReason),
            ),
            TextField(
              controller: detailsCtrl,
              decoration: InputDecoration(
                labelText: context.l10n.reportDetails,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
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
                  SnackBar(
                    content: Text(context.l10n.reportSubmitted),
                    backgroundColor: context.palette.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.reportFailed),
                    backgroundColor: context.palette.error,
                  ),
                );
              }
            },
            child: Text(context.l10n.actionSubmit),
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
      return Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: context.palette.primary),
        ),
      );
    }
    if (_items.isEmpty) {
      return Text(context.l10n.similarEmpty, style: context.styles.body2);
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
                        backgroundColor: context.palette.surfaceMuted,
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
                        style: context.styles.subtitle2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.ageCityShort(p.age, p.city),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.styles.caption,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: context.palette.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.caste,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.styles.caption,
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
