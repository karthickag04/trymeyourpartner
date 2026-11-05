import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/matrimonial_provider.dart';
import '../utils/constants.dart';
import '../services/matrimonial_service.dart';
import 'matrimonial_main_screen.dart';
import 'simple_registration_screen.dart';

class ProfileCompletionGate extends StatefulWidget {
  const ProfileCompletionGate({super.key});

  @override
  State<ProfileCompletionGate> createState() => _ProfileCompletionGateState();
}

class _ProfileCompletionGateState extends State<ProfileCompletionGate> {
  bool _started = false;
  @override
  void initState() {
    super.initState();
    // Ensure user data is loaded when entering the gate
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_started) return;
      _started = true;
      final auth = context.read<AuthProvider>();
      final matrimony = context.read<MatrimonialProvider>();
      final uid = auth.user?.id;
      if (uid != null) {
        await matrimony.loadAllUserData(uid);
        // If no profile exists yet, auto-create a minimal profile for edit
        if (matrimony.currentUserProfile == null) {
          try {
            final created =
                await MatrimonialService.ensureProfileForCurrentUser();
            if (created) {
              await matrimony.forceRefreshUserData(uid);
              // The server creates the Free plan for new profiles.
            }
          } catch (e) {
            // Policies might not be ready yet; defer creation to registration screen
            // debugPrint('Gate: ensureProfileForCurrentUser failed: $e');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MatrimonialProvider>(
      builder: (context, auth, matrimony, _) {
        // Lightweight debug to trace routing decisions
        // ignore: invalid_use_of_protected_member
        // debugPrint('Gate: loading auth=${auth.isLoading} data=${matrimony.isLoading}');
        if (auth.isLoading || matrimony.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final profile = matrimony.currentUserProfile;
        // If no profile exists yet, send user to Simple Registration
        if (profile == null) {
          // debugPrint('Gate: no profile -> SimpleRegistrationScreen');
          return const SimpleRegistrationScreen();
        }

        // Compute mandatory completion
        final isComplete = matrimony.isMandatoryComplete(profile);
        if (!isComplete) {
          // debugPrint('Gate: incomplete -> SimpleRegistrationScreen');
          return const SimpleRegistrationScreen();
        }

        // debugPrint('Gate: complete -> MatrimonialMainScreen');
        return const MatrimonialMainScreen();
      },
    );
  }
}
