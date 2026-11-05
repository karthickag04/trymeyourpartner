import '../../core/services/matrimonial_domain_service.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/models/location_data.dart';
import '../../shared/models/caste_data.dart' as caste_model;
import 'http_client.dart';

class HttpMatrimonialDomainService implements MatrimonialDomainService {
  final ApiClient api;
  HttpMatrimonialDomainService(this.api);

  @override
  Future<void> initialize() async {}

  // ---- Helpers ----
  List<MatrimonialUser> _usersFrom(dynamic data) {
    final list = (data is Map && data['items'] is List)
        ? data['items'] as List
        : (data is List ? data : const []);
    return list
        .whereType<Map>()
        .map(
          (e) => MatrimonialUser.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList();
  }

  List<LocationData> _locationsFrom(dynamic data) {
    final list = (data is Map && data['items'] is List)
        ? data['items'] as List
        : (data is List ? data : const []);
    return list
        .whereType<Map>()
        .map(
          (e) =>
              LocationData.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();
  }

  List<caste_model.CasteData> _castesFrom(dynamic data) {
    final list = (data is Map && data['items'] is List)
        ? data['items'] as List
        : (data is List ? data : const []);
    return list
        .whereType<Map>()
        .map(
          (e) => caste_model.CasteData.fromJson(
            e.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList();
  }

  List<String> _stringList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  // ---- Lookups ----
  @override
  Future<List<LocationData>> getStates() async {
    final data = await api.get('/lookups/states');
    return _locationsFrom(data);
  }

  @override
  Future<List<LocationData>> getDistrictsByState(String stateId) async {
    final data = await api.get('/lookups/states/$stateId/districts');
    return _locationsFrom(data);
  }

  @override
  Future<List<caste_model.CasteData>> getCastesByReligion(
    String religion,
  ) async {
    final data = await api.get('/lookups/religions/$religion/castes');
    return _castesFrom(data);
  }

  @override
  Future<List<String>> getEducations() async {
    final data = await api.get('/lookups/educations');
    return _stringList(data);
  }

  @override
  Future<List<String>> getOccupations() async {
    final data = await api.get('/lookups/occupations');
    return _stringList(data);
  }

  // ---- Profile ----
  @override
  Future<MatrimonialUser?> getCurrentUserProfile(String authUserId) async {
    // Prefer /profiles/me; fall back to /profiles/by-auth/{id}
    try {
      final data = await api.get('/profiles/me');
      if (data is Map) {
        return MatrimonialUser.fromJson(
          data.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {
      // ignore and try fallback
    }
    try {
      final data = await api.get('/profiles/by-auth/$authUserId');
      if (data is Map) {
        return MatrimonialUser.fromJson(
          data.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveProfile(
    MatrimonialUser profile, {
    bool saveContact = false,
    bool saveFamily = false,
    bool savePartner = false,
  }) async {
    await api.put(
      '/profiles/me',
      body: {
        'profile': profile.toJson(),
        'save_contact': saveContact,
        'save_family': saveFamily,
        'save_partner': savePartner,
      },
    );
  }

  // ---- Lists ----
  @override
  Future<List<MatrimonialUser>> getMatches(String userId) async {
    final data = await api.get('/matches/suggestions');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getReceivedInterests(String userId) async {
    final data = await api.get('/interests/received');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getSentInterests(String userId) async {
    final data = await api.get('/interests/sent');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getShortlistedProfiles(String userId) async {
    final data = await api.get('/shortlist');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getProfilesWhoShortlistedMe(
    String userId,
  ) async {
    final data = await api.get('/shortlist/of-me');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getViewedProfiles(String userId) async {
    final data = await api.get('/views/mine');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getViewersOfMe(String userId) async {
    final data = await api.get('/views/of-me');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getAcceptedConnections(String userId) async {
    final data = await api.get('/matches/mutual');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getNewThisWeekProfiles(String userId) async {
    final data = await api.get('/profiles/new');
    return _usersFrom(data);
  }

  @override
  Future<List<MatrimonialUser>> getSimilarToShortlisted(String userId) async {
    final data = await api.get('/profiles/similar');
    return _usersFrom(data);
  }

  // ---- Search ----
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
  }) async {
    final query = <String, dynamic>{
      if (state != null && state.isNotEmpty) 'state': state,
      if (district != null && district.isNotEmpty) 'district': district,
      if (caste != null && caste.isNotEmpty) 'caste': caste,
      if (subCaste != null && subCaste.isNotEmpty) 'sub_caste': subCaste,
      if (city != null && city.isNotEmpty) 'city': city,
      if (minAge != null) 'min_age': minAge,
      if (maxAge != null) 'max_age': maxAge,
      if (education != null && education.isNotEmpty) 'education': education,
      if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
      if (minHeight != null) 'min_height_cm': minHeight,
      if (maxHeight != null) 'max_height_cm': maxHeight,
      if (minIncome != null) 'min_income': minIncome,
      if (maxIncome != null) 'max_income': maxIncome,
      if (joinedWithinDays != null) 'joined_within_days': joinedWithinDays,
      if (onlineNow) 'online_now': true,
      if (recentlyActive) 'recently_active': true,
      if (sortBy != null && sortBy.isNotEmpty) 'sort': sortBy,
      'page': page,
      'page_size': pageSize,
    };
    // Multi-select lists as repeated query params or CSV
    if (castes != null && castes.isNotEmpty) {
      query['castes'] = castes.join(',');
    }
    if (educations != null && educations.isNotEmpty) {
      query['educations'] = educations.join(',');
    }
    if (occupations != null && occupations.isNotEmpty) {
      query['occupations'] = occupations.join(',');
    }
    if (maritalStatuses != null && maritalStatuses.isNotEmpty) {
      query['marital_statuses'] = maritalStatuses.join(',');
    }
    if (languages != null && languages.isNotEmpty) {
      query['languages'] = languages.join(',');
    }

    final data = await api.get('/profiles/search', query: query);
    return _usersFrom(data);
  }

  // ---- Actions ----
  @override
  Future<void> sendInterest(String toProfileId) async {
    await api.post('/interests/send', body: {'to_profile_id': toProfileId});
  }

  @override
  Future<void> updateInterestStatus({
    required String fromProfileId,
    required String toProfileId,
    required String status,
  }) async {
    await api.post(
      '/interests/update',
      body: {
        'from_profile_id': fromProfileId,
        'to_profile_id': toProfileId,
        'status': status,
      },
    );
  }

  @override
  Future<void> toggleShortlist(String profileId) async {
    await api.post('/shortlist/toggle', body: {'profile_id': profileId});
  }

  @override
  Future<void> viewProfile(String profileId) async {
    await api.post('/views', body: {'profile_id': profileId});
  }

  @override
  Future<void> blockProfile(String profileId, String reason) async {
    await api.post(
      '/blocks',
      body: {'profile_id': profileId, 'reason': reason},
    );
  }

  // ---- Misc ----
  @override
  Future<List<MatrimonialUser>> getProfilesByGenderAndCaste(
    String gender,
    String caste,
  ) async {
    final data = await api.get(
      '/profiles',
      query: {'gender': gender, 'caste': caste},
    );
    return _usersFrom(data);
  }

  // ---- Activity ----
  @override
  Future<bool?> isProfileActive(String profileId) async {
    // Option A: If your API exposes a lightweight endpoint, use it, e.g. /profiles/{id}/active
    // final res = await api.get('/profiles/$profileId/active');
    // if (res is bool) return res;
    // if (res is Map && res['active'] is bool) return res['active'] as bool;

    // Fallback: If not supported, return null (unknown). UI treats null as active to avoid false blocks.
    return null;
  }
}
