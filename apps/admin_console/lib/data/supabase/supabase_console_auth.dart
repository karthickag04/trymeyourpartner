import 'package:supabase_flutter/supabase_flutter.dart';

import '../../src/models.dart';
import '../../src/services/console_auth.dart';
import 'errors.dart';

/// [ConsoleAuth] on Supabase Auth (password + TOTP MFA).
class SupabaseConsoleAuth implements ConsoleAuth {
  SupabaseConsoleAuth(SupabaseClient client) : _auth = client.auth;

  final GoTrueClient _auth;

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
      guard(() => _auth.signInWithPassword(email: email, password: password));

  @override
  Future<void> signOut() => guard(() => _auth.signOut());

  @override
  Future<MfaStatus> mfaStatus() => guard(() async {
    final factors = await _auth.mfa.listFactors();
    final level = _auth.mfa.getAuthenticatorAssuranceLevel().currentLevel;
    return MfaStatus(
      sessionVerified: level == AuthenticatorAssuranceLevels.aal2,
      verifiedFactorId: factors.totp.isEmpty ? null : factors.totp.first.id,
    );
  });

  @override
  Future<TotpEnrolment> enrolTotp() => guard(() async {
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
  });

  @override
  Future<void> verifyTotp({required String factorId, required String code}) =>
      guard(() => _auth.mfa.challengeAndVerify(factorId: factorId, code: code));
}
