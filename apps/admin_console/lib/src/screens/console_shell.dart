import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../navigation.dart';
import '../session/session_controller.dart';

/// Frame around the staff pages: navigation built from the signed-in staff
/// member's permissions, and the account menu.
class ConsoleShell extends StatelessWidget {
  const ConsoleShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = session.profile!;
    final sections = sectionsFor(profile);
    final selected = sections
        .indexWhere((s) => s.path == location)
        .clamp(0, sections.length - 1);
    void go(int i) => context.go(sections[i].path);

    final appBar = AppBar(
      title: const Text('TryMeYourPartner Admin'),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              '${profile.displayName.isEmpty ? session.email ?? '' : profile.displayName}'
              ' · ${roleLabel(profile.role)}',
            ),
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: session.signOut,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        if (wide || sections.length < 2) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                if (sections.length >= 2) ...[
                  NavigationRail(
                    key: const Key('console-nav'),
                    extended: constraints.maxWidth >= 1100,
                    labelType: constraints.maxWidth >= 1100
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    selectedIndex: selected,
                    onDestinationSelected: go,
                    destinations: [
                      for (final s in sections)
                        NavigationRailDestination(
                          icon: Icon(s.icon),
                          label: Text(s.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: appBar,
          body: child,
          bottomNavigationBar: NavigationBar(
            key: const Key('console-nav'),
            selectedIndex: selected,
            onDestinationSelected: go,
            destinations: [
              for (final s in sections)
                NavigationDestination(icon: Icon(s.icon), label: s.label),
            ],
          ),
        );
      },
    );
  }
}
