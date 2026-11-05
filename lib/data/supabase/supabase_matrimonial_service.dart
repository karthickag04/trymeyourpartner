import '../../core/services/matrimonial_domain_service.dart';
import '../../models/matrimonial_user.dart';
import '../../models/location_data.dart';
import '../../models/caste_data.dart' as caste_model;
import '../../services/matrimonial_service.dart' as legacy;

class SupabaseMatrimonialDomainService implements MatrimonialDomainService {
  @override
  Future<void> initialize() => legacy.MatrimonialService.initialize();

  @override
  Future<List<caste_model.CasteData>> getCastesByReligion(String religion) =>
      legacy.MatrimonialService.getCastesByReligion(religion);

  @override
  Future<List<LocationData>> getDistrictsByState(String stateId) =>
      legacy.MatrimonialService.getDistrictsByState(stateId);

  @override
  Future<List<String>> getEducations() =>
      legacy.MatrimonialService.getEducations();

  @override
  Future<List<String>> getOccupations() =>
      legacy.MatrimonialService.getOccupations();

  @override
  Future<List<LocationData>> getStates() =>
      legacy.MatrimonialService.getStates();

  @override
  Future<List<MatrimonialUser>> getAcceptedConnections(String userId) =>
      legacy.MatrimonialService.getAcceptedConnections(userId);

  @override
  Future<MatrimonialUser?> getCurrentUserProfile(String authUserId) =>
      legacy.MatrimonialService.getCurrentUserProfile(authUserId);

  @override
  Future<List<MatrimonialUser>> getMatches(String userId) =>
      legacy.MatrimonialService.getMatches(userId);

  @override
  Future<List<MatrimonialUser>> getNewThisWeekProfiles(String userId) =>
      legacy.MatrimonialService.getNewThisWeekProfiles(userId);

  @override
  Future<List<MatrimonialUser>> getProfilesByGenderAndCaste(
    String gender,
    String caste,
  ) => legacy.MatrimonialService.getProfilesByGenderAndCaste(gender, caste);

  @override
  Future<List<MatrimonialUser>> getReceivedInterests(String userId) =>
      legacy.MatrimonialService.getReceivedInterests(userId);

  @override
  Future<List<MatrimonialUser>> getSentInterests(String userId) =>
      legacy.MatrimonialService.getSentInterests(userId);

  @override
  Future<List<MatrimonialUser>> getShortlistedProfiles(String userId) =>
      legacy.MatrimonialService.getShortlistedProfiles(userId);

  @override
  Future<List<MatrimonialUser>> getProfilesWhoShortlistedMe(String userId) =>
      legacy.MatrimonialService.getProfilesWhoShortlistedMe(userId);

  @override
  Future<List<MatrimonialUser>> getSimilarToShortlisted(String userId) =>
      legacy.MatrimonialService.getSimilarToShortlisted(userId);

  @override
  Future<List<MatrimonialUser>> getViewersOfMe(String userId) =>
      legacy.MatrimonialService.getViewersOfMe(userId);

  @override
  Future<List<MatrimonialUser>> getViewedProfiles(String userId) =>
      legacy.MatrimonialService.getViewedProfiles(userId);

  @override
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
  }) => legacy.MatrimonialService.searchProfiles(
    state: state,
    district: district,
    caste: caste,
    castes: castes,
    subCaste: subCaste,
    city: city,
    minAge: minAge,
    maxAge: maxAge,
    education: education,
    occupation: occupation,
    educations: educations,
    occupations: occupations,
    maritalStatuses: maritalStatuses,
    languages: languages,
    minHeight: minHeight,
    maxHeight: maxHeight,
    minIncome: minIncome,
    maxIncome: maxIncome,
    joinedWithinDays: joinedWithinDays,
    onlineNow: onlineNow,
    recentlyActive: recentlyActive,
    sortBy: sortBy,
    page: page,
    pageSize: pageSize,
  );

  @override
  Future<void> blockProfile(String profileId, String reason) =>
      legacy.MatrimonialService.blockProfile(profileId, reason);

  @override
  Future<void> saveProfile(
    MatrimonialUser profile, {
    bool saveContact = false,
    bool saveFamily = false,
    bool savePartner = false,
  }) => legacy.MatrimonialService.saveProfile(
    profile,
    saveContact: saveContact,
    saveFamily: saveFamily,
    savePartner: savePartner,
  );

  @override
  Future<void> sendInterest(String toProfileId) =>
      legacy.MatrimonialService.sendInterest(toProfileId);

  @override
  Future<void> toggleShortlist(String profileId) =>
      legacy.MatrimonialService.toggleShortlist(profileId);

  @override
  Future<void> updateInterestStatus({
    required String fromProfileId,
    required String toProfileId,
    required String status,
  }) => legacy.MatrimonialService.updateInterestStatus(
    fromProfileId: fromProfileId,
    toProfileId: toProfileId,
    status: status,
  );

  @override
  Future<void> viewProfile(String profileId) =>
      legacy.MatrimonialService.viewProfile(profileId);

  // ---- Activity ----
  @override
  Future<bool?> isProfileActive(String profileId) async {
    try {
      return await legacy.MatrimonialService.isProfileActive(profileId);
    } catch (_) {
      return null;
    }
  }
}
