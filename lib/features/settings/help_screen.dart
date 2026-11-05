import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/settings/app_settings.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';

/// Help & Support: contacts come from the admin-controlled settings.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final l = context.l10n;
    final items = <(IconData, String, String)>[
      if (s.supportEmail.isNotEmpty)
        (Icons.email_outlined, l.helpEmail, s.supportEmail),
      if (s.supportPhone.isNotEmpty)
        (Icons.phone_outlined, l.helpPhone, s.supportPhone),
      if (s.supportWhatsapp.isNotEmpty)
        (Icons.chat_outlined, l.helpWhatsapp, s.supportWhatsapp),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: RefreshIndicator(
        onRefresh: s.refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            Text(l.helpIntro),
            const SizedBox(height: AppDimensions.paddingM),
            if (items.isEmpty)
              Text(l.helpNoContacts),
            for (final (icon, label, value) in items)
              Card(
                child: ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  subtitle: SelectableText(value),
                  trailing: IconButton(
                    tooltip: l.helpCopy,
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l.helpCopied(label))));
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
