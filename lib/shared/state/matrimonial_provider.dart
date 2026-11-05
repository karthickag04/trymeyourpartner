import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/matrimonial_user.dart';
import '../models/location_data.dart';
import '../models/caste_data.dart' as caste_model;
import '../../app/di/service_locator.dart';
import '../../core/services/matrimonial_domain_service.dart';
import '../../core/services/realtime_service.dart';
import '../../core/services/presence_service.dart';

class MatrimonialProvider with ChangeNotifier {
  final MatrimonialDomainService _svc = sl.matrimonialService;
  final RealtimeService _rt = sl.realtimeService;
  final PresenceService _presence = sl.presenceService;
  List<MatrimonialUser> _allProfiles = [];
  List<MatrimonialUser> _matchedProfiles = [];
  List<MatrimonialUser> _receivedInterests = [];
  List<MatrimonialUser> _sentInterests = [];
  // Track IDs we've sent interest to (for fast UI checks/optimistic updates)
  final Set<String> _sentInterestIds = <String>{};
  List<MatrimonialUser> _shortlistedProfiles = [];
  // split: shortlisted by me vs who shortlisted me
  List<MatrimonialUser> _shortlistedByMe = [];
  List<MatrimonialUser> _shortlistedMe = [];
  List<MatrimonialUser> _viewedProfiles = [];
  List<MatrimonialUser> _viewersOfMe = [];
  List<MatrimonialUser> _acceptedConnections = [];
  List<MatrimonialUser> _newThisWeek = [];
  List<MatrimonialUser> _similarToShortlisted = [];
  List<MatrimonialUser> _searchResults = [];
  int _searchPage = 0;
  bool _hasMoreSearch = true;
  bool _isLoadingMore = false;

  MatrimonialUser? _currentUserProfile;
  String? _lastLoadedUserId; // Track the last user we loaded data for
  DateTime? _lastDataLoadTime; // Track when data was last loaded
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  bool _isLoading = false;
  bool _isLoadingUserData = false;
  bool _isLoadingMatches = false; // prevent concurrent/redundant loads
  bool _isLoadingAccepted = false; // guard for accepted connections loads
  bool _isLoadingReceived = false; // guard for received interests loads
  String _error = '';
  bool _isInitialized = false;
  DateTime? _lastMatchesRequestAt; // throttle rapid re-requests
  DateTime? _lastAcceptedRequestAt; // throttle accepted connections re-requests
  DateTime? _lastReceivedRequestAt; // throttle received interests re-requests

  // Realtime subscriptions (profile_interactions)
  Object? _interactionsChannel;
  String? _interactionsSubscribedProfileId;
  String? _pendingRealtimeToast; // transient in-app toast message
  // Global presence heartbeat timer
  Timer? _presenceHeartbeat;
  // Optional polling to keep interest/accepted lists live in HTTP mode
  Timer? _interestsPoll;

  // Expose and clear the pending toast atomically
  String? takeRealtimeToast() {
    final msg = _pendingRealtimeToast;
    _pendingRealtimeToast = null;
    return msg;
  }

  // Lookup caches
  List<LocationData> _statesCache = [];
  final Map<String, List<LocationData>> _districtsCache = {};
  final Map<String, List<caste_model.CasteData>> _castesByReligionCache = {};
  List<String> _educationsCache = [];
  List<String> _occupationsCache = [];

  // Last search filters persistence
  String? lastSearchState;
  String? lastSearchDistrict;
  // Single-value legacy fields (kept for backward compatibility)
  String? lastSearchCaste;
  String? lastSearchEducation;
  String? lastSearchOccupation;
  int? lastSearchMinAge;
  int? lastSearchMaxAge;
  double? lastSearchMinHeight;
  double? lastSearchMaxHeight;
  // New multi-selects and advanced filters
  List<String>? lastSearchCastes;
  List<String>? lastSearchEducations;
  List<String>? lastSearchOccupations;
  List<String>? lastSearchMaritalStatuses;
  List<String>? lastSearchLanguages;
  double? lastSearchMinIncome;
  double? lastSearchMaxIncome;
  bool? lastSearchOnlineNow;
  bool? lastSearchRecentlyActive;
  String?
  lastSearchSortBy; // 'active' (default) | 'newest' | 'ageAsc' | 'ageDesc' | 'incomeDesc'
  int? lastSearchJoinedWithinDays; // session-only, not persisted

  // Getters
  List<MatrimonialUser> get allProfiles => _allProfiles;
  List<MatrimonialUser> get matchedProfiles => _matchedProfiles;
  List<MatrimonialUser> get receivedInterests => _receivedInterests;
  List<MatrimonialUser> get sentInterests => _sentInterests;
  // Backwards compat: expose legacy getter as "by me"
  List<MatrimonialUser> get shortlistedProfiles => _shortlistedByMe;
  List<MatrimonialUser> get shortlistedByMe => _shortlistedByMe;
  List<MatrimonialUser> get shortlistedMe => _shortlistedMe;
  List<MatrimonialUser> get viewedProfiles => _viewedProfiles;
  List<MatrimonialUser> get viewersOfMe => _viewersOfMe;
  List<MatrimonialUser> get acceptedConnections => _acceptedConnections;
  List<MatrimonialUser> get newThisWeek => _newThisWeek;
  List<MatrimonialUser> get similarToShortlisted => _similarToShortlisted;
  List<MatrimonialUser> get searchResults => _searchResults;
  bool get hasMoreSearch => _hasMoreSearch;
  bool get isLoadingMore => _isLoadingMore;

