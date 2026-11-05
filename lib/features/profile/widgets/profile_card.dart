import 'package:flutter/material.dart';
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
      color: AppColors.cardBackground,
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
                      color: AppColors.surface,
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
                  // Presence dot overlay bottom-right
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
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
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 18,
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
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced for better fit
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.isVerified)
                            const Icon(
                              Icons.verified,
                              color: AppColors.success,
                              size: 12, // Smaller icon
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Presence text under name
                      PresenceIndicator(
                        profileId: profile.id,
                        showText: true,
                        textColor: Colors.black54,
                        pollEvery: Duration(seconds: 60),
                      ),

                      const SizedBox(height: 2), // Reduced spacing
                      // Age and Height
                      Text(
                        '${profile.age} years, ${profile.heightInFeetInches}',
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Education
                      Text(
                        profile.education,
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Occupation
                      Text(
                        profile.occupation,
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
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
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      '${profile.district}, ${profile.state}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.accent,
                                        fontSize: 10,
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
                            tooltip: 'Why matched',
                            icon: const Icon(Icons.info_outline, size: 16),
                            onPressed: () => _showWhyMatch(context),
                          ),

                          // Send Interest Button
                          if (onInterest != null)
                            SizedBox(
                              height: 28,
                              child: ElevatedButton.icon(
                                onPressed: isInterestSent ? null : onInterest,
                                icon: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                label: Text(
                                  isInterestSent ? 'Interest Sent' : 'Interest',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  elevation: 1,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  minimumSize: const Size(0, 28),
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
                constraints: const BoxConstraints(minHeight: 35, maxHeight: 50),
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
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 18,
                          ),
                          tooltip: 'Accept',
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    if (onReject != null)
                      Expanded(
                        child: IconButton(
                          onPressed: onReject,
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: AppColors.error,
                            size: 18,
                          ),
                          tooltip: 'Reject',
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
                            color: AppColors.warning,
                            size: 18,
                          ),
                          tooltip: isShortlisted
                              ? 'Remove from Shortlist'
                              : 'Add to Shortlist',
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

  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  void _showWhyMatch(BuildContext context) {
    final reasons = _computeWhyMatch(profile);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => Row(
            children: [
              const Icon(Icons.check, size: 16, color: AppColors.accent),
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

  List<String> _computeWhyMatch(MatrimonialUser other) {
    final List<String> reasons = [];
    // NOTE: This is a lightweight, client-only heuristic. Replace with backend view later.
    if (other.district.isNotEmpty) {
      reasons.add('You live near ${other.district}');
    }
    if (other.education.isNotEmpty) {
      reasons.add('Similar education: ${other.education}');
    }
    if (other.caste.isNotEmpty) {
      reasons.add('Caste preference matched: ${other.caste}');
    }
    if (other.languages.isNotEmpty) {
      reasons.add('Language overlap: ${other.languages.join(', ')}');
    }
    if (reasons.isEmpty) {
      reasons.add('Good compatibility based on your preferences');
    }
    return reasons.take(4).toList();
  }
}
