import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/settings/app_settings.dart';

/// Help & Support: contacts come from the admin-controlled settings.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final items = <(IconData, String, String)>[
      if (s.supportEmail.isNotEmpty)
        (Icons.email_outlined, 'Email', s.supportEmail),
      if (s.supportPhone.isNotEmpty)
        (Icons.phone_outlined, 'Phone', s.supportPhone),
      if (s.supportWhatsapp.isNotEmpty)
        (Icons.chat_outlined, 'WhatsApp', s.supportWhatsapp),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: RefreshIndicator(
        onRefresh: s.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Need help with your account, a profile or a payment? Contact our support team.',
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('Support contacts are not available right now.'),
            for (final (icon, label, value) in items)
              Card(
                child: ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  subtitle: SelectableText(value),
                  trailing: IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$label copied')));
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