  MatrimonialUser? get currentUserProfile => _currentUserProfile;

  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isInitialized => _isInitialized;
  // Lightweight freshness helpers for screens to avoid back-to-back loads
  bool shouldReloadAccepted({Duration minAge = const Duration(seconds: 5)}) {
    final t = _lastAcceptedRequestAt;
    if (t == null) return true;
    return DateTime.now().difference(t) > minAge;
  }

  bool shouldReloadReceived({Duration minAge = const Duration(seconds: 5)}) {
    final t = _lastReceivedRequestAt;
    if (t == null) return true;
    return DateTime.now().difference(t) > minAge;
  }

  // --- Persisted freshness handling (per profile) ---
  String _tsKey(String category, String profileId) =>
      'last_load_${category}_$profileId';

  Future<void> _restoreLastLoadTimestamps(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final a = prefs.getInt(_tsKey('accepted', profileId));
      final r = prefs.getInt(_tsKey('received', profileId));
      if (a != null) {
        _lastAcceptedRequestAt = DateTime.fromMillisecondsSinceEpoch(a);
      }
      if (r != null) {
        _lastReceivedRequestAt = DateTime.fromMillisecondsSinceEpoch(r);
      }
    } catch (_) {}
  }

  Future<void> _persistLastLoadTimestamp({
    required String category,
    required String profileId,
    required DateTime at,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _tsKey(category, profileId),
        at.millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  // Lookup getters
  List<LocationData> get states => _statesCache;
  List<LocationData> districtsFor(String stateId) =>
      _districtsCache[stateId] ?? [];
  List<caste_model.CasteData> castesForReligion(String religion) =>
      _castesByReligionCache[religion] ?? [];
  List<String> get educations => _educationsCache;
  List<String> get occupations => _occupationsCache;

  // Mandatory fields required for enabling matches/search
  bool isMandatoryComplete(MatrimonialUser profile) {
    bool _has(String? s) => s != null && s.trim().isNotEmpty;
    final now = DateTime.now();
    final minDob = DateTime(now.year - 18, now.month, now.day);

    final hasValidDob = profile.dateOfBirth.isBefore(minDob);

    return _has(profile.religion) &&
        _has(profile.caste) &&
        _has(profile.state) &&
        _has(profile.district) &&
        _has(profile.education) &&
        hasValidDob;
  }

  // Approximate completion percentage used for UI nudges
  int completionPercent(MatrimonialUser profile) {
    int score = 0;
    int total = 0;
    bool hasStr(String? s) => s != null && s.trim().isNotEmpty;
    void add(bool ok) {
      total++;
      if (ok) score++;
    }

    final now = DateTime.now();
    final minDob = DateTime(now.year - 18, now.month, now.day);

    // Core basics
    add(hasStr(profile.name));
    add(profile.gender.trim().isNotEmpty);
    add(profile.dateOfBirth.isBefore(minDob));
    add(hasStr(profile.religion));
    add(hasStr(profile.caste));
    add(hasStr(profile.state));
    add(hasStr(profile.district));
    add(hasStr(profile.city));
    add(hasStr(profile.education));
    add(hasStr(profile.occupation));

    // Contact info (light weight)
    add(hasStr(profile.contactInfo.phoneNumber));
    add(hasStr(profile.contactInfo.whatsappNumber));

    // Preferences (optional but helpful)
    add(profile.partnerPreferences != null);

    if (total == 0) return 0;
    final pct = ((score / total) * 100).round();
    return pct.clamp(0, 100);
  }

  // Initialize the provider and service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _svc.initialize();
      _isInitialized = true;
      // Attempt to restore last search from local storage
      await _restoreLastSearchFromStorage();
      // debugPrint('[MatrimonialProvider] initialized');
    } catch (e) {
      _setError('Failed to initialize: $e');
      // debugPrint('MatrimonialProvider initialization failed: $e');
    }
  }

  // Prefetch and cache lookup lists (idempotent)
  Future<void> prefetchLookups({String? religion, String? stateId}) async {
    await initialize();
    try {
      if (_statesCache.isEmpty) {
        _statesCache = await _svc.getStates();
      }
      if (religion != null && religion.isNotEmpty) {
        _castesByReligionCache.putIfAbsent(religion, () => []);
        if (_castesByReligionCache[religion]!.isEmpty) {
          _castesByReligionCache[religion] = await _svc.getCastesByReligion(
            religion,
          );
        }
      }
      if (stateId != null && stateId.isNotEmpty) {
        if (!_districtsCache.containsKey(stateId)) {
          _districtsCache[stateId] = await _svc.getDistrictsByState(stateId);
        }
      }
      if (_educationsCache.isEmpty) {
        _educationsCache = await _svc.getEducations();
      }
      if (_occupationsCache.isEmpty) {
        _occupationsCache = await _svc.getOccupations();
      }
      notifyListeners();
    } catch (_) {}
  }

  // Check if data needs to be loaded for a different user
  bool _needsDataRefresh(String userId) {
    // Force refresh if different user
    if (_lastLoadedUserId != userId) {
      // debugPrint('[MatrimonialProvider] different user detected, refresh');
      return true;
    }

    // Force refresh if no profile data
    if (_currentUserProfile == null) {
      // debugPrint('[MatrimonialProvider] no current profile, refresh');
      return true;
    }

    // Check cache validity
    if (_lastDataLoadTime == null) {
      // debugPrint('[MatrimonialProvider] no load time, refresh');
      return true;
    }

    final timeSinceLastLoad = DateTime.now().difference(_lastDataLoadTime!);
    if (timeSinceLastLoad > _cacheValidDuration) {
      // debugPrint('[MatrimonialProvider] cache expired (${timeSinceLastLoad.inMinutes}m)');
      return true;
    }

    // debugPrint('[MatrimonialProvider] cache valid for $userId');
    return false;
  }

  // Load all user data (called when user logs in or app restarts)
  Future<void> loadAllUserData(String userId) async {
    if (_isLoadingUserData) {
      return;
    }
    if (!_needsDataRefresh(userId)) {
      // Data already up-to-date for this user; skip reload
      return;
    }

    // debugPrint('[MatrimonialProvider] loading all data for $userId');
    _setLoading(true);
    _isLoadingUserData = true;

    try {
      // Ensure service is initialized
      await initialize();

      // Load user profile first (this handles auto-assignment)
      await loadCurrentUserProfile(userId);

      // Always load matches: service supports browse mode without profile
      // Load other lists only when we have a valid profile
      final futures = <Future<void>>[];
      futures.add(loadMatches(userId));
      if (_currentUserProfile != null) {
        debugPrint('✅ Profile available, loading additional data...');
        futures.addAll([
          loadReceivedInterests(userId),
          loadSentInterests(userId),
          loadShortlistedProfiles(userId),
          loadViewedProfiles(userId),
          loadViewersOfMe(userId),
          loadNewThisWeek(userId),
          loadSimilarToShortlisted(userId),
        ]);
      } else {
        debugPrint('💡 No profile available; loading matches in browse mode');
        futures.add(loadNewThisWeek(userId));
      }

      await Future.wait(futures);

      _lastLoadedUserId = userId;
      _lastDataLoadTime = DateTime.now(); // Track load time
      // debugPrint('[MatrimonialProvider] data load completed at ${_lastDataLoadTime}');

      // Ensure realtime subscriptions are active for this profile
      // Safe to call repeatedly; it will no-op if already subscribed
      await _subscribeToInterestRealtime(authUserId: userId);
      _startPresenceHeartbeat();
    } catch (e) {
      _setError('Failed to load user data: $e');
      // debugPrint('Failed to load user data: $e');
      // Clear cache on error so next attempt will retry
      _lastLoadedUserId = null;
      _lastDataLoadTime = null;
    } finally {
      _setLoading(false);
      _isLoadingUserData = false;
    }
  }

  // Force refresh all user data (ignores cache)
  Future<void> forceRefreshUserData(String userId) async {
    // debugPrint('[MatrimonialProvider] force refresh for $userId');
    // Clear cache to force refresh
    _lastLoadedUserId = null;
    _lastDataLoadTime = null;
    _currentUserProfile = null;

    await loadAllUserData(userId);
  }

  // Clear all data (when user logs out)
  void clearAllData() {
    // debugPrint('[MatrimonialProvider] clear all');
    _unsubscribeFromRealtime();
    _allProfiles.clear();
    _matchedProfiles.clear();
    _receivedInterests.clear();
    _sentInterests.clear();
    _shortlistedProfiles.clear();
    _shortlistedByMe.clear();
    _shortlistedMe.clear();
    _viewedProfiles.clear();
    _acceptedConnections.clear();
    _searchResults.clear();
    _currentUserProfile = null;
    _lastLoadedUserId = null;
    _lastDataLoadTime = null; // Clear load time
    _error = '';
    _presenceHeartbeat?.cancel();
    _interestsPoll?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribeFromRealtime();
    _presenceHeartbeat?.cancel();
    _interestsPoll?.cancel();
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    if (_error == error) return;
    _error = error;
    notifyListeners();
  }

  // Load current user's matrimonial profile
  Future<void> loadCurrentUserProfile(String authUserId) async {
    try {
      _setLoading(true);
      _setError('');

      // Ensure service is initialized
      await initialize();

      // debugPrint('[MatrimonialProvider] load profile for $authUserId');

      _currentUserProfile = await _svc.getCurrentUserProfile(authUserId);

      if (_currentUserProfile != null) {
        // debugPrint('[MatrimonialProvider] profile found: ${_currentUserProfile!.name}');
      } else {
        // debugPrint('[MatrimonialProvider] no profile for $authUserId');
        // User can still browse and interact with profiles even without their own profile
      }

      // Force notify listeners to update UI
      notifyListeners();

      // Restore freshness timestamps for this profile so screens share state
      final pid = _currentUserProfile?.id;
      if (pid != null && pid.isNotEmpty) {
        // Fire and forget; getters will read from memory afterwards
        // ignore: unawaited_futures
        _restoreLastLoadTimestamps(pid);
      }
    } catch (e) {
      _setError('Failed to load profile: $e');
      debugPrint('❌ Error loading profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load matched profiles based on preferences and caste
  Future<void> loadMatches(String userId) async {
    // Debounce/throttle: skip if already loading or called too frequently
    if (_isLoadingMatches) return;
    final now = DateTime.now();
    if (_lastMatchesRequestAt != null &&
        now.difference(_lastMatchesRequestAt!) < const Duration(seconds: 2)) {
      return;
    }
    _isLoadingMatches = true;
    _lastMatchesRequestAt = now;
    try {
      _setError('');

      // Ensure service is initialized
      await initialize();

      _matchedProfiles = await _svc.getMatches(userId);
      // Notify consumers (e.g., Matches screen, Home Top Picks)
      notifyListeners();
    } catch (e) {
      _setError('Failed to load matches: $e');
    } finally {
      _isLoadingMatches = false;
    }
  }

  // Load received interests
  Future<void> loadReceivedInterests(String userId) async {
    // Debounce/throttle: skip if already loading or called too frequently
    if (_isLoadingReceived) return;
    final now = DateTime.now();
    if (_lastReceivedRequestAt != null &&
        now.difference(_lastReceivedRequestAt!) < const Duration(seconds: 5)) {
      return;
    }
    _isLoadingReceived = true;
    _lastReceivedRequestAt = now;
    try {
      _setError('');

      _receivedInterests = await _svc.getReceivedInterests(userId);
      notifyListeners();
      // Persist request time per profile for cross-screen freshness
      final pid = _currentUserProfile?.id;
      if (pid != null && pid.isNotEmpty) {
        // ignore: unawaited_futures
        _persistLastLoadTimestamp(
          category: 'received',
          profileId: pid,
          at: now,
        );
      }
    } catch (e) {
      _setError('Failed to load interests: $e');
    } finally {
      _isLoadingReceived = false;
    }
  }

  // Load sent interests
  Future<void> loadSentInterests(String userId) async {
    try {
      _setError('');

      _sentInterests = await _svc.getSentInterests(userId);
      // Keep the ID set in sync for quick lookups in UI
      _sentInterestIds
        ..clear()
        ..addAll(_sentInterests.map((p) => p.id));
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sent interests: $e');
    }
  }

  // Load shortlisted profiles
  Future<void> loadShortlistedProfiles(String userId) async {
    try {
      _setError('');
      debugPrint('📥 Loading shortlisted(by me) for user: $userId');
      _shortlistedByMe = await _svc.getShortlistedProfiles(userId);
      debugPrint('✅ Shortlisted(by me) loaded: ${_shortlistedByMe.length}');
      debugPrint('📥 Loading shortlisted(me) for user: $userId');
      _shortlistedMe = await _svc.getProfilesWhoShortlistedMe(userId);
      debugPrint('✅ Shortlisted(me) loaded: ${_shortlistedMe.length}');
      // keep legacy list in sync for existing UIs
      _shortlistedProfiles = List<MatrimonialUser>.from(_shortlistedByMe);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load shortlisted profiles: $e');
    }
  }

  // Load viewed profiles
  Future<void> loadViewedProfiles(String userId) async {
    try {
      _setError('');
      debugPrint('📥 Loading viewed profiles for user: $userId');
      _viewedProfiles = await _svc.getViewedProfiles(userId);
      debugPrint('✅ Viewed loaded: ${_viewedProfiles.length}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load viewed profiles: $e');
    }
  }

  Future<void> loadViewersOfMe(String userId) async {
    try {
      _setError('');
      debugPrint('📥 Loading viewers of me for user: $userId');
      _viewersOfMe = await _svc.getViewersOfMe(userId);
      debugPrint('✅ Viewers loaded: ${_viewersOfMe.length}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load viewers: $e');
    }
  }

  // Load accepted connections (interests with status 'accepted' either direction)
  Future<void> loadAcceptedConnections(String userId) async {
    // Debounce/throttle: skip if already loading or called too frequently
    if (_isLoadingAccepted) return;
    final now = DateTime.now();
    if (_lastAcceptedRequestAt != null &&
        now.difference(_lastAcceptedRequestAt!) < const Duration(seconds: 5)) {
      return;
    }
    _isLoadingAccepted = true;
    _lastAcceptedRequestAt = now;
    try {
      _setError('');
      debugPrint('📥 Loading accepted connections for user: $userId');
      _acceptedConnections = await _svc.getAcceptedConnections(userId);
      debugPrint(
        '✅ Accepted connections loaded: ${_acceptedConnections.length}',
      );
      notifyListeners();
      // Persist request time per profile for cross-screen freshness
      final pid = _currentUserProfile?.id;
      if (pid != null && pid.isNotEmpty) {
        // ignore: unawaited_futures
        _persistLastLoadTimestamp(
          category: 'accepted',
          profileId: pid,
          at: now,
        );
      }
    } catch (e) {
      _setError('Failed to load accepted connections: $e');
    } finally {
      _isLoadingAccepted = false;
    }
  }

  Future<void> loadNewThisWeek(String userId) async {
    try {
      _setError('');
      _newThisWeek = await _svc.getNewThisWeekProfiles(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load new this week: $e');
    }
  }

  Future<void> loadSimilarToShortlisted(String userId) async {
    try {
      _setError('');
      _similarToShortlisted = await _svc.getSimilarToShortlisted(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recommendations: $e');
    }
  }

  // Search profiles with filters
  Future<void> searchProfiles({
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
    double? minHeight,
    double? maxHeight,
    double? minIncome,
    double? maxIncome,
    int? joinedWithinDays,
    bool onlineNow = false,
    bool recentlyActive = false,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      // Do not toggle global loading here; search is local to SearchScreen
      _setError('');

      // Persist last search filters
      lastSearchState = state;
      lastSearchDistrict = district;
      lastSearchCaste = caste;
      lastSearchEducation = education;
      lastSearchOccupation = occupation;
      lastSearchMinAge = minAge;
      lastSearchMaxAge = maxAge;
      lastSearchMinHeight = minHeight;
      lastSearchMaxHeight = maxHeight;
      lastSearchCastes = castes;
      lastSearchEducations = educations;
      lastSearchOccupations = occupations;
      lastSearchMaritalStatuses = maritalStatuses;
      lastSearchLanguages = languages;
      lastSearchMinIncome = minIncome;
      lastSearchMaxIncome = maxIncome;
      lastSearchOnlineNow = onlineNow;
      lastSearchRecentlyActive = recentlyActive;
      lastSearchSortBy = sortBy;
      // Persist in-memory for pagination within session
      lastSearchJoinedWithinDays = joinedWithinDays;

      _searchPage = page;
      _hasMoreSearch = true;
      _searchResults = await _svc.searchProfiles(
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
        minHeight: minHeight?.toInt(),
        maxHeight: maxHeight?.toInt(),
        minIncome: minIncome,
        maxIncome: maxIncome,
        joinedWithinDays: joinedWithinDays,
        onlineNow: onlineNow,
        recentlyActive: recentlyActive,
        sortBy: sortBy,
        page: page,
        pageSize: pageSize,
      );

      // Determine if more pages available (simple heuristic)
      _hasMoreSearch = _searchResults.length >= pageSize;

      debugPrint(
        '🔍 Provider: Search completed, results: ${_searchResults.length}',
      );
      notifyListeners();

      // Persist last search to storage
      await _persistLastSearchToStorage();
    } catch (e) {
      _setError('Failed to search profiles: $e');
    }
  }

  Future<void> loadMoreSearchResults({int pageSize = 20}) async {
    if (_isLoadingMore || !_hasMoreSearch) return;
    _isLoadingMore = true;
    try {
      final nextPage = _searchPage + 1;
      final more = await _svc.searchProfiles(
        state: lastSearchState,
        district: lastSearchDistrict,
        caste: lastSearchCaste,
        castes: lastSearchCastes,
        subCaste: null,
        city: null,
        minAge: lastSearchMinAge,
        maxAge: lastSearchMaxAge,
        education: lastSearchEducation,
        occupation: lastSearchOccupation,
        educations: lastSearchEducations,
        occupations: lastSearchOccupations,
        maritalStatuses: lastSearchMaritalStatuses,
        languages: lastSearchLanguages,
        minHeight: lastSearchMinHeight?.toInt(),
        maxHeight: lastSearchMaxHeight?.toInt(),
        minIncome: lastSearchMinIncome,
        maxIncome: lastSearchMaxIncome,
        joinedWithinDays: lastSearchJoinedWithinDays,
        onlineNow: lastSearchOnlineNow ?? false,
        recentlyActive: lastSearchRecentlyActive ?? false,
        sortBy: lastSearchSortBy,
        page: nextPage,
        pageSize: pageSize,
      );
      _searchResults.addAll(more);
      _searchPage = nextPage;
      _hasMoreSearch = more.length >= pageSize;
      notifyListeners();
    } finally {
      _isLoadingMore = false;
    }
  }

  void resetLastSearch() {
    lastSearchState = null;
    lastSearchDistrict = null;
    lastSearchCaste = null;
    lastSearchEducation = null;
    lastSearchOccupation = null;
    lastSearchMinAge = null;
    lastSearchMaxAge = null;
    lastSearchMinHeight = null;
    lastSearchMaxHeight = null;
    lastSearchCastes = null;
    lastSearchEducations = null;
    lastSearchOccupations = null;
    lastSearchMaritalStatuses = null;
    lastSearchLanguages = null;
    lastSearchMinIncome = null;
    lastSearchMaxIncome = null;
    lastSearchOnlineNow = null;
    lastSearchRecentlyActive = null;
    lastSearchSortBy = null;
    lastSearchJoinedWithinDays = null;
    _searchResults = [];
    _searchPage = 0;
    _hasMoreSearch = true;
    _persistClearLastSearch();
    notifyListeners();
  }

  Future<void> _persistLastSearchToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastSearchState', lastSearchState ?? '');
      await prefs.setString('lastSearchDistrict', lastSearchDistrict ?? '');
      await prefs.setString('lastSearchCaste', lastSearchCaste ?? '');
      await prefs.setString('lastSearchEducation', lastSearchEducation ?? '');
      await prefs.setString('lastSearchOccupation', lastSearchOccupation ?? '');
      await prefs.setInt('lastSearchMinAge', lastSearchMinAge ?? -1);
      await prefs.setInt('lastSearchMaxAge', lastSearchMaxAge ?? -1);
      await prefs.setDouble('lastSearchMinHeight', lastSearchMinHeight ?? -1);
      await prefs.setDouble('lastSearchMaxHeight', lastSearchMaxHeight ?? -1);
      await prefs.setStringList('lastSearchCastes', lastSearchCastes ?? []);
      await prefs.setStringList(
        'lastSearchEducations',
        lastSearchEducations ?? [],
      );
      await prefs.setStringList(
        'lastSearchOccupations',
        lastSearchOccupations ?? [],
      );
      await prefs.setStringList(
        'lastSearchMaritalStatuses',
        lastSearchMaritalStatuses ?? [],
      );
      await prefs.setStringList(
        'lastSearchLanguages',
        lastSearchLanguages ?? [],
      );
      await prefs.setDouble('lastSearchMinIncome', lastSearchMinIncome ?? -1);
      await prefs.setDouble('lastSearchMaxIncome', lastSearchMaxIncome ?? -1);
      await prefs.setBool('lastSearchOnlineNow', lastSearchOnlineNow ?? false);
      await prefs.setBool(
        'lastSearchRecentlyActive',
        lastSearchRecentlyActive ?? false,
      );
      await prefs.setString('lastSearchSortBy', lastSearchSortBy ?? 'active');
    } catch (_) {}
  }

  Future<void> _restoreLastSearchFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String readStr(String k) => prefs.getString(k) ?? '';
      int readInt(String k) => prefs.getInt(k) ?? -1;
      double readDouble(String k) => prefs.getDouble(k) ?? -1;
      bool readBool(String k) => prefs.getBool(k) ?? false;
      lastSearchState = _emptyToNull(readStr('lastSearchState'));
      lastSearchDistrict = _emptyToNull(readStr('lastSearchDistrict'));
      lastSearchCaste = _emptyToNull(readStr('lastSearchCaste'));
      lastSearchEducation = _emptyToNull(readStr('lastSearchEducation'));
      lastSearchOccupation = _emptyToNull(readStr('lastSearchOccupation'));
      final minAge = readInt('lastSearchMinAge');
      final maxAge = readInt('lastSearchMaxAge');
      lastSearchMinAge = minAge < 0 ? null : minAge;
      lastSearchMaxAge = maxAge < 0 ? null : maxAge;
      final minH = readDouble('lastSearchMinHeight');
      final maxH = readDouble('lastSearchMaxHeight');
      lastSearchMinHeight = minH < 0 ? null : minH;
      lastSearchMaxHeight = maxH < 0 ? null : maxH;
      lastSearchCastes = prefs.getStringList('lastSearchCastes');
      lastSearchEducations = prefs.getStringList('lastSearchEducations');
      lastSearchOccupations = prefs.getStringList('lastSearchOccupations');
      lastSearchMaritalStatuses = prefs.getStringList(
        'lastSearchMaritalStatuses',
      );
      lastSearchLanguages = prefs.getStringList('lastSearchLanguages');
      final minInc = readDouble('lastSearchMinIncome');
      final maxInc = readDouble('lastSearchMaxIncome');
      lastSearchMinIncome = minInc < 0 ? null : minInc;
      lastSearchMaxIncome = maxInc < 0 ? null : maxInc;
      lastSearchOnlineNow = readBool('lastSearchOnlineNow');
      lastSearchRecentlyActive = readBool('lastSearchRecentlyActive');
      lastSearchSortBy = _emptyToNull(readStr('lastSearchSortBy')) ?? 'active';
    } catch (_) {}
  }

  Future<void> _persistClearLastSearch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastSearchState');
      await prefs.remove('lastSearchDistrict');
      await prefs.remove('lastSearchCaste');
      await prefs.remove('lastSearchEducation');
      await prefs.remove('lastSearchOccupation');
      await prefs.remove('lastSearchMinAge');
      await prefs.remove('lastSearchMaxAge');
      await prefs.remove('lastSearchMinHeight');
      await prefs.remove('lastSearchMaxHeight');
      await prefs.remove('lastSearchCastes');
      await prefs.remove('lastSearchEducations');
      await prefs.remove('lastSearchOccupations');
      await prefs.remove('lastSearchMaritalStatuses');
      await prefs.remove('lastSearchLanguages');
      await prefs.remove('lastSearchMinIncome');
      await prefs.remove('lastSearchMaxIncome');
      await prefs.remove('lastSearchOnlineNow');
      await prefs.remove('lastSearchRecentlyActive');
      await prefs.remove('lastSearchSortBy');
    } catch (_) {}
  }

  String? _emptyToNull(String? v) => (v == null || v.isEmpty) ? null : v;

  // Send interest to a profile
  Future<void> sendInterest(String toProfileId) async {
    try {
      await _svc.sendInterest(toProfileId);
      // Optimistically mark as sent for UI disablement
      _sentInterestIds.add(toProfileId);
      // Optionally, ensure the sent list gets refreshed in background
      try {
        final authUserId = await sl.authService.currentUserId();
        if (authUserId != null) {
          // Fire and forget
          // ignore: unawaited_futures
          loadSentInterests(authUserId);
        }
      } catch (_) {}
      // Update local state if needed
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to send interest: $e');
    }
  }

  // Quick lookup for whether current user has already sent interest to profile
  bool isInterestSent(String profileId) {
    if (_sentInterestIds.contains(profileId)) return true;
    // Fallback to list in case set not yet hydrated
    return _sentInterests.any((p) => p.id == profileId);
  }

  // Accept interest from another profile
  Future<void> acceptInterest({
    required String fromProfileId,
    required String toAuthUserId,
  }) async {
    try {
      await _svc.updateInterestStatus(
        fromProfileId: fromProfileId,
        toProfileId: _currentUserProfile?.id ?? '',
        status: 'accepted',
      );
      await loadReceivedInterests(toAuthUserId);
      // Refresh matches in background to reflect potential new connection
      // ignore: unawaited_futures
      loadMatches(toAuthUserId);
      // Also refresh accepted connections in background
      // ignore: unawaited_futures
      loadAcceptedConnections(toAuthUserId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to accept interest: $e');
    }
  }

  // Reject interest from another profile
  Future<void> rejectInterest({
    required String fromProfileId,
    required String toAuthUserId,
  }) async {
    try {
      await _svc.updateInterestStatus(
        fromProfileId: fromProfileId,
        toProfileId: _currentUserProfile?.id ?? '',
        status: 'rejected',
      );
      await loadReceivedInterests(toAuthUserId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to reject interest: $e');
    }
  }

  // Check if a profile is shortlisted
  bool isProfileShortlisted(String profileId) {
    return _shortlistedByMe.any((p) => p.id == profileId);
  }

  // Toggle shortlist status
  Future<void> toggleShortlist(String profileId) async {
    try {
      await _svc.toggleShortlist(profileId);

      // Update local state
      final isShortlisted = _shortlistedByMe.any((p) => p.id == profileId);

      if (isShortlisted) {
        _shortlistedByMe.removeWhere((p) => p.id == profileId);
      } else {
        // Trigger a reload using the authenticated user's ID to keep in sync
        // Falls back to no-op if auth user not available
        try {
          // Lazy import to avoid tight coupling at top of file
          // ignore: avoid_dynamic_calls
          final authUserId = await sl.authService.currentUserId();
          if (authUserId != null) {
            await loadShortlistedProfiles(authUserId);
          }
        } catch (_) {}
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update shortlist: $e');
    }
  }

  // View a profile (track view)
  Future<void> viewProfile(String profileId, {MatrimonialUser? profile}) async {
    try {
      await _svc.viewProfile(profileId);
      // Optimistically update viewed list if profile provided
      if (profile != null) {
        final existingIndex = _viewedProfiles.indexWhere(
          (p) => p.id == profile.id,
        );
        if (existingIndex >= 0) {
          _viewedProfiles.removeAt(existingIndex);
        }
        _viewedProfiles.insert(0, profile);
      }
      // Update local state
      notifyListeners();
    } catch (e) {
      // Don't throw error for views as it's not critical
      debugPrint('Failed to track profile view: $e');
    }
  }

  // Block a profile
  Future<void> blockProfile(String profileId, String reason) async {
    try {
      await _svc.blockProfile(profileId, reason);

      // Remove from all local lists
      _allProfiles.removeWhere((p) => p.id == profileId);
      _matchedProfiles.removeWhere((p) => p.id == profileId);
      _receivedInterests.removeWhere((p) => p.id == profileId);
      _shortlistedProfiles.removeWhere((p) => p.id == profileId);
      _shortlistedByMe.removeWhere((p) => p.id == profileId);
      _viewedProfiles.removeWhere((p) => p.id == profileId);
      _searchResults.removeWhere((p) => p.id == profileId);

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to block profile: $e');
    }
  }

  // Create or update matrimonial profile
  Future<void> saveUserProfile(
    MatrimonialUser profile, {
    bool saveContact = false,
    bool saveFamily = false,
    bool savePartner = false,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      final withCompletion = profile.copyWith(
        isProfileComplete: isMandatoryComplete(profile),
      );

      await _svc.saveProfile(
        withCompletion,
        saveContact: saveContact,
        saveFamily: saveFamily,
        savePartner: savePartner,
      );
      _currentUserProfile = withCompletion;
      // Immediately notify listeners so parent widgets (e.g., ProfileCompletionGate)
      // can react to the updated profile and perform routing if the profile
      // became mandatory-complete. This avoids a timing window where the
      // registration screen unmounts but the parent hasn't yet rebuilt.
      notifyListeners();

      // If profile now has mandatory fields, refresh matches to reflect filters
      final authUserId = await sl.authService.currentUserId();
      if (authUserId != null && isMandatoryComplete(withCompletion)) {
        // Fire and forget; UI will rebuild on notifyListeners
        // Load matches for latest criteria and opposite gender
        // Don't await to keep saves snappy
        // ignore: unawaited_futures
        loadMatches(authUserId);
      }
      // Matches load will notify listeners upon completion
    } catch (e) {
      _setError('Failed to save profile: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Explicit refresher for matches (can be used by UI after updates)
  Future<void> refreshMatches() async {
    final authUserId = await sl.authService.currentUserId();
    if (authUserId != null) {
      await loadMatches(authUserId);
      // loadMatches already notifies on success
    }
  }

  // Compute compatibility score between current user and a candidate
  double _compatibilityScore(MatrimonialUser me, MatrimonialUser other) {
    double score = 0;
    bool eq(String a, String b) =>
        a.trim().toLowerCase() == b.trim().toLowerCase();
    // Caste match
    if (other.caste.isNotEmpty && eq(me.caste, other.caste)) score += 10;
    // District/State
    if (other.district.isNotEmpty && eq(me.district, other.district))
      score += 8;
    if (other.state.isNotEmpty && eq(me.state, other.state)) score += 6;
    // Education/Occupation
    if (other.education.isNotEmpty && eq(me.education, other.education))
      score += 4;
    if (other.occupation.isNotEmpty && eq(me.occupation, other.occupation))
      score += 2;
    // Age proximity (closer is better)
    final ageDiff = (me.age - other.age).abs();
    score += (10 - ageDiff).clamp(0, 10).toDouble();
    // Languages overlap
    final overlap = other.languages
        .where(
          (l) => me.languages
              .map((e) => e.toLowerCase().trim())
              .contains(l.toLowerCase().trim()),
        )
        .length;
    score += overlap * 1.0;
    // Recent activity bonus
    if (other.lastActiveAt != null) {
      final mins = DateTime.now().difference(other.lastActiveAt!).inMinutes;
      if (mins <= 10)
        score += 5;
      else if (mins <= 60)
        score += 3;
      else if (mins <= 24 * 60)
        score += 1;
    }
    return score;
  }

  // Get Top Picks ranked list from matched profiles without mutating state
  List<MatrimonialUser> getTopPicks({int limit = 10}) {
    final me = _currentUserProfile;
    if (me == null) return _matchedProfiles.take(limit).toList();
    final scored =
        _matchedProfiles
            .map((p) => MapEntry(p, _compatibilityScore(me, p)))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(limit).toList();
  }

  // Get profiles by filter criteria
  Future<void> loadProfilesByGenderAndCaste(String gender, String caste) async {
    try {
      _setLoading(true);
      _setError('');

      _allProfiles = await _svc.getProfilesByGenderAndCaste(gender, caste);
    } catch (e) {
      _setError('Failed to load profiles: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear all data
  void clearData() {
    _allProfiles.clear();
    _matchedProfiles.clear();
    _receivedInterests.clear();
    _sentInterests.clear();
    _shortlistedProfiles.clear();
    _viewedProfiles.clear();
    _searchResults.clear();
    _currentUserProfile = null;
    _error = '';
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUserData(String userId) async {
    await Future.wait([
      loadCurrentUserProfile(userId),
      loadMatches(userId),
      loadReceivedInterests(userId),
      loadShortlistedProfiles(userId),
      loadViewedProfiles(userId),
    ]);
    // Ensure realtime stays in sync after manual refresh
    await _subscribeToInterestRealtime(authUserId: userId);
  }

  // --- Realtime wiring for interests and connections ---
  Future<void> _subscribeToInterestRealtime({
    required String authUserId,
  }) async {
    // Must have current profile to know profile_id for filters
    final profileId = _currentUserProfile?.id;
    if (profileId == null || profileId.isEmpty) return;

    // If already subscribed for this profile, skip
    if (_interactionsChannel != null &&
        _interactionsSubscribedProfileId == profileId) {
      return;
    }

    // Tear down any previous channel
    _unsubscribeFromRealtime();

    final rt = _rt;
    // Subscribe via realtime service
    final handle = await rt.subscribeInterests(
      profileId,
      onInsertToMe: (row) async {
        try {
          if (row['interaction_type'] == 'interest') {
            await loadReceivedInterests(authUserId);
            _pendingRealtimeToast = 'You have a new interest';
            notifyListeners();
          }
        } catch (_) {}
      },
      onUpdateToMe: (row) async {
        try {
          if (row['interaction_type'] == 'interest') {
            await loadReceivedInterests(authUserId);
            if (row['status'] == 'accepted') {
              await loadAcceptedConnections(authUserId);
            }
            _pendingRealtimeToast = 'Interests updated';
            notifyListeners();
          }
        } catch (_) {}
      },
      onUpdateFromMe: (row) async {
        try {
          if (row['interaction_type'] == 'interest') {
            await loadSentInterests(authUserId);
            if (row['status'] == 'accepted') {
              await loadAcceptedConnections(authUserId);
              _pendingRealtimeToast = 'Your interest was accepted';
            }
            notifyListeners();
          }
        } catch (_) {}
      },
      onDeleteToMe: (row) async {
        try {
          await loadReceivedInterests(authUserId);
          _pendingRealtimeToast = 'An interest was withdrawn';
          notifyListeners();
        } catch (_) {}
      },
    );

    _interactionsChannel = handle;
    _interactionsSubscribedProfileId = profileId;

    // Lightweight polling fallback only for HTTP backend
    _interestsPoll?.cancel();
    final rtType = _rt.runtimeType.toString();
    final isHttpBackend = rtType.contains('HttpRealtimeService');
    if (isHttpBackend) {
      _interestsPoll = Timer.periodic(const Duration(seconds: 20), (_) async {
        try {
          await Future.wait([
            loadReceivedInterests(authUserId),
            loadAcceptedConnections(authUserId),
          ]);
        } catch (_) {}
      });
    }
  }

  void _unsubscribeFromRealtime() {
    if (_interactionsChannel != null) {
      try {
        _rt.unsubscribe(_interactionsChannel);
      } catch (_) {}
      _interactionsChannel = null;
      _interactionsSubscribedProfileId = null;
    }
    _interestsPoll?.cancel();
  }

  void _startPresenceHeartbeat() {
    final profileId = _currentUserProfile?.id;
    if (profileId == null || profileId.isEmpty) {
      _presenceHeartbeat?.cancel();
      return;
    }
    _presenceHeartbeat?.cancel();
    _presence.heartbeat(myProfileId: profileId);
    _presenceHeartbeat = Timer.periodic(const Duration(seconds: 60), (_) {
      _presence.heartbeat(myProfileId: profileId);
    });
  }
}
