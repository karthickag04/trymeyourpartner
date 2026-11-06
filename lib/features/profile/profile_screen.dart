import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../settings/account_settings.dart';
import '../settings/help_screen.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../auth/auth_provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/theme/constants.dart';
import 'profile_edit_screen.dart';
import '../auth/auth_user.dart';
import '../../shared/services/matrimonial_service.dart';
import '../../shared/widgets/storage_image.dart';
import '../../shared/widgets/display_settings.dart';
import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
import '../../l10n/option_labels.dart';
import '../subscriptions/subscription.dart';
import '../subscriptions/subscription_service.dart';
import '../../app/di/service_locator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        backgroundColor: context.palette.primary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: context.l10n.accountActions,
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, MatrimonialProvider>(
        builder: (context, authProvider, matrimonialProvider, child) {
          if (authProvider.isLoading || matrimonialProvider.isLoading) {
            return _buildLoadingState();
          }

          if (!authProvider.isAuthenticated) {
            return _buildSignInPrompt();
          }

          final user = authProvider.user!;
          final matrimonialProfile = matrimonialProvider.currentUserProfile;

          if (matrimonialProfile == null) {
            // Provide diagnostics why profile isn't loaded and CTA to create
            return _buildNoMatrimonialProfile(user, matrimonialProvider);
          }

          return _buildProfileContent(user, matrimonialProfile);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: context.palette.accent),
          SizedBox(height: AppDimensions.paddingM),
          Text(context.l10n.profileLoading, style: context.styles.subtitle1),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: AppDimensions.iconXL * 2,
              color: context.palette.textTertiary,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              context.l10n.signInRequiredTitle,
              style: context.styles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              context.l10n.profileSignInBody,
              style: context.styles.body2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            ElevatedButton.icon(
              onPressed: () => _showSignInDialog(context),
              icon: const Icon(Icons.login),
              label: Text(context.l10n.authSignIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.accent,
                foregroundColor: context.palette.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingL,
                  vertical: AppDimensions.paddingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    AppAuthUser user,
    MatrimonialUser? matrimonialProfile,
  ) {
    final userProfile = context.read<AuthProvider>().userProfile;
    final userName =
        userProfile?['full_name'] ??
        user.email?.split('@')[0] ??
        context.l10n.defaultUserName;
    final userEmail = user.email ?? '';
    // Prefer matrimonial primary photo (photoUrls[0]), then profileImageUrl, then auth profile avatar
    final matAvatar = (matrimonialProfile?.photoUrls.isNotEmpty == true)
        ? matrimonialProfile!.photoUrls.first
        : (matrimonialProfile?.profileImageUrl ?? '');
    final avatarUrl = (matAvatar.isNotEmpty)
        ? matAvatar
        : (userProfile?['avatar_url'] ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          if (matrimonialProfile != null)
            FutureBuilder<Subscription?>(
              future: SubscriptionService.getActive(matrimonialProfile.id),
              builder: (context, snap) {
                final sub = snap.data;
                final tier = switch (sub?.tier.name) {
                  'gold' => context.l10n.planGold,
                  'platinum' => context.l10n.planPlatinum,
                  _ => context.l10n.planFree,
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: context.palette.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.planLabel(tier),
                        style: context.styles.subtitle1,
                      ),
                    ],
                  ),
                );
              },
            ),
          // Email Verification Banner
          if (!user.emailVerified) _buildVerificationBanner(),

          // Profile Header
          _buildProfileHeader(userName, userEmail, avatarUrl, user.createdAt),

          const SizedBox(height: AppDimensions.paddingL),

          // Matrimonial Profile Status
          _buildMatrimonialProfileStatus(matrimonialProfile),

          const SizedBox(height: AppDimensions.paddingL),

          // Matrimonial Profile Details (if available)
          if (matrimonialProfile != null)
            _buildMatrimonialProfileDetails(matrimonialProfile),

          const SizedBox(height: AppDimensions.paddingL),

          // Profile Stats
          _buildProfileStats(),

          const SizedBox(height: AppDimensions.paddingL),

          // Quick Actions
          _buildQuickActions(),

          const SizedBox(height: AppDimensions.paddingL),

          // App Settings
          _buildAppSettings(userEmail),

          const SizedBox(height: AppDimensions.paddingXL),

          // Sign Out Button
          _buildSignOutButton(),
        ],
      ),
    );
  }

  Widget _buildVerificationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: context.palette.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: context.palette.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_unread, color: context.palette.warning),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.emailVerificationTitle,
                  style: context.styles.subtitle2.copyWith(
                    color: context.palette.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  context.l10n.emailVerificationBody,
                  style: context.styles.caption,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _resendVerificationEmail,
            child: Text(
              context.l10n.actionResend,
              style: TextStyle(color: context.palette.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    String email,
    String avatarUrl,
    DateTime? memberSince,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: context.palette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Stack(
            children: [
              FutureBuilder<String?>(
                future: _resolveAvatarUrl(avatarUrl),
                builder: (context, snap) {
                  final resolved = snap.data;
                  if (resolved != null && resolved.isNotEmpty) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: context.palette.accent,
                      backgroundImage: NetworkImage(resolved),
                    );
                  }
                  return CircleAvatar(
                    radius: 50,
                    backgroundColor: context.palette.accent,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: context.styles.heading2.copyWith(
                        color: context.palette.onPrimary,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Semantics(
                  button: true,
                  label: context.l10n.changePhoto,
                  child: GestureDetector(
                    onTap: () => _showImagePicker(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingS),
                      decoration: BoxDecoration(
                        color: context.palette.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: context.palette.onPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // User Info
          Text(
            name,
            style: context.styles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            email,
            style: context.styles.body2.copyWith(
              color: context.palette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            context.l10n.memberSince(
              context.formatDate(memberSince ?? DateTime.now()),
            ),
            style: context.styles.caption,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Edit + Manage Photos Buttons (Wrap to avoid overflow on narrow widths)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppDimensions.paddingM,
            runSpacing: AppDimensions.paddingS,
            children: [
              OutlinedButton.icon(
                onPressed: () => _navigateToProfileEdit(),
                icon: const Icon(Icons.edit),
                label: Text(context.l10n.actionEditProfile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.accent,
                  side: BorderSide(color: context.palette.accent),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showManagePhotosSheet,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(context.l10n.actionManagePhotos),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.accent,
                  side: BorderSide(color: context.palette.accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(context.l10n.statInterests, '0', Icons.favorite),
            _buildStatItem(context.l10n.statMatches, '0', Icons.people),
            _buildStatItem(context.l10n.profileTitle, '0', Icons.person),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Consumer<MatrimonialProvider>(
        builder: (context, matrimony, _) {
          final profile = matrimony.currentUserProfile;
          final complete =
              profile != null && matrimony.isMandatoryComplete(profile);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context.l10n.statInterests,
                matrimony.sentInterests.length.toString(),
                Icons.favorite,
              ),
              _buildStatItem(
                context.l10n.statMatches,
                matrimony.acceptedConnections.length.toString(),
                Icons.people,
              ),
              _buildStatItem(
                context.l10n.profileTitle,
                complete
                    ? context.l10n.statComplete
                    : context.l10n.statIncomplete,
                Icons.person,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: context.palette.accent, size: AppDimensions.iconL),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          value,
          style: context.styles.heading3.copyWith(
            color: context.palette.accent,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        Text(label, style: context.styles.caption),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.quickActionsTitle, style: context.styles.subtitle1),
          const SizedBox(height: AppDimensions.paddingM),
          _buildActionItem(
            context.l10n.quickFavorites,
            context.l10n.quickFavoritesSub,
            Icons.favorite,
            () => _navigateToInterests(),
          ),
          _buildActionItem(
            context.l10n.statMatches,
            context.l10n.quickMatchesSub,
            Icons.people,
            () => _navigateToMatches(),
          ),
          _buildActionItem(
            context.l10n.quickCompletion,
            context.l10n.quickCompletionSub,
            Icons.edit,
            () => _navigateToProfileCompletion(),
          ),
          _buildActionItem(
            context.l10n.quickRefresh,
            context.l10n.quickRefreshSub,
            Icons.refresh,
            () => _refreshData(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: context.palette.accent),
      title: Text(title, style: context.styles.body1),
      subtitle: Text(subtitle, style: context.styles.caption),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAppSettings(String email) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.settingsTitle, style: context.styles.subtitle1),
          const SizedBox(height: AppDimensions.paddingM),
          const DisplaySettings(),
          const SizedBox(height: AppDimensions.paddingM),
          const Divider(),
          if (email.isNotEmpty)
            ChangePasswordTile(
              email: email,
              sendResetLink: sl.authService.resetPassword,
            ),
          _buildActionItem(
            context.l10n.helpTitle,
            context.l10n.settingsHelpSub,
            Icons.help,
            () => _navigateToHelp(),
          ),
          _buildActionItem(
            context.l10n.settingsAbout,
            context.l10n.settingsAboutSub,
            Icons.info,
            () => showAppAbout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showSignOutDialog,
        icon: const Icon(Icons.logout),
        label: Text(context.l10n.actionSignOut),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.palette.error,
          foregroundColor: context.palette.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        ),
      ),
    );
  }

  // Action Methods
  void _showSignInDialog(BuildContext context) {
    // This shouldn't be called since we're using AuthWrapper
    // But just in case, we can show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.restartToSignIn),
        backgroundColor: context.palette.warning,
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    final authProvider = context.read<AuthProvider>();
    try {
      final ok = await authProvider.resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? context.l10n.verificationEmailSent
                  : context.l10n.verificationEmailFailed,
            ),
            backgroundColor: ok
                ? context.palette.success
                : context.palette.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.verificationEmailFailed),
            backgroundColor: context.palette.error,
          ),
        );
      }
    }
  }

  void _showImagePicker(BuildContext context) {
    debugPrint('[ProfilePhoto] open picker');
    showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(context.l10n.photoTake),
              onTap: () {
                debugPrint('[ProfilePhoto] source: camera');
                Navigator.pop(context, 'camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.photoGallery),
              onTap: () {
                debugPrint('[ProfilePhoto] source: gallery');
                Navigator.pop(context, 'gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.commonCancel),
              onTap: () {
                debugPrint('[ProfilePhoto] source: cancel');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ).then((source) async {
      if (source == null) {
        debugPrint('[ProfilePhoto] picker dismissed');
        return;
      }
      final auth = context.read<AuthProvider>();
      final mat = context.read<MatrimonialProvider>();
      final me = mat.currentUserProfile;
      final pid = me?.id ?? auth.user?.id ?? '';
      if (pid.isEmpty) {
        debugPrint('[ProfilePhoto] no profile/user id, abort');
        return;
      }
      debugPrint(
        '[ProfilePhoto] launching photo flow: fromCamera=${source == 'camera'} pid=$pid',
      );
      final url = await sl.photoService.pickEditCompressAndUpload(
        context: context,
        profileId: pid,
        slotIndex: -1,
        fromCamera: source == 'camera',
      );
      debugPrint('[ProfilePhoto] upload result: $url');
      if (url == null) return;
      // Update auth profile metadata and public profile
      final ok = await auth.updateProfile(avatarUrl: url);
      debugPrint('[ProfilePhoto] auth.updateProfile: $ok');
      // Also persist into matrimonial_profiles.profile_image_url so DB reflects latest avatar
      try {
        final mat = context.read<MatrimonialProvider>();
        final me = mat.currentUserProfile;
        if (me != null) {
          // Ensure the uploaded avatar appears in photo_urls as well (insert at 0 if absent)
          final photos = List<String>.from(me.photoUrls)
            ..removeWhere((e) => e.trim().isEmpty);
          if (!photos.contains(url)) photos.insert(0, url);
          final updated = me.copyWith(profileImageUrl: url, photoUrls: photos);
          debugPrint(
            '[ProfilePhoto] saving matrimonial profile_image_url -> '
            '${updated.profileImageUrl} and photo_urls_len=${photos.length}',
          );
          await mat.saveUserProfile(updated);
          debugPrint('[ProfilePhoto] matrimonial profile_image_url saved');
        } else {
          debugPrint(
            '[ProfilePhoto] WARN: No currentUserProfile, skip matrimonial save',
          );
        }
      } catch (e) {
        debugPrint('[ProfilePhoto] ERROR saving matrimonial profile image: $e');
      }
      if (mounted) setState(() {});
    });
  }

  Future<String?> _resolveAvatarUrl(String avatarUrl) async {
    if (avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('http')) return avatarUrl;
    try {
      return await sl.storageService.getSignedUrl(avatarUrl);
    } catch (_) {
      return null;
    }
  }

  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
  }

  // Photos manager bottom sheet (single source of truth: photo_urls; index 0 = avatar)
  Future<void> _showManagePhotosSheet() async {
    final provider = context.read<MatrimonialProvider>();
    final me = provider.currentUserProfile;
    if (me == null) return;
    List<String> photos = List<String>.from(me.photoUrls);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> saveNow() async {
              final updated = me.copyWith(
                photoUrls: photos,
                profileImageUrl: photos.isNotEmpty
                    ? photos.first
                    : me.profileImageUrl,
              );
              debugPrint(
                '[PhotosSheet] saving photos_len=${photos.length} avatar=${updated.profileImageUrl}',
              );
              await provider.saveUserProfile(updated);
              if (mounted) setState(() {});
            }

            Future<void> addPhoto() async {
              final url = await sl.photoService.pickEditCompressAndUpload(
                context: context,
                profileId: me.id,
                slotIndex: photos.length,
                fromCamera: false,
              );
              if (url == null) return;
              setSheetState(() {
                if (!photos.contains(url)) photos.add(url);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppDimensions.paddingM,
                right: AppDimensions.paddingM,
                top: AppDimensions.paddingM,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo_library_outlined),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.actionManagePhotos,
                        style: context.styles.heading3,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_a_photo),
                        onPressed: addPhoto,
                        tooltip: context.l10n.photoAdd,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: photos.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (c, i) {
                      if (i == photos.length) {
                        return InkWell(
                          onTap: addPhoto,
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.palette.accent.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                color: context.palette.accent,
                              ),
                            ),
                          ),
                        );
                      }
                      final src = photos[i];
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: StorageImage(src: src, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () async {
                                setSheetState(() {
                                  photos.removeAt(i);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.palette.imageScrim.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: context.palette.onImage,
                                  semanticLabel: context.l10n.photoRemove,
                                ),
                              ),
                            ),
                          ),
                          if (i == 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: _badge(context.l10n.photoPrimary),
                            )
                          else
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    final v = photos.removeAt(i);
                                    photos.insert(0, v);
                                  });
                                },
                                child: _badge(context.l10n.photoMakePrimary),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(context.l10n.commonClose),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await saveNow();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.save),
                        label: Text(context.l10n.commonSave),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: context.palette.imageScrim.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: context.styles.micro.copyWith(color: context.palette.onImage),
    ),
  );

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.settingsTitle),
        content: Text(context.l10n.accountActions),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonClose),
          ),
          Builder(
            builder: (dialogCtx) {
              final profile = context
                  .read<MatrimonialProvider>()
                  .currentUserProfile;
              final isDeactivated =
                  profile != null && profile.isActive == false;
              return TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (isDeactivated) {
                    try {
                      final ok = await MatrimonialService.reactivateProfile(
                        profile.id,
                      );
                      if (ok) {
                        final auth = context.read<AuthProvider>();
                        await context
                            .read<MatrimonialProvider>()
                            .forceRefreshUserData(auth.user?.id ?? '');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.profileReactivated),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.profileReactivateFailed),
                          ),
                        );
                      }
                    }
                  } else {
                    await _confirmDeactivateFromProfile();
                  }
                },
                child: Text(
                  isDeactivated
                      ? context.l10n.actionReactivateProfile
                      : context.l10n.actionDeactivateProfile,
                ),
              );
            },
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _confirmDeleteFromProfile();
            },
            child: Text(
              context.l10n.actionDeleteProfile,
              style: TextStyle(color: context.palette.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivateFromProfile() async {
    if (!mounted) return;
    final matrimonialProvider = context.read<MatrimonialProvider>();
    final auth = context.read<AuthProvider>();
    final profile = matrimonialProvider.currentUserProfile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileNotLoaded),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.actionDeactivateProfile),
        content: Text(context.l10n.deactivateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionDeactivate),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final success = await MatrimonialService.deactivateProfile(profile.id);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileDeactivated),
            backgroundColor: context.palette.success,
          ),
        );
        await matrimonialProvider.forceRefreshUserData(auth.user?.id ?? '');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileDeactivateFailed),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  Future<void> _confirmDeleteFromProfile() async {
    if (!mounted) return;
    final matrimonialProvider = context.read<MatrimonialProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final profile = matrimonialProvider.currentUserProfile;
    if (profile == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileNotLoaded),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.actionDeleteProfile),
        content: Text(context.l10n.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.error,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final success = await MatrimonialService.deleteProfile(profile.id);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileDeleted),
            backgroundColor: context.palette.success,
          ),
        );
        await auth.signOut();
        matrimonialProvider.clearAllData();
        nav.pushNamedAndRemoveUntil('/', (r) => false);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileDeleteFailed),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.actionSignOut),
        content: Text(context.l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog first
              Navigator.of(context).pop();

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text(context.l10n.signingOut),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              // Sign out
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.error,
            ),
            child: Text(context.l10n.actionSignOut),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToInterests() => context.go(AppRoutes.interests);

  void _navigateToMatches() => context.go(AppRoutes.matches);

  void _navigateToProfileCompletion() {
    // Navigate to profile edit screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
    );
  }

  void _navigateToHelp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HelpScreen()));
  }

  Widget _buildMatrimonialProfileStatus(MatrimonialUser? matrimonialProfile) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: matrimonialProfile != null
            ? (matrimonialProfile.isActive
                  ? context.palette.success.withValues(alpha: 0.1)
                  : context.palette.warning.withValues(alpha: 0.1))
            : context.palette.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: matrimonialProfile != null
              ? (matrimonialProfile.isActive
                    ? context.palette.success.withValues(alpha: 0.3)
                    : context.palette.warning.withValues(alpha: 0.3))
              : context.palette.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            matrimonialProfile != null
                ? (matrimonialProfile.isActive
                      ? Icons.check_circle
                      : Icons.warning)
                : Icons.warning,
            color: matrimonialProfile != null
                ? (matrimonialProfile.isActive
                      ? context.palette.success
                      : context.palette.warning)
                : context.palette.warning,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              matrimonialProfile != null
                  ? (matrimonialProfile.isActive
                        ? context.l10n.profileStatusActive
                        : context.l10n.profileStatusDeactivated)
                  : context.l10n.profileStatusMissing,
              style: context.styles.body2.copyWith(
                color: matrimonialProfile != null
                    ? (matrimonialProfile.isActive
                          ? context.palette.success
                          : context.palette.warning)
                    : context.palette.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (matrimonialProfile != null && !matrimonialProfile.isActive)
            TextButton(
              onPressed: () async {
                try {
                  final ok = await MatrimonialService.reactivateProfile(
                    matrimonialProfile.id,
                  );
                  if (ok) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.profileReactivated)),
                    );
                    final auth = context.read<AuthProvider>();
                    await context
                        .read<MatrimonialProvider>()
                        .forceRefreshUserData(auth.user?.id ?? '');
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.profileReactivateFailed),
                    ),
                  );
                }
              },
              child: Text(context.l10n.actionReactivate),
            ),
        ],
      ),
    );
  }

  Widget _buildNoMatrimonialProfile(
    AppAuthUser user,
    MatrimonialProvider matrimonialProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(
            user.fullName ??
                user.email?.split('@').first ??
                context.l10n.defaultUserName,
            user.email ?? '',
            '',
            user.createdAt,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: context.palette.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: context.palette.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.palette.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.noProfileTitle,
                      style: context.styles.subtitle2.copyWith(
                        color: context.palette.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(context.l10n.noProfileBody),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Ask service to auto-create a minimal profile then navigate to edit
                        try {
                          final created =
                              await MatrimonialService.ensureProfileForCurrentUser();
                          if (created) {
                            // Reload and go to edit screen
                            await matrimonialProvider.forceRefreshUserData(
                              user.id,
                            );
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileEditScreen(),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.createProfileFailed,
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.createProfileFailed),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: Text(context.l10n.actionCreateProfile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.palette.accent,
                        foregroundColor: context.palette.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Try restoring from archived deleted_users (if any)
                        try {
                          final restoredId =
                              await MatrimonialService.restoreProfileForCurrentUser();
                          if (restoredId != null) {
                            await matrimonialProvider.forceRefreshUserData(
                              user.id,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.profileRestored),
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileEditScreen(),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.noArchivedProfile),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.restoreFailed),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.restore),
                      label: Text(context.l10n.actionRestoreProfile),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Diagnostics: log why profile might be missing
                        final auth = context.read<AuthProvider>();
                        final authId = auth.user?.id;
                        final email = auth.user?.email;
                        debugPrint(
                          '[ProfileScreen] Missing profile for authId=$authId email=$email',
                        );
                        final existing =
                            await MatrimonialService.getCurrentUserProfile(
                              authId ?? '',
                            );
                        debugPrint(
                          '[ProfileScreen] getCurrentUserProfile returned: ${existing?.id ?? 'null'}',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.diagnosticsPrinted),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.bug_report),
                      label: Text(context.l10n.actionPrintDiagnostics),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrimonialProfileDetails(MatrimonialUser matrimonialProfile) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: context.palette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.myProfileTitle, style: context.styles.heading3),
          const SizedBox(height: AppDimensions.paddingM),

          // Basic Info
          _buildInfoRow(context.l10n.fieldName, matrimonialProfile.name),
          _buildInfoRow(
            context.l10n.fieldAge,
            context.l10n.ageYearsLong(matrimonialProfile.age),
          ),
          _buildInfoRow(
            context.l10n.fieldGender,
            context.optionLabel(matrimonialProfile.gender),
          ),
          _buildInfoRow(
            context.l10n.fieldHeight,
            (matrimonialProfile.heightInFeetInches ??
                context.l10n.commonNotSpecified),
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Education & Occupation
          _buildInfoRow(
            context.l10n.fieldEducation,
            matrimonialProfile.education,
          ),
          _buildInfoRow(
            context.l10n.fieldOccupation,
            matrimonialProfile.occupation,
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Location
          _buildInfoRow(
            context.l10n.fieldLocation,
            context.l10n.placeDistrictState(
              matrimonialProfile.district,
              matrimonialProfile.state,
            ),
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Religion & Caste
          _buildInfoRow(
            context.l10n.fieldReligion,
            context.optionLabel(matrimonialProfile.religion),
          ),
          _buildInfoRow(context.l10n.fieldCaste, matrimonialProfile.caste),

          const SizedBox(height: AppDimensions.paddingL),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToProfileEdit(),
              icon: const Icon(Icons.edit),
              label: Text(context.l10n.actionEditMyProfile),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: context.styles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: context.styles.body2)),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    debugPrint('ProfileScreen: Manual refresh requested');
    final matrimonialProvider = Provider.of<MatrimonialProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final userId = authProvider.userId;
    if (userId != null) {
      await matrimonialProvider.forceRefreshUserData(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.refreshSuccess),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.refreshNotSignedIn),
            duration: Duration(seconds: 2),
            backgroundColor: context.palette.error,
          ),
        );
      }
    }
  }
}
