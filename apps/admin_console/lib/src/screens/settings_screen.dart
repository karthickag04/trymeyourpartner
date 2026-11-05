import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../session/session_controller.dart';

/// Admin-controlled app settings (`app_settings`): maintenance mode, support
/// contacts, feature switches, plan limits. Needs platform.settings
/// (system_admin). Every change is recorded in the audit log by the database.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<List<AppSetting>> _settings = _load();

  Future<List<AppSetting>> _load() =>
      context.read<SessionController>().data.listSettings();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FutureBuilder<List<AppSetting>>(
      future: _settings,
      builder: (context, snap) {
        final List<Widget> body;
        if (snap.connectionState != ConnectionState.done) {
          body = const [Center(child: CircularProgressIndicator())];
        } else if (snap.hasError) {
          body = [
            Text(describeError(snap.error!)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => setState(() => _settings = _load()),
                child: const Text('Try again'),
              ),
            ),
          ];
        } else if (snap.data!.isEmpty) {
          body = const [Text('No settings found.')];
        } else {
          body = [
            for (final s in snap.data!)
              _SettingCard(key: ValueKey(s.key), setting: s),
          ];
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Settings', style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Values are JSON. Changes apply to the apps on their next start '
              'and are recorded in the audit log.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...body,
          ],
        );
      },
    );
  }
}

class _SettingCard extends StatefulWidget {
  const _SettingCard({super.key, required this.setting});

  final AppSetting setting;

  @override
  State<_SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<_SettingCard> {
  static const _pretty = JsonEncoder.withIndent('  ');

  late String _saved = _pretty.convert(widget.setting.value);
  late final _value = TextEditingController(text: _saved);
  late DateTime? _updatedAt = widget.setting.updatedAt;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value.addListener(_validate);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _validate() {
    String? error;
    try {
      jsonDecode(_value.text);
    } on FormatException {
      error = 'Not valid JSON';
    }
    // Rebuild on every edit so Save/Undo follow the text.
    if (mounted) setState(() => _error = error);
  }

  bool get _changed => _value.text != _saved;

  Future<void> _save() async {
    final key = widget.setting.key;
    final value = jsonDecode(_value.text);
    setState(() => _saving = true);
    try {
      await context.read<SessionController>().data.updateSetting(key, value);
      if (!mounted) return;
      setState(() {
        _saved = _pretty.convert(value);
        _value.text = _saved;
        _updatedAt = DateTime.now();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved $key')));
    } catch (e) {
      if (mounted) setState(() => _error = 'Not saved: ${describeError(e)}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.setting;
    final text = Theme.of(context).textTheme;
    final updated = _updatedAt == null
        ? ''
        : ' · updated ${DateFormat.yMMMd().add_jm().format(_updatedAt!.toLocal())}';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.key, style: text.titleMedium),
            if (s.description.isNotEmpty) Text(s.description),
            Text(
              '${s.isPublic ? 'Readable before sign-in' : 'Staff only'}$updated',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: Key('setting-${s.key}'),
              controller: _value,
              maxLines: null,
              minLines: 1,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(errorText: _error),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  key: Key('save-${s.key}'),
                  onPressed: _changed && !_saving && _error == null
                      ? _save
                      : null,
                  child: const Text('Save'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _changed && !_saving
                      ? () => _value.text = _saved
                      : null,
                  child: const Text('Undo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
