import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../profile/widgets/profile_card_horizontal.dart';
import '../../shared/theme/constants.dart';
import '../../shared/services/matrimonial_service.dart';
import '../../shared/models/location_data.dart';
import '../../shared/models/caste_data.dart' as caste_model;
import '../../app/di/service_locator.dart';
import '../../shared/models/saved_search.dart';
import '../interests/requests_inbox_screen.dart';
import '../../shared/models/contact_request.dart';
import '../../shared/widgets/storage_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.initialStateName,
    this.initialDistrictName,
    this.initialCastes,
    this.initialSortBy,
    this.initialJoinedWithinDays,
    this.autoSearch = false,
  });

  final String? initialStateName;
  final String? initialDistrictName;
  final List<String>? initialCastes;
  final String?
  initialSortBy; // 'active' | 'newest' | 'ageAsc' | 'ageDesc' | 'incomeDesc'
  // If set, filters results to profiles created within the last N days
  final int? initialJoinedWithinDays;
  final bool autoSearch;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  MatrimonialProvider? _providerForListener;
  LocationData? _selectedState;
  LocationData? _selectedDistrict;
  caste_model.CasteData? _selectedCaste;
  String? _selectedEducation;
  String? _selectedOccupation;
  // New multi-selects and extras
  final List<caste_model.CasteData> _selectedCastes = [];
  final List<String> _selectedEducations = [];
  final List<String> _selectedOccupations = [];
  final List<String> _selectedMaritalStatuses = [];
  final List<String> _selectedLanguages = [];
  String? _city;
  String? _subCaste;
  RangeValues _ageRange = const RangeValues(21, 35);
  RangeValues _heightRange = const RangeValues(150, 180);
  RangeValues _incomeRange = const RangeValues(0, 50); // in LPA
  bool _onlineNow = false;
  bool _recentlyActive = false;
  String _sortBy = 'active';
  bool _isSearching = false;
  bool _loadingFilters = true;
  List<SavedSearch> _savedSearches = [];

  List<LocationData> _states = [];
  List<LocationData> _districts = [];
  List<caste_model.CasteData> _castes = [];
  List<String> _educations = [];
  List<String> _occupations = [];
  final List<String> _languages = const [
    'Tamil',
    'English',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Hindi',
  ];

  VoidCallback? _providerListener;
  bool _autoQuickSearchDone = false;
  // Simple flag to avoid bursting multiple searches when removing chips fast
  bool _chipActionInProgress = false;
  bool _hasSearched =
      false; // show results only after first search or quick search
  bool _initialApplied = false; // ensure deep-link filters apply only once
  int? _deepLinkJoinedWithinDays; // shows a read-only chip when deep-linked
  // Handshake status cache (profileId -> status)
  final Map<String, ContactHandshakeStatus> _handshakeStatus = {};
  final Set<String> _fetchingHandshake = {};

  @override
  void initState() {
    super.initState();
    // Load dynamic filters and set up listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cache provider instance for safe add/remove listener
      _providerForListener = context.read<MatrimonialProvider>();
      _initFilters();
      _setupProviderListener();
      _autoPopulateSearchResults();
      _loadSavedSearches();
      // If deep-linked with initial filters, apply them instead of restoring
      if ((widget.initialStateName != null ||
              (widget.initialCastes != null &&
                  widget.initialCastes!.isNotEmpty) ||
              widget.initialDistrictName != null ||
              widget.initialSortBy != null ||
              widget.initialJoinedWithinDays != null) &&
          !_initialApplied) {
        _applyInitialFiltersAndMaybeSearch();
      } else {
        _restoreLastSearch();
      }
    });
  }

  @override
  void dispose() {
    if (_providerListener != null) {
      try {
        _providerForListener?.removeListener(_providerListener!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _setupProviderListener() {
    final provider = context.read<MatrimonialProvider>();
    _providerListener = () {
      if (!mounted) return;
      final p = provider;
      // If matches have arrived and no search results yet, auto-populate once
      if (!_autoQuickSearchDone &&
          !_isSearching &&
          p.searchResults.isEmpty &&
          p.matchedProfiles.isNotEmpty) {
        // Defer to next frame to avoid setState during dispose or build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _autoQuickSearchDone = true;
          _performQuickSearch();
        });
      }
    };
    provider.addListener(_providerListener!);
  }

  Future<void> _initFilters() async {
    if (mounted) setState(() => _loadingFilters = true);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<MatrimonialProvider>();
    try {
      // Load states
      final states = await MatrimonialService.getStates();
      // Load castes for user's religion if available (read before awaits)
      final profileReligion = provider.currentUserProfile?.religion;
      final religion = profileReligion ?? 'Hindu';
      final castes = await MatrimonialService.getCastesByReligion(religion);
      final educations = await MatrimonialService.getEducations();
      final occupations = await MatrimonialService.getOccupations();

      if (!mounted) return;
      setState(() {
        _states = states;
        _castes = castes
            .map(
              (c) => caste_model.CasteData(
                id: c.id,
                name: c.name,
                religion: c.religion,
              ),
            )
            .toList();
        _educations = educations;
        _occupations = occupations;
        _loadingFilters = false;
      });
      // After filters are loaded, set initial filters if provided
      if ((widget.initialStateName != null ||
              widget.initialDistrictName != null ||
              (widget.initialCastes != null &&
                  widget.initialCastes!.isNotEmpty) ||
              widget.initialJoinedWithinDays != null) &&
          !_initialApplied) {
        await _applyInitialFiltersAndMaybeSearch();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingFilters = false);
      // Optionally inform the user; avoid context after awaits by using captured messenger where possible
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to load filters: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _applyInitialFiltersAndMaybeSearch() async {
    _initialApplied = true;
    // Apply initial state/district/castes and optional sort
    if (widget.initialStateName != null) {
      _selectedState = _states.firstWhere(
        (s) => s.name == widget.initialStateName,
        orElse: () => _states.isNotEmpty
            ? _states.first
            : _selectedState ?? LocationData(id: '', name: ''),
      );
      await _loadDistrictsForState(_selectedState);
    }
    if (widget.initialDistrictName != null) {
      _selectedDistrict = _districts.firstWhere(
        (d) => d.name == widget.initialDistrictName,
        orElse: () => _districts.isNotEmpty
            ? _districts.first
            : _selectedDistrict ?? LocationData(id: '', name: ''),
      );
    }
    if (widget.initialCastes != null && widget.initialCastes!.isNotEmpty) {
      _selectedCastes.clear();
      for (final name in widget.initialCastes!) {
        final found = _castes.firstWhere(
          (c) => c.name == name,
          orElse: () => caste_model.CasteData(id: '', name: name, religion: ''),
        );
        _selectedCastes.add(found);
      }
    }
    if (widget.initialSortBy != null) {
      _sortBy = widget.initialSortBy!;
    }
    // Capture deep-link 'joined within days' to show a read-only chip
    if (widget.initialJoinedWithinDays != null) {
      _deepLinkJoinedWithinDays = widget.initialJoinedWithinDays;
    }
    if (mounted) setState(() {});
    if (widget.autoSearch) {
      setState(() => _hasSearched = true);
      _performSearch(joinedWithinDays: widget.initialJoinedWithinDays);
    }
  }

  void _restoreLastSearch() {
    final p = context.read<MatrimonialProvider>();
    // Basic
    if (p.lastSearchState != null) {
      _selectedState = _states.firstWhere(
        (s) => s.name == p.lastSearchState,
        orElse: () =>
            _selectedState ??
            (_states.isNotEmpty
                ? _states.first
                : LocationData(id: '', name: '')),
      );
      _loadDistrictsForState(_selectedState);
    }
    if (p.lastSearchDistrict != null) {
      _selectedDistrict = _districts.firstWhere(
        (d) => d.name == p.lastSearchDistrict,
        orElse: () =>
            _selectedDistrict ??
            (_districts.isNotEmpty
                ? _districts.first
                : LocationData(id: '', name: '')),
      );
    }
    if (p.lastSearchCaste != null) {
      _selectedCaste = _castes.firstWhere(
        (c) => c.name == p.lastSearchCaste,
        orElse: () =>
            _selectedCaste ??
            (_castes.isNotEmpty
                ? _castes.first
                : caste_model.CasteData(id: '', name: '', religion: '')),
      );
    }
    _ageRange = RangeValues(
      (p.lastSearchMinAge ?? _ageRange.start.round()).toDouble(),
      (p.lastSearchMaxAge ?? _ageRange.end.round()).toDouble(),
    );
    if (p.lastSearchMinHeight != null || p.lastSearchMaxHeight != null) {
      _heightRange = RangeValues(
        (p.lastSearchMinHeight ?? _heightRange.start).toDouble(),
        (p.lastSearchMaxHeight ?? _heightRange.end).toDouble(),
      );
    }
    // Advanced
    if (p.lastSearchCastes != null && p.lastSearchCastes!.isNotEmpty) {
      for (final name in p.lastSearchCastes!) {
        final found = _castes.firstWhere(
          (c) => c.name == name,
          orElse: () => caste_model.CasteData(id: '', name: name, religion: ''),
        );
        _selectedCastes.add(found);
      }
    }
    if (p.lastSearchEducations != null) {
      _selectedEducations.addAll(p.lastSearchEducations!);
    }
    if (p.lastSearchOccupations != null) {
      _selectedOccupations.addAll(p.lastSearchOccupations!);
    }
    if (p.lastSearchMaritalStatuses != null) {
      _selectedMaritalStatuses.addAll(p.lastSearchMaritalStatuses!);
    }
    if (p.lastSearchLanguages != null) {
      _selectedLanguages.addAll(p.lastSearchLanguages!);
    }
    if (p.lastSearchMinIncome != null || p.lastSearchMaxIncome != null) {
      // assume LPA scale; convert from absolute to LPA if needed
      _incomeRange = RangeValues(
        (p.lastSearchMinIncome ?? 0) / 100000,
        (p.lastSearchMaxIncome ?? 50 * 100000) / 100000,
      );
    }
    _onlineNow = p.lastSearchOnlineNow ?? false;
    _recentlyActive = p.lastSearchRecentlyActive ?? false;
    _sortBy = p.lastSearchSortBy ?? 'active';
    if (mounted) setState(() {});
  }

  Future<void> _loadDistrictsForState(LocationData? state) async {
    if (state == null) {
      if (mounted) setState(() => _districts = []);
      return;
    }
    try {
      final districts = await MatrimonialService.getDistrictsByState(state.id);
      if (mounted) setState(() => _districts = districts);
    } catch (e) {
      if (mounted) setState(() => _districts = []);
    }
  }

  void _autoPopulateSearchResults() async {
    final matrimonialProvider = context.read<MatrimonialProvider>();

    // If no search results but there are matched profiles, perform a quick search
    if (!_autoQuickSearchDone &&
        matrimonialProvider.searchResults.isEmpty &&
        matrimonialProvider.matchedProfiles.isNotEmpty) {
      // debugPrint('[SearchScreen] Auto-populating results from matched profiles');
      _autoQuickSearchDone = true;
      _performQuickSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Profiles'),
        elevation: 0,
        backgroundColor: Colors.pink.shade50,
        actions: [
          IconButton(
            tooltip: 'Saved searches',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: _openSavedSearches,
          ),
          IconButton(
            tooltip: 'Contact requests',
            icon: const Icon(Icons.handshake_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RequestsInboxScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Filters
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.pink.shade50,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActiveFiltersBar(),
                      const SizedBox(height: 8),
                      _buildLocationFilters(),
                      const SizedBox(height: 16),
                      _buildBasicFilters(),
                      const SizedBox(height: 16),
                      _buildRangeFilters(),
                      const SizedBox(height: 20),
                      _buildSearchButton(),
                      const SizedBox(height: 8),
                      _buildSaveSearchButton(),
                      const SizedBox(height: 12),
                      _buildQuickSearchButton(),
                      const SizedBox(height: 8),
                      _buildResetButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Results (expand only after a search to improve filter usability)
          if (_hasSearched)
            Expanded(
              flex: 3,
              child: Consumer<MatrimonialProvider>(
                builder: (context, matrimonialProvider, child) {
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200 &&
                          !matrimonialProvider.isLoadingMore &&
                          matrimonialProvider.hasMoreSearch &&
                          !_isSearching) {
                        matrimonialProvider.loadMoreSearchResults();
                      }
                      return false;
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildSearchResultsFromProvider(
                            matrimonialProvider,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _isSearching ? null : _resetFilters,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Reset Filters'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Tip: Adjust filters and tap Search to see results here.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // State dropdown
            DropdownButtonFormField<LocationData>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
              items: _states
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedState = value;
                  _selectedDistrict = null; // Reset district when state changes
                });
                await _loadDistrictsForState(value);
              },
            ),

            const SizedBox(height: 12),

            // District dropdown
            DropdownButtonFormField<LocationData>(
              value: _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
              items: _districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrict = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Caste dropdown
            DropdownButtonFormField<caste_model.CasteData>(
              value: _selectedCaste,
              decoration: const InputDecoration(
                labelText: 'Caste',
                border: OutlineInputBorder(),
              ),
              items: _castes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCaste = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Sub-caste
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Sub-caste',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _subCaste = v.trim(),
            ),

            const SizedBox(height: 12),

            // Education dropdown
            DropdownButtonFormField<String>(
              value: _selectedEducation,
              decoration: const InputDecoration(
                labelText: 'Education',
                border: OutlineInputBorder(),
              ),
              items: _educations
                  .map(
                    (education) => DropdownMenuItem(
                      value: education,
                      child: Text(education),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEducation = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Occupation dropdown
            DropdownButtonFormField<String>(
              value: _selectedOccupation,
              decoration: const InputDecoration(
                labelText: 'Occupation',
                border: OutlineInputBorder(),
              ),
              items: _occupations
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOccupation = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // City
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _city = v.trim(),
            ),

            const SizedBox(height: 12),

            // Multi-select quick chips
            _chipsSelector<String>(
              label: 'More Educations',
              options: _educations,
              selected: _selectedEducations,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 8),
            _chipsSelector<String>(
              label: 'More Occupations',
              options: _occupations,
              selected: _selectedOccupations,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 8),
            _chipsSelector<String>(
              label: 'Marital Status',
              options: AppConstants.maritalStatuses,
              selected: _selectedMaritalStatuses,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 8),
            _chipsSelector<String>(
              label: 'Languages',
              options: _languages,
              selected: _selectedLanguages,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 8),
            _chipsSelector<caste_model.CasteData>(
              label: 'More Castes',
              options: _castes,
              selected: _selectedCastes,
              display: (c) => c.name,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Range Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Age range
            Text(
              'Age: ${_ageRange.start.round()} - ${_ageRange.end.round()} years',
            ),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 60,
              divisions: 42,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),

            const SizedBox(height: 12),

            // Height range
            Text(
              'Height: ${_heightRange.start.round()} - ${_heightRange.end.round()} cm',
            ),
            RangeSlider(
              values: _heightRange,
              min: 140,
              max: 200,
              divisions: 60,
              labels: RangeLabels(
                '${_heightRange.start.round()} cm',
                '${_heightRange.end.round()} cm',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _heightRange = values;
                });
              },
            ),

            const SizedBox(height: 12),

            // Income range (LPA)
            Text(
              'Income: ${_incomeRange.start.toStringAsFixed(1)}L - ${_incomeRange.end.toStringAsFixed(1)}L',
            ),
            RangeSlider(
              values: _incomeRange,
              min: 0,
              max: 50,
              divisions: 50,
              labels: RangeLabels(
                '${_incomeRange.start.toStringAsFixed(1)}L',
                '${_incomeRange.end.toStringAsFixed(1)}L',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _incomeRange = values;
                });
              },
            ),

            const SizedBox(height: 12),

            // Activity toggles & sort
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: _onlineNow,
                    onChanged: (v) => setState(() => _onlineNow = v ?? false),
                    title: const Text('Online now'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    value: _recentlyActive,
                    onChanged: (v) =>
                        setState(() => _recentlyActive = v ?? false),
                    title: const Text('Recently active'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort by',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'active',
                  child: Text('Recently active'),
                ),
                DropdownMenuItem(value: 'newest', child: Text('Newest')),
                DropdownMenuItem(value: 'ageAsc', child: Text('Younger first')),
                DropdownMenuItem(value: 'ageDesc', child: Text('Older first')),
                DropdownMenuItem(
                  value: 'incomeDesc',
                  child: Text('Higher income'),
                ),
              ],
              onChanged: (v) => setState(() => _sortBy = v ?? 'active'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSearching
            ? null
            : () {
                setState(() => _hasSearched = true);
                _performSearch();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSearching
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Search Profiles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildSaveSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isSearching ? null : _promptAndSaveCurrentSearch,
        icon: const Icon(Icons.bookmark_add_outlined),
        label: const Text('Save this Search'),
      ),
    );
  }

  Widget _buildQuickSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isSearching
            ? null
            : () {
                setState(() => _hasSearched = true);
                _performQuickSearch();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Quick Search (No Filters)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _isSearching ? null : _resetFilters,
        child: const Text('Reset Filters'),
      ),
    );
  }

  Widget _buildSearchResultsFromProvider(
    MatrimonialProvider matrimonialProvider,
  ) {
    final searchResults = matrimonialProvider.searchResults;
    final matchedProfiles = matrimonialProvider.matchedProfiles;
    // Use local flags; avoid depending on provider.isLoading here
    final isLoading = _isSearching || _loadingFilters;

    // Use search results if available, otherwise show matched profiles
    final profilesToShow = searchResults.isNotEmpty
        ? searchResults
        : matchedProfiles;
    final resultsSource = searchResults.isNotEmpty ? 'search' : 'matches';
    // debugPrint('[SearchScreen] results=$resultsSource count=${profilesToShow.length} loading=$isLoading');

    if (profilesToShow.isEmpty && !isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for profiles',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Use the filters above to find compatible matches',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pink),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${profilesToShow.length} profiles found${resultsSource == "matches" ? " (recommended)" : ""}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount:
                  profilesToShow.length +
                  (matrimonialProvider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= profilesToShow.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.pink,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }
                final profile = profilesToShow[index];
                final matrimonialProvider = context.read<MatrimonialProvider>();

                // Resolve handshake status from cache or fetch
                String? statusLabel;
                Color? statusColor;
                final my = matrimonialProvider.currentUserProfile;
                final cached = _handshakeStatus[profile.id];
                if (cached != null) {
                  final mapped = _mapHandshakeToChip(cached);
                  if (mapped.$1.isNotEmpty) {
                    statusLabel = mapped.$1;
                    statusColor = mapped.$2;
                  }
                } else if (my != null &&
                    !_fetchingHandshake.contains(profile.id)) {
                  _fetchingHandshake.add(profile.id);
                  // Fire-and-forget; update cache when done
                  sl.contactExchangeService
                      .getStatus(my.id, profile.id)
                      .then((status) {
                        _handshakeStatus[profile.id] = status;
                      })
                      .catchError((_) {})
                      .whenComplete(() {
                        _fetchingHandshake.remove(profile.id);
                        if (mounted) setState(() {});
                      });
                }
                return ProfileCardHorizontal(
                  profile: profile,
                  onTap: () {
                    context.read<MatrimonialProvider>().viewProfile(
                      profile.id,
                      profile: profile,
                    );
                    _showProfileDetails(profile);
                  },
                  onInterest: () => _sendInterest(profile),
                  onShortlist: () => _toggleShortlist(profile),
                  isShortlisted: matrimonialProvider.isProfileShortlisted(
                    profile.id,
                  ),
                  isInterestSent: matrimonialProvider.isInterestSent(
                    profile.id,
                  ),
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Maps handshake status to a presentable chip (label, color)
  (String, Color) _mapHandshakeToChip(ContactHandshakeStatus s) {
    switch (s) {
      case ContactHandshakeStatus.accepted:
        return ('Contact available', AppColors.success);
      case ContactHandshakeStatus.sentPending:
        return ('Request sent', AppColors.accent);
      case ContactHandshakeStatus.receivedPending:
        return ('Request received', AppColors.warning);
      case ContactHandshakeStatus.declined:
        return ('Declined', AppColors.error);
      case ContactHandshakeStatus.cancelled:
        return ('Cancelled', Colors.grey);
      case ContactHandshakeStatus.none:
        return ('', Colors.transparent);
    }
  }

  Widget _buildActiveFiltersBar() {
    final chips = <Widget>[];
    void addChip(String label, VoidCallback onClear) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Chip(
            label: Text(label),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () {
              if (_chipActionInProgress) return;
              _chipActionInProgress = true;
              onClear();
              if (mounted) setState(() {});
              // Trigger a fresh search after clearing a filter
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _performSearch();
                _chipActionInProgress = false;
              });
            },
          ),
        ),
      );
    }

    // State/District
    if (_selectedState != null) {
      addChip('State: ${_selectedState!.name}', () => _selectedState = null);
    }
    if (_selectedDistrict != null) {
      addChip(
        'District: ${_selectedDistrict!.name}',
        () => _selectedDistrict = null,
      );
    }
    // Caste & sub-caste
    if (_selectedCaste != null) {
      addChip('Caste: ${_selectedCaste!.name}', () => _selectedCaste = null);
    }
    if (_selectedCastes.isNotEmpty) {
      for (final c in List.of(_selectedCastes)) {
        addChip('Caste: ${c.name}', () => _selectedCastes.remove(c));
      }
    }
    if (_subCaste != null && _subCaste!.isNotEmpty) {
      addChip('Sub-caste: $_subCaste', () => _subCaste = null);
    }
    // Education/Occupation
    if (_selectedEducation != null) {
      addChip('Edu: $_selectedEducation', () => _selectedEducation = null);
    }
    for (final e in List.of(_selectedEducations)) {
      addChip('Edu: $e', () => _selectedEducations.remove(e));
    }
    if (_selectedOccupation != null) {
      addChip('Occ: $_selectedOccupation', () => _selectedOccupation = null);
    }
    for (final o in List.of(_selectedOccupations)) {
      addChip('Occ: $o', () => _selectedOccupations.remove(o));
    }
    // Marital status & languages
    for (final m in List.of(_selectedMaritalStatuses)) {
      addChip('Status: $m', () => _selectedMaritalStatuses.remove(m));
    }
    for (final l in List.of(_selectedLanguages)) {
      addChip('Lang: $l', () => _selectedLanguages.remove(l));
    }
    // City
    if (_city != null && _city!.isNotEmpty) {
      addChip('City: $_city', () => _city = null);
    }
    // Ranges if not default
    if (!(_ageRange.start == 21 && _ageRange.end == 35)) {
      addChip('Age ${_ageRange.start.round()}-${_ageRange.end.round()}', () {
        _ageRange = const RangeValues(21, 35);
      });
    }
    if (!(_heightRange.start == 150 && _heightRange.end == 180)) {
      addChip(
        'Ht ${_heightRange.start.round()}-${_heightRange.end.round()}cm',
        () {
          _heightRange = const RangeValues(150, 180);
        },
      );
    }
    if (!(_incomeRange.start == 0 && _incomeRange.end == 50)) {
      addChip(
        'Income ${_incomeRange.start.toStringAsFixed(0)}-${_incomeRange.end.toStringAsFixed(0)}L',
        () {
          _incomeRange = const RangeValues(0, 50);
        },
      );
    }
    // Activity
    if (_onlineNow) {
      addChip('Online now', () => _onlineNow = false);
    }
    if (_recentlyActive) {
      addChip('Recent', () => _recentlyActive = false);
    }

    // Toggleable deep-link chip for 'Joined within N days' (7/14/30)
    if (_deepLinkJoinedWithinDays != null) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: PopupMenuButton<int>(
            tooltip: 'Joined within days',
            onSelected: (v) {
              setState(() {
                _deepLinkJoinedWithinDays = v;
                _hasSearched = true;
              });
              _performSearch(joinedWithinDays: v);
            },
            itemBuilder: (context) {
              const options = [7, 14, 30];
              return options
                  .map(
                    (d) => PopupMenuItem<int>(
                      value: d,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_deepLinkJoinedWithinDays == d)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.check, size: 16),
                            ),
                          Text('Joined: $d days'),
                        ],
                      ),
                    ),
                  )
                  .toList();
            },
            child: Chip(label: Text('Joined: $_deepLinkJoinedWithinDays days')),
          ),
        ),
      );
    }

    // Clear all
    if (chips.isNotEmpty) {
      chips.add(
        TextButton(
          onPressed: _isSearching ? null : _resetFilters,
          child: const Text('Clear all'),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(children: chips),
    );
  }

  void _performSearch({int? joinedWithinDays}) async {
    // debugPrint('[SearchScreen] starting search');
    if (mounted) {
      setState(() {
        _isSearching = true;
        _handshakeStatus.clear();
        _fetchingHandshake.clear();
      });
    }
    final messenger = ScaffoldMessenger.of(context);
    final matrimonialProvider = context.read<MatrimonialProvider>();
    final authProvider = context.read<AuthProvider>();
    try {
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // debugPrint('Search params: state=${_selectedState?.name} district=${_selectedDistrict?.name} caste=${_selectedCaste?.name}');

      await matrimonialProvider.searchProfiles(
        state: _selectedState?.name,
        district: _selectedDistrict?.name,
        caste: _selectedCaste?.name,
        castes: _selectedCastes.map((e) => e.name).toList(),
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
        education: _selectedEducation,
        occupation: _selectedOccupation,
        educations: _selectedEducations,
        occupations: _selectedOccupations,
        maritalStatuses: _selectedMaritalStatuses,
        languages: _selectedLanguages,
        minHeight: _heightRange.start,
        maxHeight: _heightRange.end,
        minIncome: _incomeRange.start * 100000,
        maxIncome: _incomeRange.end * 100000,
        joinedWithinDays: joinedWithinDays,
        onlineNow: _onlineNow,
        recentlyActive: _recentlyActive,
        sortBy: _sortBy,
        city: _city,
        subCaste: _subCaste,
        page: 0,
        pageSize: 20,
      );

      // debugPrint('[SearchScreen] search complete: ${matrimonialProvider.searchResults.length}');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      // debugPrint('[SearchScreen] search failed: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
      // Use captured messenger to avoid context-after-await
      messenger.showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performQuickSearch() async {
    // debugPrint('[SearchScreen] quick search');
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isSearching = true;
        _handshakeStatus.clear();
        _fetchingHandshake.clear();
      });
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final matrimonialProvider = context.read<MatrimonialProvider>();
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Search with no filters - should return all opposite gender profiles
      await matrimonialProvider.searchProfiles(page: 0, pageSize: 20);

      // debugPrint('[SearchScreen] quick search complete: ${matrimonialProvider.searchResults.length}');

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _isSearching = false;
          });
        });
      }
    } catch (e) {
      // debugPrint('[SearchScreen] quick search failed: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _isSearching = false;
          });
        });
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Quick search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetFilters() {
    final provider = context.read<MatrimonialProvider>();
    provider.resetLastSearch();
    setState(() {
      _hasSearched = false;
      _deepLinkJoinedWithinDays = null;
      _selectedState = null;
      _selectedDistrict = null;
      _selectedCaste = null;
      _selectedCastes.clear();
      _selectedEducation = null;
      _selectedOccupation = null;
      _selectedEducations.clear();
      _selectedOccupations.clear();
      _selectedMaritalStatuses.clear();
      _selectedLanguages.clear();
      _city = null;
      _subCaste = null;
      _ageRange = const RangeValues(21, 35);
      _heightRange = const RangeValues(150, 180);
      _incomeRange = const RangeValues(0, 50);
      _onlineNow = false;
      _recentlyActive = false;
      _sortBy = 'active';
    });
  }

  Future<void> _loadSavedSearches() async {
    try {
      final my = context.read<MatrimonialProvider>().currentUserProfile;
      if (my == null) return;
      final list = await sl.savedSearchService.list(my.id);
      if (!mounted) return;
      setState(() => _savedSearches = list);
    } catch (_) {}
  }

  Future<void> _promptAndSaveCurrentSearch() async {
    final my = context.read<MatrimonialProvider>().currentUserProfile;
    if (my == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete registration first.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save this search'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Chennai IT, 25-30, Hindu',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final name = nameController.text.trim().isEmpty
        ? 'Search ${DateTime.now().toLocal().toIso8601String().substring(0, 16)}'
        : nameController.text.trim();
    final filter = _currentFilterAsJson();
    try {
      final created = await sl.savedSearchService.create(my.id, name, filter);
      if (!mounted) return;
      setState(() => _savedSearches = [created, ..._savedSearches]);
      messenger.showSnackBar(
        SnackBar(content: Text('Saved search "${created.name}"')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save search: $e')),
      );
    }
  }

  Map<String, dynamic> _currentFilterAsJson() {
    return {
      'state': _selectedState?.name,
      'district': _selectedDistrict?.name,
      'caste': _selectedCaste?.name,
      'castes': _selectedCastes.map((e) => e.name).toList(),
      'sub_caste': _subCaste,
      'city': _city,
      'min_age': _ageRange.start.round(),
      'max_age': _ageRange.end.round(),
      'education': _selectedEducation,
      'occupation': _selectedOccupation,
      'educations': _selectedEducations,
      'occupations': _selectedOccupations,
      'marital_statuses': _selectedMaritalStatuses,
      'languages': _selectedLanguages,
      'min_height_cm': _heightRange.start.round(),
      'max_height_cm': _heightRange.end.round(),
      'min_income': _incomeRange.start * 100000,
      'max_income': _incomeRange.end * 100000,
      'online_now': _onlineNow,
      'recently_active': _recentlyActive,
      'sort': _sortBy,
    }..removeWhere(
      (key, value) =>
          value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty),
    );
  }

  void _openSavedSearches() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.bookmarks_outlined),
                title: Text('Saved searches'),
              ),
              if (_savedSearches.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No saved searches yet.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _savedSearches.length,
                    itemBuilder: (context, index) {
                      final s = _savedSearches[index];
                      return Dismissible(
                        key: ValueKey(s.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete saved search?'),
                              content: Text('"${s.name}" will be removed.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          return ok == true;
                        },
                        onDismissed: (_) async {
                          final my = context
                              .read<MatrimonialProvider>()
                              .currentUserProfile;
                          if (my == null) return;
                          await sl.savedSearchService.delete(my.id, s.id);
                          if (!mounted) return;
                          setState(() => _savedSearches.removeAt(index));
                        },
                        child: SwitchListTile(
                          title: Text(s.name),
                          subtitle: Text(
                            'Alerts: ${s.alertEnabled ? 'On' : 'Off'} • ${s.createdAt.toLocal().toString().substring(0, 16)}',
                          ),
                          value: s.alertEnabled,
                          onChanged: (v) async {
                            final my = context
                                .read<MatrimonialProvider>()
                                .currentUserProfile;
                            if (my == null) return;
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              final updated = await sl.savedSearchService
                                  .toggleAlert(my.id, s.id, v);
                              if (!mounted) return;
                              setState(() => _savedSearches[index] = updated);
                            } catch (e) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                SnackBar(content: Text('Failed to toggle: $e')),
                              );
                            }
                          },
                          secondary: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Run search',
                            onPressed: () {
                              Navigator.pop(context);
                              _applySavedFilterAndSearch(s);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _applySavedFilterAndSearch(SavedSearch s) {
    final f = s.filter;
    // Basic fields
    final stateName = f['state']?.toString();
    final districtName = f['district']?.toString();
    _selectedState = stateName == null
        ? null
        : _states.firstWhere(
            (e) => e.name == stateName,
            orElse: () => _states.isNotEmpty
                ? _states.first
                : LocationData(id: '', name: stateName),
          );
    _selectedDistrict = districtName == null
        ? null
        : _districts.firstWhere(
            (e) => e.name == districtName,
            orElse: () => _districts.isNotEmpty
                ? _districts.first
                : LocationData(id: '', name: districtName),
          );
    final casteName = f['caste']?.toString();
    _selectedCaste = casteName == null
        ? null
        : _castes.firstWhere(
            (e) => e.name == casteName,
            orElse: () =>
                caste_model.CasteData(id: '', name: casteName, religion: ''),
          );
    _selectedCastes
      ..clear()
      ..addAll(
        ((f['castes'] as List?) ?? const <dynamic>[])
            .map((e) => e.toString())
            .map(
              (name) => _castes.firstWhere(
                (c) => c.name == name,
                orElse: () =>
                    caste_model.CasteData(id: '', name: name, religion: ''),
              ),
            ),
      );
    _subCaste = f['sub_caste']?.toString();
    _city = f['city']?.toString();
    _selectedEducation = f['education']?.toString();
    _selectedOccupation = f['occupation']?.toString();
    _selectedEducations
      ..clear()
      ..addAll(
        ((f['educations'] as List?) ?? const <dynamic>[]).map(
          (e) => e.toString(),
        ),
      );
    _selectedOccupations
      ..clear()
      ..addAll(
        ((f['occupations'] as List?) ?? const <dynamic>[]).map(
          (e) => e.toString(),
        ),
      );
    _selectedMaritalStatuses
      ..clear()
      ..addAll(
        ((f['marital_statuses'] as List?) ?? const <dynamic>[]).map(
          (e) => e.toString(),
        ),
      );
    _selectedLanguages
      ..clear()
      ..addAll(
        ((f['languages'] as List?) ?? const <dynamic>[]).map(
          (e) => e.toString(),
        ),
      );
    _ageRange = RangeValues(
      ((f['min_age'] as num?) ?? 21).toDouble(),
      ((f['max_age'] as num?) ?? 35).toDouble(),
    );
    _heightRange = RangeValues(
      ((f['min_height_cm'] as num?) ?? 150).toDouble(),
      ((f['max_height_cm'] as num?) ?? 180).toDouble(),
    );
    _incomeRange = RangeValues(
      (((f['min_income'] as num?) ?? 0) / 100000).toDouble(),
      (((f['max_income'] as num?) ?? 5000000) / 100000).toDouble(),
    );
    _onlineNow = (f['online_now'] as bool?) ?? false;
    _recentlyActive = (f['recently_active'] as bool?) ?? false;
    _sortBy = f['sort']?.toString() ?? 'active';
    setState(() {
      _hasSearched = true;
    });
    _performSearch();
  }

  void _showProfileDetails(MatrimonialUser profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child:
                              (profile.profileImageUrl != null &&
                                  profile.profileImageUrl!.isNotEmpty)
                              ? StorageImage(
                                  src: profile.profileImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: Center(
                                    child: Text(
                                      profile.name.isNotEmpty
                                          ? profile.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  emptyWidget: Center(
                                    child: Text(
                                      profile.name.isNotEmpty
                                          ? profile.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    profile.name.isNotEmpty
                                        ? profile.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${profile.age} years • ${profile.city}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (profile.isVerified)
                            const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Profile details
                _buildDetailSection(
                  'About',
                  profile.aboutMe ?? 'No information provided',
                ),
                _buildDetailSection('Education', profile.education),
                _buildDetailSection('Occupation', profile.occupation),
                _buildDetailSection(
                  'Location',
                  '${profile.city}, ${profile.district}',
                ),
                _buildDetailSection('Caste', profile.caste),
                _buildDetailSection(
                  'Height',
                  '${profile.height?.round() ?? 'Not specified'} cm',
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendInterest(profile),
                        icon: const Icon(Icons.favorite_border),
                        label: const Text('Send Interest'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addToShortlist(profile),
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text('Shortlist'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.pink,
                          side: const BorderSide(color: Colors.pink),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 15)),
          const Divider(),
        ],
      ),
    );
  }

  void _sendInterest(MatrimonialUser profile) {
    final provider = context.read<MatrimonialProvider>();
    provider
        .sendInterest(profile.id)
        .then((_) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Interest sent to ${profile.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send interest: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  void _addToShortlist(MatrimonialUser profile) {
    final provider = context.read<MatrimonialProvider>();
    final was = provider.isProfileShortlisted(profile.id);
    provider
        .toggleShortlist(profile.id)
        .then((_) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  was ? 'Removed from shortlist' : 'Added to shortlist',
                ),
                backgroundColor: Colors.blue,
              ),
            );
          }
        })
        .catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update shortlist: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  void _toggleShortlist(MatrimonialUser profile) {
    final matrimonialProvider = context.read<MatrimonialProvider>();
    final wasShortlisted = matrimonialProvider.isProfileShortlisted(profile.id);

    matrimonialProvider
        .toggleShortlist(profile.id)
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  wasShortlisted
                      ? 'Removed from shortlist'
                      : 'Added to shortlist',
                ),
                backgroundColor: AppColors.accent,
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update shortlist: $error'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        });
  }
}

// Generic chips selector helper
Widget _chipsSelector<T>({
  required String label,
  required List<T> options,
  required List<T> selected,
  String Function(T)? display,
  VoidCallback? onChanged,
}) {
  String toText(T v) => display != null ? display(v) : v.toString();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSel = selected.contains(opt);
          return FilterChip(
            label: Text(toText(opt)),
            selected: isSel,
            onSelected: (v) {
              if (v) {
                selected.add(opt);
              } else {
                selected.remove(opt);
              }
              // Notify parent for setState so the chip reflects active selection
              onChanged?.call();
            },
          );
        }).toList(),
      ),
    ],
  );
}
