import 'package:flutter/material.dart';
import '../models/matrimonial_user.dart';
import '../utils/constants.dart';
import 'presence_indicator.dart';
import 'storage_image.dart';

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
      color: AppColors.cardBackground,
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
                  _buildProfileImage(),

                  // Right side - Profile Details
                  Expanded(child: _buildProfileDetails()),
                ],
              ),
            ),

            // Bottom - Action Buttons
            if (_hasActionButtons()) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
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
              color: AppColors.surface,
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
                        color: AppColors.surface,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      errorWidget: _buildDefaultAvatar(),
                      emptyWidget: _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
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
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 16),
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
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
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
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                textColor: AppColors.textSecondary,
                pollEvery: Duration(seconds: 60),
              ),
            ],
          ),

          const SizedBox(height: 4), // Reduced spacing
          // Age and Height
          Row(
            children: [
              Icon(Icons.cake, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${profile.age} years',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12, // Smaller text
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Icon(Icons.height, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                profile.heightInFeetInches,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12, // Smaller text
                ),
              ),
            ],
          ),

          const SizedBox(height: 6), // Reduced spacing
          // Education
          Row(
            children: [
              Icon(Icons.school, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile.education,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12, // Smaller text
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
              Icon(Icons.work, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile.occupation,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12, // Smaller text
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${profile.district}, ${profile.state}',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
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
                color: (statusColor ?? AppColors.accent).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (statusColor ?? AppColors.accent).withValues(
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
                    color: statusColor ?? AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel!,
                    style: AppTextStyles.body2.copyWith(
                      color: statusColor ?? AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  color: AppColors.warning,
                  size: 18,
                ),
                label: Text(
                  isShortlisted ? 'Shortlisted' : 'Shortlist',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.warning),
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
                icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                label: const Text(
                  'Reject',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
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
                icon: const Icon(Icons.favorite, color: Colors.white, size: 18),
                label: const Text(
                  'Accept',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
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
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    isInterestSent ? 'Interest Sent' : 'Send Interest',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
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

  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
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
