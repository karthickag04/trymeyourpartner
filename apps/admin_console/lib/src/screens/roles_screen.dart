import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../session/session_controller.dart';

/// The role/permission matrix. Read-only, except for holders of
/// `roles.manage` (system_admin), who can grant and revoke. System admin's
/// own column is fixed: it always holds every permission.
class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  late Future<RoleMatrix> _matrix = _load();
  final _saving = <String>{};

  SessionController get _session => context.read<SessionController>();

  Future<RoleMatrix> _load() => _session.backend.loadRoleMatrix();

  Future<void> _toggle(RoleMatrix m, String role, String key, bool on) async {
    final id = RoleMatrix.grantKey(role, key);
    setState(() {
      _saving.add(id);
      m.set(role, key, on);
    });
    try {
      await _session.backend.setGrant(role: role, permission: key, granted: on);
    } catch (e) {
      if (!mounted) return;
      setState(() => m.set(role, key, !on));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Not saved: ${describeError(e)}')));
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final editable = context.watch<SessionController>().profile!.can(
      'roles.manage',
    );
    return FutureBuilder<RoleMatrix>(
      future: _matrix,
      builder: (context, snap) {
        final Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snap.hasError) {
          body = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(describeError(snap.error!)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => setState(() => _matrix = _load()),
                child: const Text('Try again'),
              ),
            ],
          );
        } else {
          body = _table(snap.data!, editable);
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Roles & permissions', style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              editable
                  ? 'Changes save immediately and are recorded in the audit log. '
                        'System admin always holds every permission.'
                  : 'Read-only. Only a system admin can change permissions.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            body,
          ],
        );
      },
    );
  }

  Widget _table(RoleMatrix m, bool editable) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          columns: [
            const DataColumn(label: Text('Permission')),
            for (final r in staffRoles) DataColumn(label: Text(roleLabel(r))),
          ],
          rows: [
            for (final p in m.permissions)
              DataRow(
                cells: [
                  DataCell(
                    Tooltip(
                      message: p.key,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text('${p.category}: ${p.description}'),
                      ),
                    ),
                  ),
                  for (final r in staffRoles)
                    DataCell(
                      editable && r != 'system_admin'
                          ? Checkbox(
                              key: Key('grant-$r-${p.key}'),
                              value: m.has(r, p.key),
                              onChanged:
                                  _saving.contains(
                                    RoleMatrix.grantKey(r, p.key),
                                  )
                                  ? null
                                  : (v) => _toggle(m, r, p.key, v ?? false),
                            )
                          : Icon(
                              m.has(r, p.key) ? Icons.check : Icons.remove,
                              key: Key('grant-$r-${p.key}'),
                              color: m.has(r, p.key)
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              semanticLabel: m.has(r, p.key)
                                  ? 'Granted'
                                  : 'Not granted',
                            ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
