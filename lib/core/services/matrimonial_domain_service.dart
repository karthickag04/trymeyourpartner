import '../../models/matrimonial_user.dart';
import '../../models/location_data.dart';
import '../../models/caste_data.dart' as caste_model;

abstract class MatrimonialDomainService {
  Future<void> initialize();

  // Lookups
  Future<List<LocationData>> getStates();
  Future<List<LocationData>> getDistrictsByState(String stateId);
  Future<List<caste_model.CasteData>> getCastesByReligion(String religion);
  Future<List<String>> getEducations();
  Future<List<String>> getOccupations();

  // Profile
  Future<MatrimonialUser?> getCurrentUserProfile(String authUserId);
  Future<void> saveProfile(
    MatrimonialUser profile, {
    bool saveContact = false,
    bool saveFamily = false,
    bool savePartner = false,
  });

  // Lists
  Future<List<MatrimonialUser>> getMatches(String userId);
  Future<List<MatrimonialUser>> getReceivedInterests(String userId);
  Future<List<MatrimonialUser>> getSentInterests(String userId);
  Future<List<MatrimonialUser>> getShortlistedProfiles(String userId);
  Future<List<MatrimonialUser>> getProfilesWhoShortlistedMe(String userId);
  Future<List<MatrimonialUser>> getViewedProfiles(String userId);
  Future<List<MatrimonialUser>> getViewersOfMe(String userId);
  Future<List<MatrimonialUser>> getAcceptedConnections(String userId);
  Future<List<MatrimonialUser>> getNewThisWeekProfiles(String userId);
  Future<List<MatrimonialUser>> getSimilarToShortlisted(String userId);

  // Search
  Future<List<MatrimonialUser>> searchProfiles({
    String? state,
    String? district,
    String? caste,
    List<String>? castes,
    String? subCaste,
    String? city,
    int? minAge,
    int? maxAge,
    String? education,
    String? occupation,
    List<String>? educations,
    List<String>? occupations,
    List<String>? maritalStatuses,
    List<String>? languages,
    int? minHeight,
    int? maxHeight,
    double? minIncome,
    double? maxIncome,
    int? joinedWithinDays,
    bool onlineNow = false,
    bool recentlyActive = false,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  });

  // Actions
  Future<void> sendInterest(String toProfileId);
  Future<void> updateInterestStatus({
    required String fromProfileId,
    required String toProfileId,
    required String status,
  });
  Future<void> toggleShortlist(String profileId);
  Future<void> viewProfile(String profileId);
  Future<void> blockProfile(String profileId, String reason);

  // Misc
  Future<List<MatrimonialUser>> getProfilesByGenderAndCaste(
    String gender,
    String caste,
  );

  // Activity state
  /// Returns true if the given profile is active, false if deactivated, or null if unknown/not supported by backend.
  Future<bool?> isProfileActive(String profileId);
}
