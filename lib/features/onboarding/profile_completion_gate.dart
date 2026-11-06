import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../l10n/l10n.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../shared/theme/constants.dart';
import '../../shared/services/matrimonial_service.dart';
import 'gate_decision.dart';
import 'simple_registration_screen.dart';

/// Shows [child] once the signed-in member's required profile details are
/// saved. Registration is only for a member with no profile or with details
/// missing; while the profile is loading, or if it could not be loaded, the
/// member sees a spinner or a retry, never an empty registration form.
class ProfileCompletionGate extends StatefulWidget {
  final Widget child;
  const ProfileCompletionGate({super.key, required this.child});

  @override
  State<ProfileCompletionGate> createState() => _ProfileCompletionGateState();
}

class _ProfileCompletionGateState extends State<ProfileCompletionGate> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    if (_started && !force) return;
    _started = true;
    final auth = context.read<AuthProvider>();
    final matrimony = context.read<MatrimonialProvider>();
    final uid = auth.user?.id;
    if (uid == null) return;
    if (force) {
      await matrimony.forceRefreshUserData(uid);
    } else {
      await matrimony.loadAllUserData(uid);
    }
    // Only a load that succeeded and found nothing means "new member".
    if (matrimony.profileLoadState == ProfileLoadState.loaded &&
        matrimony.currentUserProfile == null) {
      try {
        final created = await MatrimonialService.ensureProfileForCurrentUser();
        if (created) await matrimony.forceRefreshUserData(uid);
      } catch (_) {
        // The registration form creates the profile on save instead.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MatrimonialProvider>(
      builder: (context, auth, matrimony, _) {
        final view = decideGate(
          authLoading: auth.isLoading,
          signedIn: auth.isAuthenticated,
          profileState: matrimony.profileLoadState,
          profile: matrimony.currentUserProfile,
        );
        switch (view) {
          case GateView.waiting:
            return Scaffold(
              backgroundColor: context.palette.background,
              body: Center(
                child: CircularProgressIndicator(color: context.palette.accent),
              ),
            );
          case GateView.loadFailed:
            return ProfileLoadFailedView(onRetry: () => _load(force: true));
          case GateView.register:
            return const SimpleRegistrationScreen();
          case GateView.app:
            return widget.child;
        }
      },
    );
  }
}

/// Shown when the member's profile could not be loaded.
class ProfileLoadFailedView extends StatelessWidget {
  const ProfileLoadFailedView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: context.palette.accent),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                context.l10n.profileLoadFailed,
                textAlign: TextAlign.center,
                style: context.styles.body1,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              FilledButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
