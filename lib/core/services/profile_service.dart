import '../../shared/models/profile.dart';

abstract class ProfileService {
  Future<Profile?> getMyProfile();
  Future<Profile?> getProfileById(String userId);
  Future<Map<String, Profile>> getProfilesByIds(List<String> userIds);
  // Lookups by profile_id (matrimonial_profiles.id)
  Future<Profile?> getProfileByProfileId(String profileId);
  Future<Map<String, Profile>> getProfilesByProfileIds(List<String> profileIds);
  Future<void> upsertProfile(Profile profile);
  Future<void> updateContactInfo(String userId, String phone, String email);
}
