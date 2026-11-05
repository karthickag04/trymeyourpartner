import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/matrimonial_user.dart';
import '../models/location_data.dart';
import '../models/caste_data.dart' as models;

class MatrimonialService {
  // Lazily access the Supabase client to avoid early initialization issues
  static SupabaseClient get _supabase => Supabase.instance.client;
  static bool _initialized = false;
  static final Map<String, String> _stateIdCache = {};
  static final Map<String, String> _districtIdCache =
      {}; // key: "state|district"
  static final Map<String, String> _casteIdCache = {}; // key: "religion|caste"

  // Initialize service
  static Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('🚀 Initializing MatrimonialService...');
    _initialized = true;
  }

  // Registration helpers
  static Future<List<String>> getOccupationCategories() async {
    await initialize();
    try {
      final rows = await _supabase
          .from('occupation_categories')
          .select('name')
          .order('name');
      return rows
          .map((e) => (e['name'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<String>> getQualificationTypes() async {
    await initialize();
    try {
      final rows = await _supabase
          .from('qualification_types')
          .select('name')
          .order('name');
      return rows
          .map((e) => (e['name'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String?> _resolveQualificationTypeIdByName(String name) async {
    try {
      final row = await _supabase
          .from('qualification_types')
          .select('id')
          .eq('name', name)
          .maybeSingle();
      return row == null ? null : row['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setProfileQualifications(
    String profileId,
    List<Map<String, String>> entries, // [{type: 'UG', discipline: 'CS'}, ...]
  ) async {
    await initialize();
    try {
      // Remove existing and insert anew (idempotent for our use case)
      await _supabase
          .from('profile_qualifications')
          .delete()
          .eq('profile_id', profileId);

      if (entries.isEmpty) return;

      final payload = <Map<String, dynamic>>[];
      for (final e in entries) {
        final typeName = (e['type'] ?? '').trim();
        if (typeName.isEmpty) continue;
        final typeId = await _resolveQualificationTypeIdByName(typeName);
        if (typeId == null) continue;
        payload.add({
          'profile_id': profileId,
          'type_id': typeId,
          'discipline': (e['discipline'] ?? '').trim(),
        });
      }
      if (payload.isNotEmpty) {
        await _supabase.from('profile_qualifications').insert(payload);
      }
    } catch (_) {}
  }

  static Future<void> updateRegistrationExtras(
    String profileId, {
    String? createdBy,
    String? workStatus,
  }) async {
    await initialize();
    final data = <String, dynamic>{};
    if (createdBy != null && createdBy.isNotEmpty) {
      data['created_by'] = createdBy;
    }
    if (workStatus != null && workStatus.isNotEmpty) {
      data['work_status'] = workStatus;
    }
    if (data.isEmpty) return;
    data['updated_at'] = DateTime.now().toIso8601String();
    try {
      await _supabase
          .from('matrimonial_profiles')
          .update(data)
          .eq('id', profileId);
    } catch (_) {}
  }

  // Get current user's matrimonial profile (without auto-assignment)
  static Future<MatrimonialUser?> getCurrentUserProfile(
    String authUserId,
  ) async {
    await initialize();
    try {
      final data = await _supabase
          .from('matrimonial_profiles')
          .select(
            '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
          )
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (data == null) return null;
      try {
        debugPrint(
          '🔎 getCurrentUserProfile: profile_image_url=${data['profile_image_url']} photo_urls=${data['photo_urls']}',
        );
      } catch (_) {}
      return MatrimonialUser.fromJson(_normalizeProfileRow(data));
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  // Lightweight helpers for activity checks
  static Future<bool?> isProfileActive(String profileId) async {
    try {
      final row = await _supabase
          .from('matrimonial_profiles')
          .select('is_active')
          .eq('id', profileId)
          .maybeSingle();
      if (row == null) return null;
      return row['is_active'] == true;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> myProfileId() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return null;
      final row = await _supabase
          .from('matrimonial_profiles')
          .select('id')
          .eq('auth_user_id', uid)
          .maybeSingle();
      return row?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Get matched profiles for a user
  static Future<List<MatrimonialUser>> getMatches(String userId) async {
    await initialize();
    // quiet: avoid noisy logs in normal flow

    try {
      // Get current user profile first
      final currentProfile = await getCurrentUserProfile(userId);

      if (currentProfile == null) {
        // User has no profile, show browsing mode with active profiles
        final browseProfiles = await _supabase
            .from('matrimonial_profiles')
            .select(
              '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
            )
            .eq('is_active', true)
            .order('last_active_at', ascending: false)
            .limit(20);

        return browseProfiles
            .map<MatrimonialUser>(
              (json) => MatrimonialUser.fromJson(_normalizeProfileRow(json)),
            )
            .toList();
      }

      // User has profile, find matches based on preferences
      final cg = (currentProfile.gender).trim();
      final oppositeGender = cg == 'Male'
          ? 'Female'
          : cg == 'Female'
          ? 'Male'
          : null;

      var matchQuery = _supabase
          .from('matrimonial_profiles')
          .select(
            '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
          )
          .eq('is_active', true)
          .neq('auth_user_id', userId);
      if (oppositeGender != null) {
        matchQuery = matchQuery.eq('gender', oppositeGender);
      }
      final matchProfiles = await matchQuery
          .order('last_active_at', ascending: false)
          .limit(20);

      return matchProfiles
          .map<MatrimonialUser>(
            (json) => MatrimonialUser.fromJson(_normalizeProfileRow(json)),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting matches: $e');
      return [];
    }
  }

  // Search profiles with filters
  static Future<List<MatrimonialUser>> searchProfiles({
    String? name,
    String? gender,
    int? minAge,
    int? maxAge,
    String? state,
    String? district,
    String? caste,
    List<String>? castes,
    String? subCaste,
    String? city,
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
    await initialize();
    // quiet: avoid log noise in normal flow

    try {
      // Optionally apply opposite gender based on current user's profile
      final currentUser = _supabase.auth.currentUser;
      MatrimonialUser? me;
      if (currentUser != null) {
        me = await getCurrentUserProfile(currentUser.id);
      }

      var query = _supabase
          .from('matrimonial_profiles')
          .select(
            '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
          )
          .eq('is_active', true);

      if (gender != null) {
        query = query.eq('gender', gender);
      }
      if (gender == null && me != null) {
        final og = me.gender.trim() == 'Male' ? 'Female' : 'Male';
        query = query.eq('gender', og);
      }
      // Exclude self if authenticated
      if (currentUser != null) {
        query = query.neq('auth_user_id', currentUser.id);
      }
      if (state != null) {
        final stateId = await _resolveStateIdByName(state);
        if (stateId != null) query = query.eq('state_id', stateId);
      }
      if (district != null) {
        final districtId = await _resolveDistrictIdByName(
          state ?? me?.state,
          district,
        );
        if (districtId != null) query = query.eq('district_id', districtId);
      }
      // Caste filters (multi takes precedence)
      if (castes != null && castes.isNotEmpty) {
        final ids = <String>[];
        for (final c in castes) {
          final id = await _resolveCasteIdByName(me?.religion, c);
          if (id != null) ids.add(id);
        }
        if (ids.isNotEmpty) {
          final csv = ids.map((e) => '"$e"').join(',');
          query = query.filter('caste_id', 'in', '(${csv})');
        }
      } else if (caste != null) {
        final casteId = await _resolveCasteIdByName(me?.religion, caste);
        if (casteId != null) query = query.eq('caste_id', casteId);
      }
      // Sub-caste name to id (same table)
      if (subCaste != null && subCaste.trim().isNotEmpty) {
        final subId = await _resolveCasteIdByName(me?.religion, subCaste);
        if (subId != null) query = query.eq('sub_caste_id', subId);
      }
      // City partial match
      if (city != null && city.trim().isNotEmpty) {
        query = query.ilike('city', '%${city.trim()}%');
      }
      if (education != null) {
        query = query.eq('education', education);
      }
      if (educations != null && educations.isNotEmpty) {
        final csv = educations.map((e) => '"$e"').join(',');
        query = query.filter('education', 'in', '(${csv})');
      }
      if (occupation != null) {
        query = query.eq('occupation', occupation);
      }
      if (occupations != null && occupations.isNotEmpty) {
        final csv = occupations.map((e) => '"$e"').join(',');
        query = query.filter('occupation', 'in', '(${csv})');
      }
      if (maritalStatuses != null && maritalStatuses.isNotEmpty) {
        final csv = maritalStatuses.map((e) => '"$e"').join(',');
        query = query.filter('marital_status', 'in', '(${csv})');
      }
      if (minHeight != null) query = query.gte('height_cm', minHeight);
      if (maxHeight != null) query = query.lte('height_cm', maxHeight);
      if (minIncome != null) query = query.gte('annual_income', minIncome);
      if (maxIncome != null) query = query.lte('annual_income', maxIncome);

      // Age filter using date_of_birth
      if (minAge != null || maxAge != null) {
        final now = DateTime.now();
        if (maxAge != null) {
          final minBirthDate = DateTime(
            now.year - maxAge - 1,
            now.month,
            now.day,
          );
          query = query.gte('date_of_birth', minBirthDate.toIso8601String());
        }
        if (minAge != null) {
          final maxBirthDate = DateTime(now.year - minAge, now.month, now.day);
          query = query.lte('date_of_birth', maxBirthDate.toIso8601String());
        }
      }

      // Registration date filter (profiles created within last N days)
      if (joinedWithinDays != null && joinedWithinDays > 0) {
        final threshold = DateTime.now().subtract(
          Duration(days: joinedWithinDays),
        );
        query = query.gte('created_at', threshold.toIso8601String());
      }

      // Activity filters
      if (onlineNow || recentlyActive) {
        final now = DateTime.now();
        final threshold = onlineNow
            ? now.subtract(const Duration(minutes: 10))
            : now.subtract(const Duration(hours: 24));
        query = query.gte('last_active_at', threshold.toIso8601String());
      }

      // Sorting
      final sort = (sortBy ?? 'active').trim();
      final orderedQuery = (() {
        if (sort == 'newest') {
          return query.order('created_at', ascending: false);
        } else if (sort == 'ageAsc') {
          // younger first => later DOB
          return query.order('date_of_birth', ascending: false);
        } else if (sort == 'ageDesc') {
          // older first => earlier DOB
          return query.order('date_of_birth', ascending: true);
        } else if (sort == 'incomeDesc') {
          return query.order('annual_income', ascending: false);
        } else {
          return query.order('last_active_at', ascending: false);
        }
      })();

      // Pagination using range (inclusive end)
      final from = (page * pageSize).clamp(0, 1000000);
      final to = from + pageSize - 1;
      final results = await orderedQuery.range(from, to);

      var list = results
          .map<MatrimonialUser>(
            (json) => MatrimonialUser.fromJson(_normalizeProfileRow(json)),
          )
          .toList();

      // Client-side filter for languages intersection, if provided
      if (languages != null && languages.isNotEmpty) {
        final lower = languages.map((e) => e.toLowerCase().trim()).toSet();
        list = list
            .where(
              (p) => p.languages
                  .map((e) => e.toLowerCase().trim())
                  .toSet()
                  .intersection(lower)
                  .isNotEmpty,
            )
            .toList();
      }

      return list;
    } catch (e) {
      debugPrint('❌ Error searching profiles: $e');
      return [];
    }
  }

  // Normalize database row to match MatrimonialUser model
  static Map<String, dynamic> _normalizeProfileRow(Map<String, dynamic> row) {
    // Flatten nested relations (state/district/caste) if present; avoid injecting defaults
    String? _stringish(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) return v['name']?.toString() ?? v['id']?.toString();
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        if (first is String) return first;
        if (first is Map)
          return first['name']?.toString() ?? first['id']?.toString();
      }
      return v.toString();
    }

    final normalized = <String, dynamic>{};
    // direct fields
    if (row.containsKey('id')) normalized['id'] = row['id'];
    if (row.containsKey('profile_id'))
      normalized['profile_id'] = row['profile_id'];
    if (row.containsKey('name')) normalized['name'] = row['name'];
    if (row.containsKey('email')) normalized['email'] = row['email'];
    if (row.containsKey('gender')) normalized['gender'] = row['gender'];
    if (row.containsKey('date_of_birth'))
      normalized['date_of_birth'] = row['date_of_birth'];
    if (row.containsKey('religion')) normalized['religion'] = row['religion'];
    if (row.containsKey('city')) normalized['city'] = row['city'];
    if (row.containsKey('education'))
      normalized['education'] = row['education'];
    if (row.containsKey('occupation'))
      normalized['occupation'] = row['occupation'];
    if (row.containsKey('working_location'))
      normalized['working_location'] = row['working_location'];
    if (row.containsKey('annual_income'))
      normalized['annual_income'] = row['annual_income'];
    if (row.containsKey('marital_status'))
      normalized['marital_status'] = row['marital_status'];
    if (row.containsKey('about_me')) normalized['about_me'] = row['about_me'];
    if (row.containsKey('family_details'))
      normalized['family_details'] = row['family_details'];
    if (row.containsKey('partner_preferences'))
      normalized['partner_preferences'] = row['partner_preferences'];
    if (row.containsKey('hobbies')) normalized['hobbies'] = row['hobbies'];
    if (row.containsKey('languages'))
      normalized['languages'] = row['languages'];
    if (row.containsKey('height')) normalized['height'] = row['height'];
    if (row.containsKey('height_cm')) normalized['height'] = row['height_cm'];
    if (row.containsKey('weight')) normalized['weight'] = row['weight'];
    if (row.containsKey('weight_kg')) normalized['weight'] = row['weight_kg'];
    if (row.containsKey('physical_disability'))
      normalized['physical_disability'] = row['physical_disability'];
    if (row.containsKey('is_active'))
      normalized['is_active'] = row['is_active'];
    if (row.containsKey('is_verified'))
      normalized['is_verified'] = row['is_verified'];
    if (row.containsKey('is_profile_complete'))
      normalized['is_profile_complete'] = row['is_profile_complete'];
    if (row.containsKey('photo_urls'))
      normalized['photo_urls'] = row['photo_urls'];
    if (row.containsKey('total_views'))
      normalized['total_views'] = row['total_views'];
    if (row.containsKey('total_interests'))
      normalized['total_interests'] = row['total_interests'];
    if (row.containsKey('created_at'))
      normalized['created_at'] = row['created_at'];
    if (row.containsKey('updated_at'))
      normalized['updated_at'] = row['updated_at'];
    if (row.containsKey('last_active_at'))
      normalized['last_active_at'] = row['last_active_at'];
    if (row.containsKey('profile_picture_url') ||
        row.containsKey('profile_image_url')) {
      normalized['profile_image_url'] =
          row['profile_picture_url'] ?? row['profile_image_url'];
    }

    // relation name unwrapping
    if (row.containsKey('caste'))
      normalized['caste'] = _stringish(row['caste']);
    if (row.containsKey('sub_caste'))
      normalized['sub_caste'] = _stringish(row['sub_caste']);
    if (row.containsKey('state'))
      normalized['state'] = _stringish(row['state']);
    if (row.containsKey('district'))
      normalized['district'] = _stringish(row['district']);

    // If nested relation objects exist for contact_info/family_info/partner_preferences, unwrap
    for (final rel in ['contact_info', 'family_info', 'partner_preferences']) {
      if (row[rel] is List && (row[rel] as List).isNotEmpty) {
        if (rel == 'partner_preferences') {
          normalized['partner_preference'] = (row[rel] as List).first;
        } else {
          normalized[rel] = (row[rel] as List).first;
        }
      } else if (row[rel] is Map) {
        if (rel == 'partner_preferences') {
          normalized['partner_preference'] = row[rel];
        } else {
          normalized[rel] = row[rel];
        }
      }
    }

    return normalized;
  }

  // ---------- Helper lookups ----------
  static Future<String?> _resolveStateIdByName(String? stateName) async {
    if (stateName == null || stateName.isEmpty) return null;
    if (_stateIdCache.containsKey(stateName)) return _stateIdCache[stateName];
    try {
      final res = await _supabase
          .from('states')
          .select('id')
          .eq('name', stateName)
          .maybeSingle();
      if (res != null) {
        _stateIdCache[stateName] = res['id'] as String;
        return _stateIdCache[stateName];
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _resolveDistrictIdByName(
    String? stateName,
    String? districtName,
  ) async {
    if (stateName == null ||
        districtName == null ||
        stateName.isEmpty ||
        districtName.isEmpty)
      return null;
    final key = '$stateName|$districtName';
    if (_districtIdCache.containsKey(key)) return _districtIdCache[key];
    try {
      final stateId = await _resolveStateIdByName(stateName);
      if (stateId == null) return null;
      final res = await _supabase
          .from('districts')
          .select('id')
          .eq('name', districtName)
          .eq('state_id', stateId)
          .maybeSingle();
      if (res != null) {
        _districtIdCache[key] = res['id'] as String;
        return _districtIdCache[key];
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _resolveCasteIdByName(
    String? religion,
    String? casteName,
  ) async {
    if (casteName == null || casteName.isEmpty) return null;
    final key = '${religion ?? ''}|$casteName';
    if (_casteIdCache.containsKey(key)) return _casteIdCache[key];
    try {
      var query = _supabase.from('castes').select('id').eq('name', casteName);
      if (religion != null && religion.isNotEmpty) {
        query = query.eq('religion', religion);
      }
      final res = await query.maybeSingle();
      if (res != null) {
        final id = res['id'] as String;
        _casteIdCache[key] = id;
        return id;
      }
    } catch (_) {}
    return null;
  }

  // ---------- Interactions & lists ----------
  static Future<List<MatrimonialUser>> getReceivedInterests(
    String userId,
  ) async {
    await initialize();
    try {
      final currentProfile = await getCurrentUserProfile(userId);
      if (currentProfile == null) return [];

      final response = await _supabase
          .from('profile_interactions')
          .select(
            'from_profile:matrimonial_profiles!profile_interactions_from_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*))',
          )
          .eq('to_profile_id', currentProfile.id)
          .eq('interaction_type', 'interest')
          .eq('status', 'pending');

      return response
          .map<MatrimonialUser>(
            (json) => MatrimonialUser.fromJson(
              _normalizeProfileRow(json['from_profile']),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting received interests: $e');
      return [];
    }
  }

  static Future<List<MatrimonialUser>> getSentInterests(String userId) async {
    await initialize();
    try {
      final currentProfile = await getCurrentUserProfile(userId);
      if (currentProfile == null) return [];

      final response = await _supabase
          .from('profile_interactions')
          .select(
            'to_profile:matrimonial_profiles!profile_interactions_to_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*))',
          )
          .eq('from_profile_id', currentProfile.id)
          .eq('interaction_type', 'interest');

      return response
          .map<MatrimonialUser>(
            (json) => MatrimonialUser.fromJson(
              _normalizeProfileRow(json['to_profile']),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting sent interests: $e');
      return [];
    }
  }

  static Future<List<MatrimonialUser>> getShortlistedProfiles(
    String userId,
  ) async {
    await initialize();
    try {
      final currentProfile = await getCurrentUserProfile(userId);
      if (currentProfile == null) return [];

      final response = await _supabase
          .from('shortlisted_profiles')
          .select(
            'shortlisted:matrimonial_profiles!shortlisted_profiles_shortlisted_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*))',
          )
          .eq('profile_id', currentProfile.id);

      return response
          .map<MatrimonialUser>(
            (json) => MatrimonialUser.fromJson(
              _normalizeProfileRow(json['shortlisted']),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting shortlisted profiles: $e');
      return [];
    }
  }

  // Profiles who shortlisted me
  static Future<List<MatrimonialUser>> getProfilesWhoShortlistedMe(
    String userId,
  ) async {
    await initialize();
    try {
      final currentProfile = await getCurrentUserProfile(userId);
      if (currentProfile == null) return [];

      final response = await _supabase
          .from('shortlisted_profiles')
          .select(
            'owner:matrimonial_profiles!shortlisted_profiles_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*))',
          )
          .eq('shortlisted_profile_id', currentProfile.id);

      return response
          .map<MatrimonialUser>(
            (json) =>
                MatrimonialUser.fromJson(_normalizeProfileRow(json['owner'])),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting who shortlisted me: $e');
      return [];
    }
  }

  static Future<List<MatrimonialUser>> getViewedProfiles(String userId) async {
    await initialize();
    try {
      final currentProfile = await getCurrentUserProfile(userId);
      if (currentProfile == null) return [];

      final response = await _supabase
          .from('profile_views')
          .select(
            'viewed:matrimonial_profiles!profile_views_viewed_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*), last_active_at)',
          )
          .eq('viewer_profile_id', currentProfile.id)
          .order('last_viewed_at', ascending: false);

      return response
          .map<MatrimonialUser>(
            (json) =>
                MatrimonialUser.fromJson(_normalizeProfileRow(json['viewed'])),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting viewed profiles: $e');
      return [];
    }
  }

  // People who viewed me: viewers of my profile ordered by last_viewed_at
  static Future<List<MatrimonialUser>> getViewersOfMe(String userId) async {
    await initialize();
    try {
      final currentProfile = await getCurrentUserProfile(userId);
      if (currentProfile == null) return [];

      final response = await _supabase
          .from('profile_views')
          .select(
            'viewer:matrimonial_profiles!profile_views_viewer_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*), last_active_at)',
          )
          .eq('viewed_profile_id', currentProfile.id)
          .order('last_viewed_at', ascending: false)
          .limit(50);

      return response
          .map<MatrimonialUser>(
            (json) =>
                MatrimonialUser.fromJson(_normalizeProfileRow(json['viewer'])),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting viewers of me: $e');
      return [];
    }
  }

  // Accepted connections: profiles where there is an accepted interest either direction
  static Future<List<MatrimonialUser>> getAcceptedConnections(
    String userId,
  ) async {
    await initialize();
    try {
      final currentProfile = await getCurrentUserProfile(userId);
      if (currentProfile == null) return [];

      // Fetch accepted interests sent by me
      final sentAccepted = await _supabase
          .from('profile_interactions')
          .select(
            'to_profile:matrimonial_profiles!profile_interactions_to_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*))',
          )
          .eq('from_profile_id', currentProfile.id)
          .eq('interaction_type', 'interest')
          .eq('status', 'accepted');

      // Fetch accepted interests received by me
      final receivedAccepted = await _supabase
          .from('profile_interactions')
          .select(
            'from_profile:matrimonial_profiles!profile_interactions_from_profile_id_fkey(*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*))',
          )
          .eq('to_profile_id', currentProfile.id)
          .eq('interaction_type', 'interest')
          .eq('status', 'accepted');

      final list = <MatrimonialUser>[];
      for (final j in sentAccepted) {
        list.add(
          MatrimonialUser.fromJson(_normalizeProfileRow(j['to_profile'])),
        );
      }
      for (final j in receivedAccepted) {
        list.add(
          MatrimonialUser.fromJson(_normalizeProfileRow(j['from_profile'])),
        );
      }

      // De-duplicate by profile id
      final seen = <String>{};
      final unique = <MatrimonialUser>[];
      for (final p in list) {
        if (seen.add(p.id)) unique.add(p);
      }
      return unique;
    } catch (e) {
      debugPrint('❌ Error getting accepted connections: $e');
      return [];
    }
  }

  static Future<List<MatrimonialUser>> getProfilesByGenderAndCaste(
    String gender,
    String caste,
  ) async {
    await initialize();
    try {
      final casteId = await _resolveCasteIdByName(null, caste);
      var query = _supabase
          .from('matrimonial_profiles')
          .select(
            '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
          )
          .eq('gender', gender)
          .eq('is_active', true);
      if (casteId != null) {
        query = query.eq('caste_id', casteId);
      }
      final response = await query
          .order('last_active_at', ascending: false)
          .limit(100);
      return response
          .map<MatrimonialUser>(
            (json) => MatrimonialUser.fromJson(_normalizeProfileRow(json)),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get profiles by gender and caste: $e');
      return [];
    }
  }

  // New this week: recently joined relevant profiles (opposite gender if possible)
  static Future<List<MatrimonialUser>> getNewThisWeekProfiles(
    String userId, {
    int limit = 20,
  }) async {
    await initialize();
    try {
      final me = await getCurrentUserProfile(userId);
      final opposite = (() {
        if (me == null) return null;
        final g = me.gender.trim();
        if (g == 'Male') return 'Female';
        if (g == 'Female') return 'Male';
        return null;
      })();

      var query = _supabase
          .from('matrimonial_profiles')
          .select(
            '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
          )
          .eq('is_active', true)
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          )
          .neq('auth_user_id', userId);
      if (opposite != null) query = query.eq('gender', opposite);

      final res = await query
          .order('created_at', ascending: false)
          .order('last_active_at', ascending: false)
          .limit(limit);

      return res
          .map<MatrimonialUser>(
            (j) => MatrimonialUser.fromJson(_normalizeProfileRow(j)),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to load new this week profiles: $e');
      return [];
    }
  }

  // Similar to your shortlisted: use signals from user's shortlist to fetch similar candidates
  static Future<List<MatrimonialUser>> getSimilarToShortlisted(
    String userId, {
    int limit = 20,
  }) async {
    await initialize();
    try {
      final me = await getCurrentUserProfile(userId);
      // Get last N shortlisted profiles with key attributes
      if (me == null) return [];
      final shortlistRows = await _supabase
          .from('shortlisted_profiles')
          .select(
            'shortlisted:matrimonial_profiles!shortlisted_profiles_shortlisted_profile_id_fkey(id, caste_id, state_id, district_id, education, gender)',
          )
          .eq('profile_id', me.id)
          .order('created_at', ascending: false)
          .limit(20);

      final casteIds = <String>{};
      final stateIds = <String>{};
      final districtIds = <String>{};
      final educations = <String>{};
      String? targetGender;
      for (final r in shortlistRows) {
        final s = r['shortlisted'] as Map<String, dynamic>;
        if (s['caste_id'] != null) casteIds.add(s['caste_id'] as String);
        if (s['state_id'] != null) stateIds.add(s['state_id'] as String);
        if (s['district_id'] != null)
          districtIds.add(s['district_id'] as String);
        if (s['education'] != null &&
            (s['education'] as String).trim().isNotEmpty) {
          educations.add((s['education'] as String).trim());
        }
        // Track opposing gender if consistent
        final g = (s['gender'] as String?)?.trim();
        if (g != null && g.isNotEmpty) targetGender = g;
      }

      // Fallback: if no shortlist signals, just return empty
      if (casteIds.isEmpty &&
          stateIds.isEmpty &&
          districtIds.isEmpty &&
          educations.isEmpty) {
        return [];
      }

      var query = _supabase
          .from('matrimonial_profiles')
          .select(
            '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
          )
          .eq('is_active', true)
          .neq('auth_user_id', userId);

      if (targetGender != null) query = query.eq('gender', targetGender);

      // Apply filters — prefer district, else state
      if (districtIds.isNotEmpty) {
        final csv = districtIds.map((e) => '"$e"').join(',');
        query = query.filter('district_id', 'in', '($csv)');
      } else if (stateIds.isNotEmpty) {
        final csv = stateIds.map((e) => '"$e"').join(',');
        query = query.filter('state_id', 'in', '($csv)');
      }
      if (casteIds.isNotEmpty) {
        final csv = casteIds.map((e) => '"$e"').join(',');
        query = query.filter('caste_id', 'in', '($csv)');
      }
      if (educations.isNotEmpty) {
        final csv = educations.map((e) => '"$e"').join(',');
        query = query.filter('education', 'in', '($csv)');
      }

      final res = await query
          .order('last_active_at', ascending: false)
          .limit(limit);

      var list = res
          .map<MatrimonialUser>(
            (j) => MatrimonialUser.fromJson(_normalizeProfileRow(j)),
          )
          .toList();

      // Optional: de-dup and remove any already shortlisted
      final myShortlistIds = shortlistRows
          .map<String?>(
            (r) => (r['shortlisted'] as Map<String, dynamic>)['id'] as String?,
          )
          .whereType<String>()
          .toSet();
      list = list.where((p) => !myShortlistIds.contains(p.id)).toList();

      return list;
    } catch (e) {
      debugPrint('❌ Failed to load similar-to-shortlisted profiles: $e');
      return [];
    }
  }

  // Get similar profiles to a given profile id by soft matching caste/state/district
  static Future<List<MatrimonialUser>> getSimilarProfiles(
    MatrimonialUser base, {
    int limit = 10,
  }) async {
    await initialize();
    try {
      // Resolve ids for better matching
      final casteId = await _resolveCasteIdByName(base.religion, base.caste);
      final stateId = await _resolveStateIdByName(base.state);
      final districtId = await _resolveDistrictIdByName(
        base.state,
        base.district,
      );

      var query = _supabase
          .from('matrimonial_profiles')
          .select(
            '*, state:states(name), district:districts(name), caste:castes!matrimonial_profiles_caste_id_fkey(name), sub_caste:castes!matrimonial_profiles_sub_caste_id_fkey(name), contact_info(*), family_info(*), partner_preferences(*)',
          )
          .eq('is_active', true)
          .neq('id', base.id);

      // "Similar" means the same gender as the profile being viewed,
      // and never the viewer's own profile.
      if (base.gender.isNotEmpty) query = query.eq('gender', base.gender);
      final viewerId = _supabase.auth.currentUser?.id;
      if (viewerId != null) query = query.neq('auth_user_id', viewerId);

      if (casteId != null) query = query.eq('caste_id', casteId);
      if (districtId != null)
        query = query.eq('district_id', districtId);
      else if (stateId != null)
        query = query.eq('state_id', stateId);

      final res = await query
          .order('last_active_at', ascending: false)
          .limit(limit);
      return res
          .map<MatrimonialUser>(
            (j) => MatrimonialUser.fromJson(_normalizeProfileRow(j)),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get similar profiles: $e');
      return [];
    }
  }

  static Future<bool> sendInterest(String toProfileId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      final currentProfile = await getCurrentUserProfile(currentUser.id);
      if (currentProfile == null) throw Exception('User profile not found');
      // Ensure target profile is active
      final target = await _supabase
          .from('matrimonial_profiles')
          .select('id,is_active')
          .eq('id', toProfileId)
          .maybeSingle();
      if (target == null || target['is_active'] != true) {
        throw Exception(
          'Cannot send interest: target profile is not available',
        );
      }

      // Idempotency: check if an interest already exists
      try {
        final existing = await _supabase
            .from('profile_interactions')
            .select('id,status')
            .eq('from_profile_id', currentProfile.id)
            .eq('to_profile_id', toProfileId)
            .eq('interaction_type', 'interest')
            .maybeSingle();
        if (existing != null) {
          // Already present; treat as success (idempotent)
          return true;
        }
      } catch (_) {}

      await _supabase.from('profile_interactions').insert({
        'from_profile_id': currentProfile.id,
        'to_profile_id': toProfileId,
        'interaction_type': 'interest',
        'status': 'pending',
      });
      return true;
    } catch (e) {
      final msg = e.toString();
      // Postgres unique violation / duplicate
      if (msg.contains('duplicate') || msg.contains('23505')) {
        return true; // treat as already sent (idempotent)
      }
      throw Exception('Failed to send interest: $e');
    }
  }

  static Future<void> updateInterestStatus({
    required String fromProfileId,
    required String toProfileId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('profile_interactions')
          .update({'status': status})
          .eq('from_profile_id', fromProfileId)
          .eq('to_profile_id', toProfileId)
          .eq('interaction_type', 'interest');
    } catch (e) {
      throw Exception('Failed to update interest: $e');
    }
  }

  static Future<bool> toggleShortlist(String profileId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      final currentProfile = await getCurrentUserProfile(currentUser.id);
      if (currentProfile == null) {
        throw Exception('User profile not found (required for shortlist)');
      }

      // Debug logging to diagnose RLS
      try {
        debugPrint(
          '⭐ toggleShortlist auth=${currentUser.id} myProfile=${currentProfile.id} target=$profileId',
        );
      } catch (_) {}

      // Pre-insert diagnostic: verify RLS precondition exists in DB
      try {
        final precheck = await _supabase
            .from('matrimonial_profiles')
            .select('id')
            .eq('id', currentProfile.id)
            .eq('auth_user_id', currentUser.id)
            .maybeSingle();
        debugPrint(
          '⭐ RLS precheck for shortlist: ${precheck != null ? 'OK' : 'MISSING'} (id=${currentProfile.id})',
        );
      } catch (_) {}

      final existing = await _supabase
          .from('shortlisted_profiles')
          .select()
          .eq('profile_id', currentProfile.id)
          .eq('shortlisted_profile_id', profileId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('shortlisted_profiles')
            .delete()
            .eq('profile_id', currentProfile.id)
            .eq('shortlisted_profile_id', profileId);
      } else {
        // Ensure target profile is active before adding to shortlist
        final target = await _supabase
            .from('matrimonial_profiles')
            .select('id,is_active')
            .eq('id', profileId)
            .maybeSingle();

        if (target == null || target['is_active'] != true) {
          throw Exception('Cannot shortlist: target profile is not available');
        }
        final payload = {
          'profile_id': currentProfile.id,
          'shortlisted_profile_id': profileId,
        };
        debugPrint('⭐ Inserting shortlist row: $payload');
        try {
          await _supabase.from('shortlisted_profiles').insert(payload);
        } catch (e) {
          final msg = e.toString();
          final isRls =
              msg.contains('row-level security') || msg.contains('42501');
          if (isRls) {
            debugPrint(
              '⚠️ RLS on shortlist insert, attempting RPC fallback insert_shortlist(target_profile_id)',
            );
            // Fallback to server-side insert that derives profile_id from auth.uid()
            await _supabase.rpc(
              'insert_shortlist',
              params: {'target_profile_id': profileId},
            );
          } else {
            rethrow;
          }
        }
      }
      return true;
    } catch (e) {
      throw Exception('Failed to toggle shortlist: $e');
    }
  }

  static Future<bool> viewProfile(String profileId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      final currentProfile = await getCurrentUserProfile(currentUser.id);
      if (currentProfile == null) throw Exception('User profile not found');

      // Pre-insert diagnostic for RLS
      try {
        final precheck = await _supabase
            .from('matrimonial_profiles')
            .select('id')
            .eq('id', currentProfile.id)
            .eq('auth_user_id', currentUser.id)
            .maybeSingle();
        debugPrint(
          '👁️ RLS precheck for view: ${precheck != null ? 'OK' : 'MISSING'} (viewer=${currentProfile.id})',
        );
      } catch (_) {}

      final existing = await _supabase
          .from('profile_views')
          .select()
          .eq('viewer_profile_id', currentProfile.id)
          .eq('viewed_profile_id', profileId)
          .maybeSingle();

      if (existing != null) {
        try {
          await _supabase
              .from('profile_views')
              .update({
                'view_count': (existing['view_count'] ?? 0) + 1,
                'last_viewed_at': DateTime.now().toIso8601String(),
              })
              .eq('viewer_profile_id', currentProfile.id)
              .eq('viewed_profile_id', profileId);
        } catch (e) {
          final msg = e.toString();
          final isRls =
              msg.contains('row-level security') || msg.contains('42501');
          if (isRls) {
            debugPrint(
              '⚠️ RLS on view update, attempting RPC fallback insert_or_increment_view(target_profile_id)',
            );
            await _supabase.rpc(
              'insert_or_increment_view',
              params: {'target_profile_id': profileId},
            );
          } else {
            rethrow;
          }
        }
      } else {
        try {
          await _supabase.from('profile_views').insert({
            'viewer_profile_id': currentProfile.id,
            'viewed_profile_id': profileId,
            'view_count': 1,
            'last_viewed_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          final msg = e.toString();
          final isRls =
              msg.contains('row-level security') || msg.contains('42501');
          final isDup = msg.contains('duplicate key') || msg.contains('23505');
          if (isRls) {
            debugPrint(
              '⚠️ RLS on view insert, attempting RPC fallback insert_or_increment_view(target_profile_id)',
            );
            await _supabase.rpc(
              'insert_or_increment_view',
              params: {'target_profile_id': profileId},
            );
          } else if (isDup) {
            // Treat duplicate as success and try to increment via RPC to be safe
            debugPrint(
              'ℹ️ Duplicate view detected, attempting safe increment via RPC',
            );
            try {
              await _supabase.rpc(
                'insert_or_increment_view',
                params: {'target_profile_id': profileId},
              );
            } catch (_) {}
          } else {
            rethrow;
          }
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to track profile view: $e');
    }
  }

  static Future<bool> blockProfile(String profileId, String reason) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');
      final currentProfile = await getCurrentUserProfile(currentUser.id);
      if (currentProfile == null) throw Exception('User profile not found');

      await _supabase.from('blocked_profiles').insert({
        'profile_id': currentProfile.id,
        'blocked_profile_id': profileId,
        'reason': reason,
      });
      return true;
    } catch (e) {
      throw Exception('Failed to block profile: $e');
    }
  }

  static Future<bool> saveProfile(
    MatrimonialUser profile, {
    bool saveContact = false,
    bool saveFamily = false,
    bool savePartner = false,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      // Debug flags
      // Note: keep concise to avoid log noise
      debugPrint(
        '💾 saveProfile(flags: contact=$saveContact, family=$saveFamily, partner=$savePartner)',
      );

      // Resolve names -> ids
      final stateId = await _resolveStateIdByName(profile.state);
      final districtId = await _resolveDistrictIdByName(
        profile.state,
        profile.district,
      );
      final casteId = await _resolveCasteIdByName(
        profile.religion,
        profile.caste,
      );

      // Upsert core profile
      debugPrint(
        '💾 upsert matrimonial_profiles: profile_image_url=${profile.profileImageUrl} photos=${profile.photoUrls.length}',
      );
      await _supabase.from('matrimonial_profiles').upsert({
        'id': profile.id,
        'auth_user_id': currentUser.id,
        'profile_id': profile.profileId,
        'name': profile.name,
        'email': profile.email,
        'profile_image_url': profile.profileImageUrl,
        'gender': profile.gender,
        'date_of_birth': profile.dateOfBirth.toIso8601String(),
        'religion': profile.religion,
        'caste_id': casteId,
        'state_id': stateId,
        'district_id': districtId,
        'city': profile.city,
        'education': profile.education,
        'occupation': profile.occupation,
        'working_location': profile.workingLocation,
        'annual_income': profile.annualIncome,
        'marital_status': profile.maritalStatus,
        'about_me': profile.aboutMe,
        'family_details': profile.familyDetails,
        'partner_preferences': profile.partnerPreferences,
        'hobbies': profile.hobbies,
        'languages': profile.languages,
        'height_cm': profile.height,
        'weight_kg': profile.weight,
        'physical_disability': profile.physicalDisability,
        'is_active': profile.isActive,
        'is_verified': profile.isVerified,
        'is_profile_complete': profile.isProfileComplete,
        'photo_urls': profile.photoUrls,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Re-fetch the canonical profile id for the authenticated user to ensure RLS alignment
      final meRow = await _supabase
          .from('matrimonial_profiles')
          .select('id, profile_image_url, photo_urls')
          .eq('auth_user_id', currentUser.id)
          .maybeSingle();
      if (meRow == null || meRow['id'] == null) {
        throw Exception('Unable to resolve profile id after save');
      }
      final String myProfileId = meRow['id'] as String;
      debugPrint(
        '💾 saveProfile(profileId: $myProfileId, db.profile_image_url=${meRow['profile_image_url']}, db.photo_urls_len=${(meRow['photo_urls'] as List?)?.length ?? 0})',
      );

      // Contact info helpers
      bool _isEmptyContact() {
        final ci = profile.contactInfo;
        bool isEmptyStr(String? s) => s == null || s.trim().isEmpty;
        return isEmptyStr(ci.phoneNumber) &&
            isEmptyStr(ci.alternatePhoneNumber) &&
            isEmptyStr(ci.whatsappNumber) &&
            isEmptyStr(ci.currentAddress) &&
            isEmptyStr(ci.permanentAddress) &&
            (ci.showPhone == false) &&
            (ci.showAddress == false);
      }

      // Contact info: update if exists else insert (by profile_id) — only when requested
      if (saveContact) {
        debugPrint('💾 contact_info: processing');
        final existingCI = await _supabase
            .from('contact_info')
            .select('id')
            .eq('profile_id', myProfileId)
            .maybeSingle();
        if (existingCI != null || !_isEmptyContact()) {
          final ciPayload = {
            'profile_id': myProfileId,
            'phone_number': profile.contactInfo.phoneNumber,
            'alternate_phone_number': profile.contactInfo.alternatePhoneNumber,
            'whatsapp_number': profile.contactInfo.whatsappNumber,
            'current_address': profile.contactInfo.currentAddress,
            'permanent_address': profile.contactInfo.permanentAddress,
            'show_phone': profile.contactInfo.showPhone,
            'show_address': profile.contactInfo.showAddress,
            'updated_at': DateTime.now().toIso8601String(),
          };
          try {
            if (existingCI != null) {
              debugPrint(
                '💾 contact_info: updating existing id=${existingCI['id']}',
              );
              await _supabase
                  .from('contact_info')
                  .update(ciPayload)
                  .eq('id', existingCI['id'] as String);
              debugPrint('💾 contact_info: update complete');
            } else {
              debugPrint('💾 contact_info: inserting new');
              await _supabase.from('contact_info').insert(ciPayload);
              debugPrint('💾 contact_info: insert complete');
            }
          } catch (e) {
            debugPrint('❌ contact_info write failed: $e');
            final msg = e.toString();
            final isRls =
                msg.contains('row-level security') || msg.contains('42501');
            if (isRls) {
              // Attempt server-side RPC fallback that derives profile_id from auth.uid()
              try {
                debugPrint(
                  '⚠️ RLS on contact_info write, attempting RPC fallback upsert_contact_info(ci)',
                );
                await _supabase.rpc(
                  'upsert_contact_info',
                  params: {'ci': ciPayload},
                );
                debugPrint('⚠️ upsert_contact_info RPC succeeded');
              } catch (rpcErr) {
                debugPrint('❌ upsert_contact_info RPC failed: $rpcErr');
                rethrow;
              }
            } else {
              rethrow;
            }
          }
        } else {
          debugPrint('💾 contact_info: skipped (empty and no existing)');
        }
      } else {
        debugPrint('💾 contact_info: skipped (flag=false)');
      }

      // Family info: update if exists else insert — only when requested
      final existingFI = saveFamily
          ? await _supabase
                .from('family_info')
                .select('id')
                .eq('profile_id', myProfileId)
                .maybeSingle()
          : null;
      bool _hasAnyFamilyData() {
        final f = profile.familyInfo;
        bool isEmptyStr(String? s) => s == null || s.trim().isEmpty;
        return !(isEmptyStr(f.fatherName) &&
            isEmptyStr(f.fatherOccupation) &&
            isEmptyStr(f.motherName) &&
            isEmptyStr(f.motherOccupation) &&
            (f.numberOfBrothers == null || f.numberOfBrothers == 0) &&
            (f.numberOfSisters == null || f.numberOfSisters == 0) &&
            isEmptyStr(f.familyType) &&
            isEmptyStr(f.familyValues) &&
            isEmptyStr(f.familyStatus) &&
            isEmptyStr(f.familyDetails));
      }

      if (saveFamily && (existingFI != null || _hasAnyFamilyData())) {
        debugPrint('💾 family_info: processing');
        final fiPayload = {
          'profile_id': myProfileId,
          'father_name': profile.familyInfo.fatherName,
          'father_occupation': profile.familyInfo.fatherOccupation,
          'mother_name': profile.familyInfo.motherName,
          'mother_occupation': profile.familyInfo.motherOccupation,
          'number_of_brothers': profile.familyInfo.numberOfBrothers,
          'number_of_sisters': profile.familyInfo.numberOfSisters,
          'family_type': profile.familyInfo.familyType,
          'family_values': profile.familyInfo.familyValues,
          'family_status': profile.familyInfo.familyStatus,
          'family_details': profile.familyInfo.familyDetails,
          'updated_at': DateTime.now().toIso8601String(),
        };
        try {
          if (existingFI != null) {
            debugPrint(
              '💾 family_info: updating existing id=${existingFI['id']}',
            );
            await _supabase
                .from('family_info')
                .update(fiPayload)
                .eq('id', existingFI['id'] as String);
            debugPrint('💾 family_info: update complete');
          } else {
            debugPrint('💾 family_info: inserting new');
            await _supabase.from('family_info').insert(fiPayload);
            debugPrint('💾 family_info: insert complete');
          }
        } catch (e) {
          debugPrint('❌ family_info write failed: $e');
          rethrow;
        }
      } else {
        if (!saveFamily) {
          debugPrint('💾 family_info: skipped (flag=false)');
        } else {
          debugPrint('💾 family_info: skipped (no data)');
        }
      }

      // Partner preferences: update if exists else insert — only when requested
      final existingPP = savePartner
          ? await _supabase
                .from('partner_preferences')
                .select('id')
                .eq('profile_id', myProfileId)
                .maybeSingle()
          : null;
      bool _hasAnyPartnerPrefs() {
        final pp = profile.partnerPreference;
        bool notEmptyList(List l) => l.isNotEmpty;
        return pp.minAge != null ||
            pp.maxAge != null ||
            pp.minHeight != null ||
            pp.maxHeight != null ||
            notEmptyList(pp.preferredStates) ||
            notEmptyList(pp.preferredDistricts) ||
            notEmptyList(pp.preferredCastes) ||
            notEmptyList(pp.preferredEducation) ||
            notEmptyList(pp.preferredOccupation) ||
            pp.minIncome != null ||
            pp.maxIncome != null ||
            notEmptyList(pp.preferredMaritalStatus) ||
            (pp.otherPreferences != null &&
                pp.otherPreferences!.trim().isNotEmpty);
      }

      if (savePartner && (existingPP != null || _hasAnyPartnerPrefs())) {
        debugPrint('💾 partner_preferences: processing');
        final ppPayload = {
          'profile_id': myProfileId,
          'min_age': profile.partnerPreference.minAge,
          'max_age': profile.partnerPreference.maxAge,
          'min_height_cm': profile.partnerPreference.minHeight,
          'max_height_cm': profile.partnerPreference.maxHeight,
          'preferred_states': profile.partnerPreference.preferredStates,
          'preferred_districts': profile.partnerPreference.preferredDistricts,
          'preferred_castes': profile.partnerPreference.preferredCastes,
          'preferred_education': profile.partnerPreference.preferredEducation,
          'preferred_occupation': profile.partnerPreference.preferredOccupation,
          'min_income': profile.partnerPreference.minIncome,
          'max_income': profile.partnerPreference.maxIncome,
          'preferred_marital_status':
              profile.partnerPreference.preferredMaritalStatus,
          'other_preferences': profile.partnerPreference.otherPreferences,
          'updated_at': DateTime.now().toIso8601String(),
        };
        try {
          if (existingPP != null) {
            debugPrint(
              '💾 partner_preferences: updating existing id=${existingPP['id']}',
            );
            await _supabase
                .from('partner_preferences')
                .update(ppPayload)
                .eq('id', existingPP['id'] as String);
            debugPrint('💾 partner_preferences: update complete');
          } else {
            debugPrint('💾 partner_preferences: inserting new');
            await _supabase.from('partner_preferences').insert(ppPayload);
            debugPrint('💾 partner_preferences: insert complete');
          }
        } catch (e) {
          debugPrint('❌ partner_preferences write failed: $e');
          rethrow;
        }
      } else {
        if (!savePartner) {
          debugPrint('💾 partner_preferences: skipped (flag=false)');
        } else {
          debugPrint('💾 partner_preferences: skipped (no data)');
        }
      }

      debugPrint(
        '💾 saveProfile: completed successfully for myProfileId=$myProfileId',
      );
      return true;
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  static Future<List<LocationData>> getStates() async {
    try {
      final response = await _supabase
          .from('states')
          .select()
          .eq('is_active', true)
          .order('name');
      return response
          .map<LocationData>((j) => LocationData.fromJson(j))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching states: $e');
      return [];
    }
  }

  static Future<List<LocationData>> getDistrictsByState(String stateId) async {
    try {
      final response = await _supabase
          .from('districts')
          .select()
          .eq('state_id', stateId)
          .eq('is_active', true)
          .order('name');
      return response
          .map<LocationData>((j) => LocationData.fromJson(j))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching districts: $e');
      return [];
    }
  }

  static Future<List<models.CasteData>> getCastesByReligion(
    String religion,
  ) async {
    try {
      final response = await _supabase
          .from('castes')
          .select()
          .eq('religion', religion)
          .eq('is_active', true)
          .order('name');
      return response
          .map<models.CasteData>((j) => models.CasteData.fromJson(j))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching castes: $e');
      return [];
    }
  }

  static Future<List<String>> getEducations() async {
    try {
      final response = await _supabase
          .from('matrimonial_profiles')
          .select('education')
          .order('education');
      final values =
          response
              .map((j) => (j['education'] ?? '').toString().trim())
              .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
              .toSet()
              .toList()
            ..sort();
      return values;
    } catch (e) {
      debugPrint('❌ Error fetching educations: $e');
      return [];
    }
  }

  static Future<List<String>> getOccupations() async {
    try {
      final response = await _supabase
          .from('matrimonial_profiles')
          .select('occupation')
          .order('occupation');
      final values =
          response
              .map((j) => (j['occupation'] ?? '').toString().trim())
              .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
              .toSet()
              .toList()
            ..sort();
      return values;
    } catch (e) {
      debugPrint('❌ Error fetching occupations: $e');
      return [];
    }
  }

  // Auto-create a minimal matrimonial profile for the current authenticated user
  static Future<bool> ensureProfileForCurrentUser() async {
    await initialize();
    try {
      final current = _supabase.auth.currentUser;
      if (current == null) throw Exception('Not authenticated');

      // If already exists, nothing to do
      final existing = await _supabase
          .from('matrimonial_profiles')
          .select('id')
          .eq('auth_user_id', current.id)
          .maybeSingle();
      if (existing != null) {
        return true;
      }

      // Build minimal defaults; editable later by user
      final fallbackName =
          current.userMetadata?['full_name']?.toString() ??
          current.email?.split('@').first ??
          'User';
      final today = DateTime.now();
      final defaultDob = DateTime(today.year - 25, today.month, today.day);

      await _supabase.from('matrimonial_profiles').insert({
        'auth_user_id': current.id,
        // profile_id is generated by DB trigger if null
        'name': fallbackName,
        'email': current.email ?? '',
        'gender': 'Male', // user can change later
        'date_of_birth': defaultDob.toIso8601String(),
        'religion': 'Hindu', // user can change later
        'marital_status': 'Never Married',
        'is_active': true,
        'is_profile_complete': false,
      });

      // Create empty related rows for convenience (optional)
      final created = await _supabase
          .from('matrimonial_profiles')
          .select('id')
          .eq('auth_user_id', current.id)
          .maybeSingle();
      if (created == null) return false;
      final pid = created['id'] as String;

      // Upsert related tables with minimal rows to simplify editing flows
      try {
        await _supabase.from('contact_info').insert({'profile_id': pid});
      } catch (_) {}
      try {
        await _supabase.from('family_info').insert({'profile_id': pid});
      } catch (_) {}
      try {
        await _supabase.from('partner_preferences').insert({'profile_id': pid});
      } catch (_) {}

      return true;
    } catch (e) {
      // Surface in caller for user feedback
      rethrow;
    }
  }

  static Future<bool> deactivateProfile(String profileId) async {
    try {
      await _supabase
          .from('matrimonial_profiles')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profileId);
      return true;
    } catch (e) {
      throw Exception('Failed to deactivate profile: $e');
    }
  }

  static Future<bool> deleteProfile(String profileId) async {
    try {
      await _supabase.rpc(
        'delete_profile_and_related',
        params: {'p_profile_id': profileId},
      );
      return true;
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  /// Restore a minimal profile from a deleted_users row. Returns the new profile id or null.
  static Future<String?> restoreProfileFromDeleted(String deletedId) async {
    try {
      final res = await _supabase.rpc(
        'restore_profile_from_deleted',
        params: {'p_deleted_id': deletedId},
      );
      if (res == null) return null;
      // RPC returns the new uuid; cast to string
      return res.toString();
    } catch (e) {
      throw Exception('Failed to restore profile: $e');
    }
  }

  /// Restore the latest archived profile for the currently authenticated user.
  /// Returns the restored profile id (or existing profile id) if successful.
  static Future<String?> restoreProfileForCurrentUser() async {
    try {
      final res = await _supabase.rpc('restore_profile_for_current_user');
      return res?.toString();
    } catch (e) {
      throw Exception('Failed to restore profile for current user: $e');
    }
  }

  /// Reactivate a deactivated profile by setting is_active = true.
  static Future<bool> reactivateProfile(String profileId) async {
    try {
      await _supabase
          .from('matrimonial_profiles')
          .update({
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', profileId);
      return true;
    } catch (e) {
      throw Exception('Failed to reactivate profile: $e');
    }
  }
}
