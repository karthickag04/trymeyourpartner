import 'package:flutter/material.dart';

import 'models.dart';

/// A console section. It is shown only to staff who hold [permission]
/// (null: every MFA-verified staff member).
class ConsoleSection {
  const ConsoleSection({
    required this.path,
    required this.label,
    required this.icon,
    this.permission,
  });

  final String path;
  final String label;
  final IconData icon;
  final String? permission;
}

const consoleSections = <ConsoleSection>[
  ConsoleSection(
    path: '/dashboard',
    label: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
  ),
  ConsoleSection(
    path: '/staff',
    label: 'Staff',
    icon: Icons.badge_outlined,
    permission: 'staff.view',
  ),
  ConsoleSection(
    path: '/roles',
    label: 'Roles & permissions',
    icon: Icons.admin_panel_settings_outlined,
    permission: 'roles.view',
  ),
  ConsoleSection(
    path: '/settings',
    label: 'Settings',
    icon: Icons.tune,
    permission: 'platform.settings',
  ),
];

/// The sections the signed-in staff member may open.
List<ConsoleSection> sectionsFor(StaffProfile profile) => [
  for (final s in consoleSections)
    if (s.permission == null || profile.can(s.permission!)) s,
];
