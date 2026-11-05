import '../models.dart';

/// Console data, always read and written as the signed-in user so the
/// database's access rules apply. Implemented per provider in lib/data/.
abstract interface class ConsoleData {
  /// The signed-in user's active staff account, or null if they are not
  /// staff. Works before MFA; permissions are empty until the session is aal2.
  Future<StaffProfile?> loadStaffProfile();

  /// Staff accounts in the signed-in user's scope (scoped by the database).
  /// The view is written to the audit log first.
  Future<List<StaffMember>> listStaff();

  Future<RoleMatrix> loadRoleMatrix();

  Future<void> setGrant({
    required String role,
    required String permission,
    required bool granted,
  });

  /// Every app setting (needs platform.settings).
  Future<List<AppSetting>> listSettings();

  /// Changes one setting's value; the database audits the change.
  Future<void> updateSetting(String key, Object? value);
}
