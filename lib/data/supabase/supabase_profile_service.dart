import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/profile_service.dart';
import '../../domain/models/profile.dart';

class SupabaseProfileService implements ProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Profile?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final res = await _client
        .from('matrimonial_profiles')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    return res == null ? null : Profile.fromJson(res);
  }

  @override
  Future<Profile?> getProfileById(String userId) async {
    final res = await _client
        .from('matrimonial_profiles')
        .select()
        .eq('auth_user_id', userId)
        .maybeSingle();

    return res == null ? null : Profile.fromJson(res);
  }

  @override
  Future<Map<String, Profile>> getProfilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final res = await _client
        .from('matrimonial_profiles')
        .select()
        .inFilter('auth_user_id', userIds);
    final Map<String, Profile> out = {};
    for (final row in res as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final key = (map['auth_user_id'] ?? map['user_id'] ?? map['id'])
          .toString();
      out[key] = Profile.fromJson(map);
    }
    return out;
  }

  @override
  Future<Profile?> getProfileByProfileId(String profileId) async {
    final res = await _client
        .from('matrimonial_profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();
    return res == null ? null : Profile.fromJson(res);
  }

  @override
  Future<Map<String, Profile>> getProfilesByProfileIds(
    List<String> profileIds,
  ) async {
    if (profileIds.isEmpty) return {};
    final res = await _client
        .from('matrimonial_profiles')
        .select()
        .inFilter('id', profileIds);
    final Map<String, Profile> out = {};
    for (final row in res as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final key = (map['id']).toString();
      out[key] = Profile.fromJson(map);
    }
    return out;
  }

  @override
  Future<void> upsertProfile(Profile profile) async {
    await _client.from('matrimonial_profiles').upsert({
      'auth_user_id': profile.userId,
      ...profile.toJson(),
    });
  }

  @override
  Future<void> updateContactInfo(
    String userId,
    String phone,
    String email,
  ) async {
    await _client.rpc(
      'upsert_contact_info',
      params: {
        'ci': {'phone': phone, 'email': email},
      },
    );
  }
}
