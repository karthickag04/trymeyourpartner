import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/matrimonial_user.dart';
import '../../../shared/theme/constants.dart';
import '../../chat/widgets/presence_indicator.dart';
import '../../../shared/widgets/storage_image.dart';

class ProfileCard extends StatelessWidget {
  final MatrimonialUser profile;
  final VoidCallback onTap;
  final VoidCallback? onInterest;
  final VoidCallback? onShortlist;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isShortlisted; // New parameter to show shortlist overlay
  final bool isInterestSent; // Disable interest button if already sent

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.onInterest,
    this.onShortlist,
    this.onAccept,
    this.onReject,
    this.isShortlisted = false, // Default to false
    this.isInterestSent = false,
  });

  @override
  Widget build(BuildContext context) {
    // Debug logging removed for cleaner console

    return Card(
      color: context.palette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image with Shortlist Overlay
            Expanded(
              flex: 4, // Good balance for image space
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusL),
                        topRight: Radius.circular(AppDimensions.radiusL),
                      ),
                      color: context.palette.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusL),
                        topRight: Radius.circular(AppDimensions.radiusL),
                      ),
                      child:
                          (profile.profileImageUrl != null &&
                              profile.profileImageUrl!.isNotEmpty)
                          ? StorageImage(
                              src: profile.profileImageUrl,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                color: context.palette.surface,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.palette.accent,
                                  ),
                                ),
                              ),
                              errorWidget: _buildDefaultAvatar(context),
                              emptyWidget: _buildDefaultAvatar(context),
                            )
                          : _buildDefaultAvatar(context),
                    ),
                  ),
                  // Presence dot overlay bottom-right
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.palette.cardBackground,
                        shape: BoxShape.circle,
                      ),
                      child: PresenceIndicator(
                        profileId: profile.id,
                        showText: false,
                      ),
                    ),
                  ),

                  // Shortlist Star Overlay - Top Center of Image
                  if (isShortlisted)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.palette.warning,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.palette.cardBackground,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.palette.shadow,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.star,
                            color: context.palette.onPrimary,
                            size: 18,
                            semanticLabel: context.l10n.badgeShortlisted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Profile Info - Using flexible sizing to prevent overflow
            Expanded(
              flex: 4, // More space for content
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: 4, // Reduced padding to save space
                ),
                child: SingleChildScrollView(
                  // Make content scrollable if needed
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and Age
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.displayName,
                              style: context.styles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced for better fit
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.isVerified)
                            Icon(
                              Icons.verified,
                              color: context.palette.success,
                              size: 12, // Smaller icon
                              semanticLabel: context.l10n.badgeVerified,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Presence text under name
                      PresenceIndicator(
                        profileId: profile.id,
                        showText: true,
                        textColor: context.palette.textTertiary,
                        pollEvery: const Duration(seconds: 60),
                      ),

                      const SizedBox(height: 2), // Reduced spacing
                      // Age and Height
                      Text(
                        context.l10n.profileAgeHeight(
                          profile.age,
                          profile.heightInFeetInches,
                        ),
                        style: context.styles.micro,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Education
                      Text(
                        profile.education,
                        style: context.styles.micro,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Occupation
                      Text(
                        profile.occupation,
                        style: context.styles.micro,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // Location, Match Why, and Send Interest Button Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Location with compact design
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.accent.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: context.palette.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: context.palette.accent,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      context.l10n.placeDistrictState(
                                        profile.district,
                                        profile.state,
                                      ),
                                      style: context.styles.micro.copyWith(
                                        color: context.palette.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Why Match button (opens a small reasons sheet)
                          IconButton(
                            tooltip: context.l10n.whyMatchedTooltip,
                            icon: const Icon(Icons.info_outline, size: 16),
                            onPressed: () => _showWhyMatch(context),
                          ),

                          // Send Interest Button
                          if (onInterest != null)
                            SizedBox(
                              height: AppDimensions.minTapTarget,
                              child: ElevatedButton.icon(
                                onPressed: isInterestSent ? null : onInterest,
                                icon: Icon(
                                  Icons.favorite,
                                  color: context.palette.onPrimary,
                                  size: 12,
                                ),
                                label: Text(
                                  isInterestSent
                                      ? context.l10n.actionInterestSent
                                      : context.l10n.actionInterest,
                                  style: context.styles.overline.copyWith(
                                    color: context.palette.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.palette.accent,
                                  foregroundColor: context.palette.onPrimary,
                                  elevation: 1,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  minimumSize: const Size(
                                    AppDimensions.minTapTarget,
                                    AppDimensions.minTapTarget,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons (excluding Send Interest which is now inline)
            if (onAccept != null || onReject != null || onShortlist != null)
              Container(
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.minTapTarget,
                  maxHeight: 52,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    if (onAccept != null)
                      Expanded(
                        child: IconButton(
                          onPressed: onAccept,
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: context.palette.success,
                            size: 18,
                          ),
                          tooltip: context.l10n.actionAccept,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    if (onReject != null)
                      Expanded(
                        child: IconButton(
                          onPressed: onReject,
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: context.palette.error,
                            size: 18,
                          ),
                          tooltip: context.l10n.actionReject,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    // Shortlist button - more compact
                    if (onShortlist != null)
                      Expanded(
                        child: IconButton(
                          onPressed: onShortlist,
                          icon: Icon(
                            isShortlisted ? Icons.star : Icons.star_border,
                            color: context.palette.warning,
                            size: 18,
                          ),
                          tooltip: isShortlisted
                              ? context.l10n.actionRemoveFromShortlist
                              : context.l10n.actionAddToShortlist,
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: context.palette.accent.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: context.styles.heading1.copyWith(
            fontWeight: FontWeight.bold,
            color: context.palette.accent,
          ),
        ),
      ),
    );
  }

  void _showWhyMatch(BuildContext context) {
    final reasons = _computeWhyMatch(context, profile);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => Row(
            children: [
              Icon(Icons.check, size: 16, color: context.palette.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(reasons[i])),
            ],
          ),
          separatorBuilder: (_, __) => const Divider(height: 12),
          itemCount: reasons.length,
        ),
      ),
    );
  }

  List<String> _computeWhyMatch(BuildContext context, MatrimonialUser other) {
    final List<String> reasons = [];
    // NOTE: This is a lightweight, client-only heuristic. Replace with backend view later.
    final l = context.l10n;
    if (other.district.isNotEmpty) {
      reasons.add(l.whyMatchNearby(other.district));
    }
    if (other.education.isNotEmpty) {
      reasons.add(l.whyMatchEducation(other.education));
    }
    if (other.caste.isNotEmpty) {
      reasons.add(l.whyMatchCaste(other.caste));
    }
    if (other.languages.isNotEmpty) {
      reasons.add(l.whyMatchLanguages(other.languages.join(', ')));
    }
    if (reasons.isEmpty) {
      reasons.add(l.whyMatchGeneral);
    }
    return reasons.take(4).toList();
  }
}
