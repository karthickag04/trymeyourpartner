import '../models.dart';

/// Sign-in and MFA. Implemented per provider in lib/data/ (today Supabase);
/// nothing outside lib/data/ depends on the provider.
abstract interface class ConsoleAuth {
  /// True when a signed-in session exists (for example after a reload).
  bool get hasSession;

  /// Email of the signed-in user.
  String? get email;

  /// Fires when the session ends outside the console's control (expiry,
  /// sign-out in another tab).
  Stream<void> get signedOut;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<MfaStatus> mfaStatus();

  /// Starts TOTP enrolment (removes any earlier unfinished enrolment).
  Future<TotpEnrolment> enrolTotp();

  /// Checks a TOTP code; on success the session becomes MFA-verified (aal2).
  Future<void> verifyTotp({required String factorId, required String code});
}
