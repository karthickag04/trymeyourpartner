import 'dart:async';

import 'package:tmyp_admin_console/src/backend/console_backend.dart';
import 'package:tmyp_admin_console/src/models.dart';

/// In-memory [ConsoleBackend]: no network.
class FakeBackend implements ConsoleBackend {
  FakeBackend({
    this.staff,
    this.signedIn = false,
    this.sessionVerified = false,
    this.verifiedFactorId,
    this.staffList = const [],
  });

  /// The account's staff profile once MFA is done; null for a member.
  final StaffProfile? staff;
  bool signedIn;
  bool sessionVerified;
  String? verifiedFactorId;
  final List<StaffMember> staffList;
  final grants = <String>{};
  int signOutCalls = 0;
  String? verifiedCode;

  final _signedOut = StreamController<void>.broadcast();

  @override
  bool get hasSession => signedIn;

  @override
  String? get email => signedIn ? 'someone@example.com' : null;

  @override
  Stream<void> get signedOut => _signedOut.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signedIn = true;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    signedIn = false;
    sessionVerified = false;
  }

  @override
  Future<StaffProfile?> loadStaffProfile() async {
    final s = staff;
    if (s == null) return null;
    return StaffProfile(
      userId: s.userId,
      role: s.role,
      displayName: s.displayName,
      branchId: s.branchId,
      branchName: s.branchName,
      teamId: s.teamId,
      teamName: s.teamName,
      mfaVerified: sessionVerified,
      permissions: sessionVerified ? s.permissions : const {},
    );
  }

  @override
  Future<MfaStatus> mfaStatus() async => MfaStatus(
    sessionVerified: sessionVerified,
    verifiedFactorId: verifiedFactorId,
  );

  @override
  Future<TotpEnrolment> enrolTotp() async => const TotpEnrolment(
    factorId: 'new-factor',
    secret: 'JBSWY3DPEHPK3PXP',
    uri: 'otpauth://totp/TryMeYourPartner:someone?secret=JBSWY3DPEHPK3PXP',
  );

  @override
  Future<void> verifyTotp({
    required String factorId,
    required String code,
  }) async {
    verifiedCode = code;
    sessionVerified = true;
    verifiedFactorId = factorId;
  }

  @override
  Future<List<StaffMember>> listStaff() async => staffList;

  @override
  Future<RoleMatrix> loadRoleMatrix() async => RoleMatrix(
    permissions: const [
      Permission(
        key: 'staff.view',
        category: 'People',
        description: 'View staff accounts (in scope)',
      ),
      Permission(
        key: 'roles.manage',
        category: 'Platform',
        description: 'Define roles and permission sets',
      ),
    ],
    grants: grants,
  );

  @override
  Future<void> setGrant({
    required String role,
    required String permission,
    required bool granted,
  }) async {
    final k = RoleMatrix.grantKey(role, permission);
    granted ? grants.add(k) : grants.remove(k);
  }
}

StaffProfile staffProfile(
  String role,
  Set<String> permissions, {
  String? branchName,
}) => StaffProfile(
  userId: 'u-$role',
  role: role,
  displayName: 'Test ${roleLabel(role)}',
  branchId: branchName == null ? null : 'b-1',
  branchName: branchName,
  mfaVerified: true,
  permissions: permissions,
);
