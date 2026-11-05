import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';

/// Profile → Settings: emails the member a link to set a new password.
class ChangePasswordTile extends StatelessWidget {
  const ChangePasswordTile({
    super.key,
    required this.email,
    required this.sendResetLink,
  });

  final String email;
  final Future<void> Function(String email) sendResetLink;

  Future<void> _confirmAndSend(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.settingsChangePassword),
        content: Text(l.changePasswordConfirm(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.changePasswordSend),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    String message;
    try {
      await sendResetLink(email);
      message = l.changePasswordSent(email);
    } catch (_) {
      message = l.changePasswordFailed;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.lock_reset, color: context.palette.accent),
      title: Text(
        context.l10n.settingsChangePassword,
        style: context.styles.body1,
      ),
      subtitle: Text(
        context.l10n.settingsChangePasswordSub,
        style: context.styles.caption,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _confirmAndSend(context),
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// The About dialog: app name, description and open-source licences.
void showAppAbout(BuildContext context) {
  final l = context.l10n;
  showAboutDialog(
    context: context,
    applicationName: l.appName,
    applicationIcon: Image.asset(
      'assets/icons/app_icon.png',
      width: 48,
      height: 48,
    ),
    children: [Text(l.aboutDescription)],
  );
}
