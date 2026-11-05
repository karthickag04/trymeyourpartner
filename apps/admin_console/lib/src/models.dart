/// Staff roles, highest first (see docs/ADMIN_CONSOLE.md).
const staffRoles = <String>[
  'system_admin',
  'super_admin',
  'admin',
  'branch_manager',
  'team_lead',
  'staff',
  'agent',
];

const _roleLabels = <String, String>{
  'system_admin': 'System admin',
  'super_admin': 'Super admin',
  'admin': 'Admin',
  'branch_manager': 'Branch manager',
  'team_lead': 'Team lead',
  'staff': 'Staff',
  'agent': 'Agent',
};

String roleLabel(String role) => _roleLabels[role] ?? role;

/// The signed-in staff member, from `public.current_staff_profile()`.
class StaffProfile {
  const StaffProfile({
    required this.userId,
    required this.role,
    required this.displayName,
    required this.mfaVerified,
    required this.permissions,
    this.branchId,
    this.branchName,
    this.teamId,
    this.teamName,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) => StaffProfile(
    userId: json['user_id'] as String,
    role: json['role'] as String,
    displayName: (json['display_name'] as String?) ?? '',
    branchId: json['branch_id'] as String?,
    branchName: json['branch_name'] as String?,
    teamId: json['team_id'] as String?,
    teamName: json['team_name'] as String?,
    mfaVerified: json['mfa_verified'] == true,
    permissions: Set.unmodifiable(
      ((json['permissions'] as List?) ?? const []).cast<String>(),
    ),
  );

  final String userId;
  final String role;
  final String displayName;
  final String? branchId;
  final String? branchName;
  final String? teamId;
  final String? teamName;

  /// True when the current session passed MFA (aal2).
  final bool mfaVerified;

  /// Empty until the session is MFA-verified.
  final Set<String> permissions;

  bool can(String permission) =>
      mfaVerified &&
      (role == 'system_admin' || permissions.contains(permission));
}

/// A row of the staff list.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.displayName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.workEmail,
    this.branchName,
    this.teamName,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    displayName: (json['display_name'] as String?) ?? '',
    workEmail: json['work_email'] as String?,
    role: json['role'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    branchName: (json['branch'] as Map?)?['name'] as String?,
    teamName: (json['team'] as Map?)?['name'] as String?,
  );

  final String id;
  final String displayName;
  final String? workEmail;
  final String role;
  final String status;
  final DateTime createdAt;
  final String? branchName;
  final String? teamName;
}

/// An entry of the permission catalog (`public.permissions`).
class Permission {
  const Permission({
    required this.key,
    required this.category,
    required this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
    key: json['key'] as String,
    category: json['category'] as String,
    description: json['description'] as String,
  );

  final String key;
  final String category;
  final String description;
}

/// The role/permission matrix (`public.role_permissions`).
class RoleMatrix {
  RoleMatrix({required this.permissions, required Set<String> grants})
    : _grants = {...grants};

  static String grantKey(String role, String permission) => '$role|$permission';

  final List<Permission> permissions;
  final Set<String> _grants;

  /// system_admin always holds every permission.
  bool has(String role, String permission) =>
      role == 'system_admin' || _grants.contains(grantKey(role, permission));

  void set(String role, String permission, bool granted) {
    final key = grantKey(role, permission);
    granted ? _grants.add(key) : _grants.remove(key);
  }
}

/// A new TOTP factor waiting for its first code.
class TotpEnrolment {
  const TotpEnrolment({
    required this.factorId,
    required this.secret,
    required this.uri,
  });

  final String factorId;

  /// Setup key to type into an authenticator app.
  final String secret;

  /// otpauth:// link with the same key.
  final String uri;
}

/// MFA state of the current session.
class MfaStatus {
  const MfaStatus({required this.sessionVerified, this.verifiedFactorId});

  /// The session is already aal2.
  final bool sessionVerified;

  /// A verified TOTP factor, if the user has enrolled one.
  final String? verifiedFactorId;
}
