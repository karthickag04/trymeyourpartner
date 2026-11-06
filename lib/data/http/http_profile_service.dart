import 'dart:convert';
import '../../core/services/profile_service.dart';
import '../../shared/models/profile.dart';
import 'http_client.dart';

class HttpProfileService implements ProfileService {
  final ApiClient _api;
  HttpProfileService(this._api);

  @override
  Future<Profile?> getMyProfile() async {
    final data = await _api.get('/profiles/me');
    if (data == null) return null;
    if (data is Map<String, dynamic>) return Profile.fromJson(data);
    return Profile.fromJson(
      jsonDecode(jsonEncode(data)) as Map<String, dynamic>,
    );
  }

  @override
  Future<Profile?> getProfileById(String userId) async {
    final data = await _api.get('/profiles/$userId');
    if (data == null) return null;
    if (data is Map<String, dynamic>) return Profile.fromJson(data);
    return Profile.fromJson(
      jsonDecode(jsonEncode(data)) as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, Profile>> getProfilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    final idsParam = userIds.join(',');
    final body = await _api.get('/profiles', query: {'ids': idsParam});
    if (body is! List) {
      throw Exception('Unexpected response for batch profiles');
    }
    final Map<String, Profile> out = {};
    for (final item in body) {
      if (item is Map<String, dynamic>) {
        final prof = Profile.fromJson(item);
        final key = item['auth_user_id'] ?? item['user_id'] ?? item['id'];
        if (key != null) out[key.toString()] = prof;
      }
    }
    return out;
  }

  @override
  Future<Profile?> getProfileByProfileId(String profileId) async {
    final data = await _api.get('/profiles/profile/$profileId');
    if (data == null) return null;
    if (data is Map<String, dynamic>) return Profile.fromJson(data);
    return Profile.fromJson(
      jsonDecode(jsonEncode(data)) as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, Profile>> getProfilesByProfileIds(
    List<String> profileIds,
  ) async {
    if (profileIds.isEmpty) return {};
    final idsParam = profileIds.join(',');
    final body = await _api.get(
      '/profiles/by-profile-ids',
      query: {'ids': idsParam},
    );
    if (body is! List) {
      throw Exception('Unexpected response for batch profiles by profile ids');
    }
    final Map<String, Profile> out = {};
    for (final item in body) {
      if (item is Map<String, dynamic>) {
        final prof = Profile.fromJson(item);
        final key = item['id'] ?? item['profile_id'];
        if (key != null) out[key.toString()] = prof;
      }
    }
    return out;
  }

  @override
  Future<void> upsertProfile(Profile profile) async {
    await _api.put('/profiles/me', body: profile.toJson());
  }

  @override
  Future<void> updateContactInfo(
    String userId,
    String phone,
    String email,
  ) async {
    await _api.post(
      '/profiles/$userId/contact',
      body: {'phone': phone, 'email': email},
    );
  }
}
