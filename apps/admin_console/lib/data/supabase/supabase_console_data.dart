import 'package:supabase_flutter/supabase_flutter.dart';

import '../../src/models.dart';
import '../../src/services/console_data.dart';
import '../../src/services/console_exception.dart';
import 'errors.dart';

/// [ConsoleData] on Supabase, always as the signed-in user with the
/// publishable key: row-level security decides what each role can see.
class SupabaseConsoleData implements ConsoleData {
  SupabaseConsoleData(this._client);

  final SupabaseClient _client;

  @override
  Future<StaffProfile?> loadStaffProfile() => guard(() async {
    final result = await _client.rpc('current_staff_profile');
    if (result == null) return null;
    return StaffProfile.fromJson(Map<String, dynamic>.from(result as Map));
  });

  @override
  Future<List<StaffMember>> listStaff() => guard(() async {
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
  });

  @override
  Future<RoleMatrix> loadRoleMatrix() => guard(() async {
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
  });

  @override
  Future<void> setGrant({
    required String role,
    required String permission,
    required bool granted,
  }) => guard(() async {
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
        throw const ConsoleException('Not allowed to change this');
      }
    }
  });

  @override
  Future<List<AppSetting>> listSettings() => guard(() async {
    final rows = await _client
        .from('app_settings')
        .select('key,value,description,is_public,updated_at')
        .order('key');
    return rows.map(AppSetting.fromJson).toList();
  });

  @override
  Future<void> updateSetting(String key, Object? value) => guard(() async {
    final changed = await _client
        .from('app_settings')
        .update({'value': value})
        .eq('key', key)
        .select('key');
    // Row-level security turns a forbidden update into "0 rows".
    if (changed.isEmpty) {
      throw const ConsoleException('Not allowed to change this setting');
    }
  });
}
