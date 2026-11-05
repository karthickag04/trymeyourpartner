import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'console_backend.dart';

/// [ConsoleBackend] on Supabase, always as the signed-in user with the
/// publishable key: row-level security decides what each role can see.
class SupabaseConsoleBackend implements ConsoleBackend {
  SupabaseConsoleBackend(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  bool get hasSession => _auth.currentSession != null;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Stream<void> get signedOut => _auth.onAuthStateChange
      .where((s) => s.event == AuthChangeEvent.signedOut)
      .map((_) {});

  @override
  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<StaffProfile?> loadStaffProfile() async {
    final result = await _client.rpc('current_staff_profile');
    if (result == null) return null;
    return StaffProfile.fromJson(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<MfaStatus> mfaStatus() async {
    final factors = await _auth.mfa.listFactors();
    final level = _auth.mfa.getAuthenticatorAssuranceLevel().currentLevel;
    return MfaStatus(
      sessionVerified: level == AuthenticatorAssuranceLevels.aal2,
      verifiedFactorId: factors.totp.isEmpty ? null : factors.totp.first.id,
    );
  }

  @override
  Future<TotpEnrolment> enrolTotp() async {
    final factors = await _auth.mfa.listFactors();
    for (final f in factors.all) {
      if (f.factorType == FactorType.totp &&
          f.status == FactorStatus.unverified) {
        await _auth.mfa.unenroll(f.id);
      }
    }
    final r = await _auth.mfa.enroll(
      factorType: FactorType.totp,
      issuer: 'TryMeYourPartner',
      friendlyName: 'Admin console',
    );
    return TotpEnrolment(
      factorId: r.id,
      secret: r.totp!.secret,
      uri: r.totp!.uri,
    );
  }

  @override
  Future<void> verifyTotp({
    required String factorId,
    required String code,
  }) async {
    await _auth.mfa.challengeAndVerify(factorId: factorId, code: code);
  }

  @override
  Future<List<StaffMember>> listStaff() async {
    final rows = await _client
        .from('staff_accounts')
        .select(
          'id,role,display_name,work_email,status,created_at,'
          'branch:branches(name),team:teams(name)',
        )
        .order('display_name');
    // Staff personal data: record the view before showing it. If the audit
    // entry cannot be written, nothing is shown.
    await _client.rpc(
      'log_audit',
      params: {
        'p_action': 'staff.list',
        'p_entity': 'staff_accounts',
        'p_after': {'via': 'admin-console', 'count': rows.length},
      },
    );
    return rows.map(StaffMember.fromJson).toList();
  }

  @override
  Future<RoleMatrix> loadRoleMatrix() async {
    final permissions = await _client
        .from('permissions')
        .select('key,category,description')
        .order('sort_order');
    final grants = await _client
        .from('role_permissions')
        .select('role,permission');
    return RoleMatrix(
      permissions: permissions.map(Permission.fromJson).toList(),
      grants: {
        for (final g in grants)
          RoleMatrix.grantKey(g['role'] as String, g['permission'] as String),
      },
    );
  }

  @override
  Future<void> setGrant({
    required String role,
    required String permission,
    required bool granted,
  }) async {
    final table = _client.from('role_permissions');
    if (granted) {
      await table.insert({'role': role, 'permission': permission});
    } else {
      final removed = await table
          .delete()
          .match({'role': role, 'permission': permission})
          .select('role');
      // Row-level security turns a forbidden delete into "0 rows".
      if (removed.isEmpty) {
        throw const PostgrestException(message: 'Not allowed to change this');
      }
    }
  }
}
