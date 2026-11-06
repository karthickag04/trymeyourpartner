import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/services/matrimonial_service.dart';
import '../../shared/theme/constants.dart';
import 'profile_detail_screen.dart';

/// Shows the profile behind a `/p/<code>` link. Uses the profile passed in when
/// opened from inside the app; otherwise loads it by its code (or id).
class ProfileLinkScreen extends StatelessWidget {
  final String code;
  final MatrimonialUser? preloaded;

  const ProfileLinkScreen({super.key, required this.code, this.preloaded});

  @override
  Widget build(BuildContext context) {
    final p = preloaded;
    if (p != null) return ProfileDetailScreen(profile: p);
    return FutureBuilder<MatrimonialUser?>(
      future: MatrimonialService.getProfileByCode(code),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: context.palette.primary),
            ),
          );
        }
        final profile = snap.data;
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Text(
                  context.l10n.profileNotAvailable,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return ProfileDetailScreen(profile: profile);
      },
    );
  }
}
