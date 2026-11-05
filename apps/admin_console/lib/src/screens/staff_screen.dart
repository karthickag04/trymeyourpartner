import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../session/session_controller.dart';

/// Staff accounts in the signed-in user's scope. The database decides the
/// scope: admins see every branch, a branch manager only their own.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late Future<List<StaffMember>> _staff = _load();

  Future<List<StaffMember>> _load() =>
      context.read<SessionController>().backend.listStaff();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final profile = context.watch<SessionController>().profile!;
    final heading = profile.role == 'branch_manager'
        ? 'Staff · ${profile.branchName ?? 'your branch'}'
        : 'Staff';
    return FutureBuilder<List<StaffMember>>(
      future: _staff,
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
                onPressed: () => setState(() => _staff = _load()),
                child: const Text('Try again'),
              ),
            ],
          );
        } else if (snap.data!.isEmpty) {
          body = const Text('No staff accounts in your scope.');
        } else {
          body = _table(snap.data!);
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(heading, style: text.headlineSmall),
            const SizedBox(height: 16),
            body,
          ],
        );
      },
    );
  }

  Widget _table(List<StaffMember> rows) {
    final date = DateFormat.yMMMd();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Work email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Branch')),
            DataColumn(label: Text('Team')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Since')),
          ],
          rows: [
            for (final s in rows)
              DataRow(
                cells: [
                  DataCell(Text(s.displayName.isEmpty ? '—' : s.displayName)),
                  DataCell(Text(s.workEmail ?? '—')),
                  DataCell(Text(roleLabel(s.role))),
                  DataCell(Text(s.branchName ?? '—')),
                  DataCell(Text(s.teamName ?? '—')),
                  DataCell(Text(s.status == 'active' ? 'Active' : 'Disabled')),
                  DataCell(Text(date.format(s.createdAt.toLocal()))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
