import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../session/session_controller.dart';
import 'centered_card.dart';

/// Shown to users without an active staff account. They have been signed out.
class RefusedScreen extends StatelessWidget {
  const RefusedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CenteredCard(
      children: [
        Icon(Icons.block, size: 40, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Text('No staff access', style: text.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'This account does not have staff access to the console, so you '
          'have been signed out. Members use the TryMeYourPartner app. If you '
          'are staff, ask your administrator to set up your account.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: context.read<SessionController>().backToSignIn,
          child: const Text('Back to sign-in'),
        ),
      ],
    );
  }
}
