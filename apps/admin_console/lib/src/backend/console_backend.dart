import '../models.dart';

/// Everything the console needs from Supabase. Screens and the session
/// controller depend on this interface only, so tests can use a fake.
abstract interface class ConsoleBackend {
  /// True when a signed-in session exists (for example after a reload).
  bool get hasSession;

  /// Email of the signed-in user.
  String? get email;

  /// Fires when the session ends outside the console's control (expiry,
  /// sign-out in another tab).
  Stream<void> get signedOut;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// The signed-in user's active staff account, or null if they are not
  /// staff. Works before MFA; permissions are empty until the session is aal2.
  Future<StaffProfile?> loadStaffProfile();

  Future<MfaStatus> mfaStatus();

  /// Starts TOTP enrolment (removes any earlier unfinished enrolment).
  Future<TotpEnrolment> enrolTotp();

  /// Checks a TOTP code; on success the session becomes aal2.
  Future<void> verifyTotp({required String factorId, required String code});

  /// Staff accounts in the signed-in user's scope (scoped by the database).
  Future<List<StaffMember>> listStaff();

  Future<RoleMatrix> loadRoleMatrix();

  Future<void> setGrant({
    required String role,
    required String permission,
    required bool granted,
  });
}
