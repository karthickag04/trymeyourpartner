import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/matrimonial_user.dart';
import '../../../shared/theme/constants.dart';
import '../../chat/widgets/presence_indicator.dart';
import '../../../shared/widgets/storage_image.dart';

class ProfileCardHorizontal extends StatelessWidget {
  final MatrimonialUser profile;
  final VoidCallback onTap;
  final VoidCallback? onInterest;
  final VoidCallback? onShortlist;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isShortlisted;
  final bool isInterestSent;
  final String? statusLabel;
  final Color? statusColor;

  const ProfileCardHorizontal({
    super.key,
    required this.profile,
    required this.onTap,
    this.onInterest,
    this.onShortlist,
    this.onAccept,
    this.onReject,
    this.isShortlisted = false,
    this.isInterestSent = false,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            // Main content area with image and details
            IntrinsicHeight(
              // Ensures proper height calculation
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side - Profile Image
                  _buildProfileImage(context),

                  // Right side - Profile Details
                  Expanded(child: _buildProfileDetails(context)),
                ],
              ),
            ),

            // Bottom - Action Buttons
            if (_hasActionButtons()) _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return Container(
      width: 120, // Fixed width for profile image
      height: 140, // Fixed height instead of double.infinity
      margin: const EdgeInsets.all(AppDimensions.paddingS),
      child: Stack(
        children: [
          // Profile Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              color: context.palette.surface,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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

          // Shortlist Star Overlay
          if (isShortlisted)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
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
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star,
                  color: context.palette.onPrimary,
                  size: 16,
                  semanticLabel: context.l10n.badgeShortlisted,
                ),
              ),
            ),

          // Verification Badge
          if (profile.isVerified)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.palette.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.palette.cardBackground,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.verified,
                  color: context.palette.onPrimary,
                  size: 12,
                  semanticLabel: context.l10n.badgeVerified,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          // Name and Age
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.displayName,
                  style: context.styles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.palette.textPrimary,
                    fontSize: 16, // Slightly smaller
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),
          // Presence/last seen message under name
          Row(
            children: [
              PresenceIndicator(
                profileId: profile.id,
                showText: true,
                textColor: context.palette.textSecondary,
                pollEvery: const Duration(seconds: 60),
              ),
            ],
          ),

          const SizedBox(height: 4), // Reduced spacing
          // Age and Height
          Row(
            children: [
              Icon(Icons.cake, size: 14, color: context.palette.textSecondary),
              const SizedBox(width: 4),
              Text(
                context.l10n.ageYearsLong(profile.age),
                style: context.styles.caption.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Icon(
                Icons.height,
                size: 14,
                color: context.palette.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                (profile.heightInFeetInches ?? context.l10n.commonNotSpecified),
                style: context.styles.caption.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6), // Reduced spacing
          // Education
          Row(
            children: [
              Icon(Icons.school, size: 14, color: context.palette.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile.education,
                  style: context.styles.caption.copyWith(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4), // Reduced spacing
          // Occupation
          Row(
            children: [
              Icon(Icons.work, size: 14, color: context.palette.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile.occupation,
                  style: context.styles.caption.copyWith(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6), // Reduced spacing
          // Location (neutral chip)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: context.palette.divider, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: context.palette.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    context.l10n.placeDistrictState(
                      profile.district,
                      profile.state,
                    ),
                    style: context.styles.overline.copyWith(
                      color: context.palette.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (statusLabel != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (statusColor ?? context.palette.accent).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (statusColor ?? context.palette.accent).withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: 14,
                    color: statusColor ?? context.palette.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel!,
                    style: context.styles.overline.copyWith(
                      color: statusColor ?? context.palette.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusL),
          bottomRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          // Left side - Shortlist button
          if (onShortlist != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShortlist,
                icon: Icon(
                  isShortlisted ? Icons.star : Icons.star_border,
                  color: context.palette.warning,
                  size: 18,
                ),
                label: Text(
                  isShortlisted
                      ? context.l10n.actionShortlisted
                      : context.l10n.actionShortlist,
                  style: TextStyle(
                    color: context.palette.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.palette.warning),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingS,
                  ),
                ),
              ),
            ),

          // Accept/Reject buttons for interests
          if (onAccept != null && onReject != null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReject,
                icon: Icon(Icons.close, color: context.palette.error, size: 18),
                label: Text(
                  context.l10n.actionReject,
                  style: TextStyle(
                    color: context.palette.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.palette.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingS,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: Icon(
                  Icons.favorite,
                  color: context.palette.onPrimary,
                  size: 18,
                ),
                label: Text(
                  context.l10n.actionAccept,
                  style: TextStyle(
                    color: context.palette.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingS,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Spacer when no left button
            if (onShortlist == null) const Spacer(),

            const SizedBox(width: AppDimensions.paddingM),

            // Right side - Send Interest button
            if (onInterest != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isInterestSent ? null : onInterest,
                  icon: Icon(
                    Icons.favorite,
                    color: context.palette.onPrimary,
                    size: 18,
                  ),
                  label: Text(
                    isInterestSent
                        ? context.l10n.actionInterestSent
                        : context.l10n.actionSendInterest,
                    style: TextStyle(
                      color: context.palette.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingS,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: context.palette.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
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

  bool _hasActionButtons() {
    return onInterest != null ||
        onShortlist != null ||
        onAccept != null ||
        onReject != null;
  }
}
