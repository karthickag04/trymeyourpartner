import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../session/session_controller.dart';

/// Who am I: role, branch, team and what this account may do.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final p = session.profile!;
    final text = Theme.of(context).textTheme;
    final scope = switch (p.role) {
      'system_admin' || 'super_admin' || 'admin' => 'All branches',
      'branch_manager' => 'Branch ${p.branchName ?? ''}',
      'team_lead' => 'Team ${p.teamName ?? ''}',
      _ => 'Your own records',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Dashboard', style: text.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signed in as', style: text.titleMedium),
                const SizedBox(height: 8),
                _Row('Name', p.displayName.isEmpty ? '—' : p.displayName),
                _Row('Email', session.email ?? '—'),
                _Row('Role', roleLabel(p.role)),
                _Row('Branch', p.branchName ?? '—'),
                _Row('Team', p.teamName ?? '—'),
                _Row('Scope', scope),
                const _Row('Sign-in', 'Password + authenticator app'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your permissions', style: text.titleMedium),
                const SizedBox(height: 8),
                if (p.permissions.isEmpty)
                  const Text('This role has no permissions yet.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in p.permissions) Chip(label: Text(key)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
