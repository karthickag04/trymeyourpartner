import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../session/session_controller.dart';
import 'centered_card.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<SessionController>().signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final text = Theme.of(context).textTheme;
    return CenteredCard(
      children: [
        Text('TryMeYourPartner', style: text.titleMedium),
        Text('Staff console', style: text.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'For staff accounts only. You will be asked for a code from your '
          'authenticator app after your password.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 24),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  key: const Key('email'),
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Work email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter your work email'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password'),
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
              ],
            ),
          ),
        ),
        if (session.error != null) ErrorText(session.error!),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('sign-in'),
          onPressed: session.busy ? null : _submit,
          child: session.busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sign in'),
        ),
      ],
    );
  }
}
