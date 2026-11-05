import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';

/// Shows a maintenance screen instead of the app while an admin has
/// maintenance mode switched on.
class MaintenanceGate extends StatelessWidget {
  final Widget child;
  const MaintenanceGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    if (!settings.maintenanceEnabled) return child;
    final message = settings.maintenanceMessage.isNotEmpty
        ? settings.maintenanceMessage
        : 'We are making improvements. Please check back soon.';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_circle_outlined, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Under maintenance',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: settings.refresh,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
