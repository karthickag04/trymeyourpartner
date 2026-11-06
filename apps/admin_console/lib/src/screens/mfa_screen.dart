import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../session/session_controller.dart';
import 'centered_card.dart';

/// Second sign-in step: add an authenticator app (first sign-in) or enter
/// its current code (every sign-in).
class MfaScreen extends StatefulWidget {
  const MfaScreen({super.key});

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.trim().length != 6) return;
    context.read<SessionController>().verifyCode(_code.text);
  }

  void _copy(String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$what copied')));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final text = Theme.of(context).textTheme;
    final enrolment = session.enrolment;
    return CenteredCard(
      children: [
        Text(
          enrolment != null
              ? 'Set up your authenticator app'
              : 'Enter your authenticator code',
          style: text.headlineSmall,
        ),
        const SizedBox(height: 8),
        if (enrolment != null) ...[
          Text(
            'Staff accounts need two-step sign-in. In an authenticator app '
            '(Google Authenticator, Microsoft Authenticator, 1Password, …) '
            'add an account with this setup key, then enter the 6-digit code '
            'it shows.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          SelectableText(
            _grouped(enrolment.secret),
            key: const Key('totp-secret'),
            style: text.titleMedium?.copyWith(fontFamily: 'monospace'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _copy(enrolment.secret, 'Setup key'),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy key'),
              ),
              TextButton.icon(
                onPressed: () => _copy(enrolment.uri, 'Setup link'),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copy otpauth link'),
              ),
            ],
          ),
        ] else
          Text(
            'Open your authenticator app and enter the current 6-digit code '
            'for TryMeYourPartner.',
            style: text.bodyMedium,
          ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('totp-code'),
          controller: _code,
          decoration: const InputDecoration(labelText: '6-digit code'),
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _submit(),
        ),
        if (session.error != null) ErrorText(session.error!),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('verify'),
          onPressed: session.busy ? null : _submit,
          child: const Text('Verify'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: session.busy ? null : session.signOut,
          child: const Text('Sign out'),
        ),
      ],
    );
  }

  static String _grouped(String s) {
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}
