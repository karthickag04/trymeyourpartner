import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
import '../../l10n/option_labels.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../shared/models/matrimonial_user.dart';
import '../../shared/theme/constants.dart';
import '../../shared/services/matrimonial_service.dart';
import '../../shared/models/location_data.dart';
import '../../app/di/service_locator.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  // Auto-save management
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _suspendAutoSave = true; // start suspended until profile is ready
  bool _prefilledOnce = false;

  // Optional: separate keys for future fine-grained validation per section
  final _basicFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _familyFormKey = GlobalKey<FormState>();
  final _partnerFormKey = GlobalKey<FormState>();

  // Controllers for key fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  // Switched to DB-backed dropdowns
  String? _education;
  String? _occupation;
  final _aboutCtrl = TextEditingController();
  final _annualIncomeCtrl = TextEditingController();
  final _workingLocationCtrl = TextEditingController();

  String _gender = 'Male';
  DateTime? _dob;
  String? _religion;
  String? _caste;
  String? _state;
  String? _district;
  String _maritalStatus = 'Never Married';
  double? _heightCm;
  double? _weightKg;

  // Contact
  final _phoneCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _currentAddrCtrl = TextEditingController();
  final _permanentAddrCtrl = TextEditingController();
  bool _showPhone = false;
  bool _showAddress = false;

  // Family
  final _fatherNameCtrl = TextEditingController();
  final _fatherOccCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _motherOccCtrl = TextEditingController();
  final _brothersCtrl = TextEditingController();
  final _sistersCtrl = TextEditingController();
  String? _familyType;
  String? _familyValues;
  String? _familyStatus;
  final _familyDetailsCtrl = TextEditingController();

  // Partner Preferences
  int? _ppMinAge;
  int? _ppMaxAge;
  double? _ppMinHeight;
  double? _ppMaxHeight;
  final List<String> _ppPreferredStates = [];
  final List<String> _ppPreferredDistricts = [];
  final List<String> _ppPreferredCastes = [];
  final List<String> _ppPreferredEducation = [];
  final List<String> _ppPreferredOccupation = [];
  double? _ppMinIncome;
  double? _ppMaxIncome;
  final List<String> _ppPreferredMaritalStatus = [];
  final _ppOtherCtrl = TextEditingController();

  bool _saving = false;

  // DB-backed option lists
  List<LocationData> _stateOptions = [];
  List<LocationData> _districtOptions = [];
  List<String> _educationOptions = [];
  List<String> _occupationOptions = [];
  List<String> _casteOptions = [];
  final Map<String, String> _stateNameToId = {};

  // Tabs & editing states
  late TabController _tabController;
  int _currentIndex = 0;
  bool _editBasic = false;
  bool _editLocation = false;
  bool _editContact = false;
  bool _editFamily = false;
  bool _editPartner = false;
  bool _editPhotos = false;
  List<String> _photos = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_currentIndex != _tabController.index) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrefill());
    // Kick off background loads for dropdown options
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialOptions());

    // Setup auto-save listeners for text controllers
    _setupAutoSaveListeners();
  }

  void _maybePrefill() {
    if (!mounted) return;
    final provider = context.read<MatrimonialProvider>();
    if (provider.currentUserProfile != null && !_prefilledOnce) {
      _prefill();
    }
  }

  void _setupAutoSaveListeners() {
    debugPrint('🔧 Setting up auto-save listeners for all text controllers');

    // Basic info controllers
    _nameCtrl.addListener(() => _scheduleAutoSave('Basic Info'));
    _emailCtrl.addListener(() => _scheduleAutoSave('Basic Info'));
    _aboutCtrl.addListener(() => _scheduleAutoSave('Basic Info'));

    // Location & Career controllers
    _cityCtrl.addListener(() => _scheduleAutoSave('Location & Career'));
    // Education/Occupation now use dropdowns; autosave triggered on change handlers
    _workingLocationCtrl.addListener(
      () => _scheduleAutoSave('Location & Career'),
    );
    _annualIncomeCtrl.addListener(() => _scheduleAutoSave('Location & Career'));

    // Contact info controllers
    _phoneCtrl.addListener(() => _scheduleAutoSave('Contact Info'));
    _altPhoneCtrl.addListener(() => _scheduleAutoSave('Contact Info'));
    _whatsappCtrl.addListener(() => _scheduleAutoSave('Contact Info'));
    _currentAddrCtrl.addListener(() => _scheduleAutoSave('Contact Info'));
    _permanentAddrCtrl.addListener(() => _scheduleAutoSave('Contact Info'));

    // Family info controllers
    _fatherNameCtrl.addListener(() => _scheduleAutoSave('Family Info'));
    _fatherOccCtrl.addListener(() => _scheduleAutoSave('Family Info'));
    _motherNameCtrl.addListener(() => _scheduleAutoSave('Family Info'));
    _motherOccCtrl.addListener(() => _scheduleAutoSave('Family Info'));
    _brothersCtrl.addListener(() => _scheduleAutoSave('Family Info'));
    _sistersCtrl.addListener(() => _scheduleAutoSave('Family Info'));
    _familyDetailsCtrl.addListener(() => _scheduleAutoSave('Family Info'));

    // Partner preferences controller
    _ppOtherCtrl.addListener(() => _scheduleAutoSave('Partner Preferences'));
  }

  void _scheduleAutoSave(String section) {
    if (_suspendAutoSave) return; // don't autosave during prefill/init
    final provider = context.read<MatrimonialProvider>();
    if (provider.currentUserProfile == null) return; // profile not ready

    // Only auto-save when the corresponding section is in edit mode
    if (!_isSectionEditing(section)) return;

    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
      debugPrint(
        '🔄 Unsaved changes detected in $section, scheduling auto-save...',
      );
    }

    // Cancel existing timer
    _autoSaveTimer?.cancel();

    // Schedule new auto-save after 3 seconds of inactivity
    _autoSaveTimer = Timer(Duration(seconds: 3), () {
      debugPrint('⏰ Auto-save timer triggered for $section');
      _performAutoSave(section);
    });
  }

  bool _isSectionEditing(String section) {
    switch (section) {
      case 'Basic Info':
        return _editBasic;
      case 'Location & Career':
        return _editLocation;
      case 'Contact Info':
        return _editContact;
      case 'Family Info':
        return _editFamily;
      case 'Partner Preferences':
        return _editPartner;
      default:
        return false;
    }
  }

  void _performAutoSave(String section) async {
    if (!_hasUnsavedChanges || !mounted) return;
    final provider = context.read<MatrimonialProvider>();
    if (provider.currentUserProfile == null) return; // profile not ready yet

    debugPrint('💾 Performing auto-save for $section...');
    final auth = context.read<AuthProvider>();

    setState(() => _hasUnsavedChanges = false);

    try {
      switch (section) {
        case 'Basic Info':
          await _autoSaveBasicInfo(provider, auth);
          break;
        case 'Location & Career':
          await _autoSaveLocationCareer(provider, auth);
          break;
        case 'Contact Info':
          await _autoSaveContactInfo(provider, auth);
          break;
        case 'Family Info':
          await _autoSaveFamilyInfo(provider, auth);
          break;
        case 'Partner Preferences':
          await _autoSavePartnerPreferences(provider, auth);
          break;
      }
    } catch (e) {
      debugPrint('❌ Auto-save failed for $section: $e');
    }
  }

  void _prefill() {
    final provider = context.read<MatrimonialProvider>();
    final p = provider.currentUserProfile;
    if (p == null) return;
    _suspendAutoSave = true;
    _nameCtrl.text = p.name;
    _emailCtrl.text = context.read<AuthProvider>().userEmail ?? '';
    _cityCtrl.text = p.city;
    _education = p.education;
    _occupation = p.occupation;
    _aboutCtrl.text = p.aboutMe ?? '';
    _workingLocationCtrl.text = p.workingLocation;
    _annualIncomeCtrl.text = p.annualIncome?.toString() ?? '';
    _gender = p.gender;
    _dob = p.dateOfBirth;
    _religion = p.religion;
    _caste = p.caste;
    _state = p.state;
    _district = p.district;
    _maritalStatus = p.maritalStatus;
    _heightCm = p.height;
    _weightKg = p.weight;
    _photos = List<String>.from(p.photoUrls);

    // Contact
    _phoneCtrl.text = p.contactInfo.phoneNumber ?? '';
    _altPhoneCtrl.text = p.contactInfo.alternatePhoneNumber ?? '';
    _whatsappCtrl.text = p.contactInfo.whatsappNumber ?? '';
    _currentAddrCtrl.text = p.contactInfo.currentAddress ?? '';
    _permanentAddrCtrl.text = p.contactInfo.permanentAddress ?? '';
    _showPhone = p.contactInfo.showPhone;
    _showAddress = p.contactInfo.showAddress;

    // Family
    _fatherNameCtrl.text = p.familyInfo.fatherName ?? '';
    _fatherOccCtrl.text = p.familyInfo.fatherOccupation ?? '';
    _motherNameCtrl.text = p.familyInfo.motherName ?? '';
    _motherOccCtrl.text = p.familyInfo.motherOccupation ?? '';
    _brothersCtrl.text = (p.familyInfo.numberOfBrothers ?? 0).toString();
    _sistersCtrl.text = (p.familyInfo.numberOfSisters ?? 0).toString();
    _familyType = p.familyInfo.familyType;
    _familyValues = p.familyInfo.familyValues;
    _familyStatus = p.familyInfo.familyStatus;
    _familyDetailsCtrl.text = p.familyInfo.familyDetails ?? '';

    // Partner preferences
    final pp = p.partnerPreference;
    _ppMinAge = pp.minAge;
    _ppMaxAge = pp.maxAge;
    _ppMinHeight = pp.minHeight;
    _ppMaxHeight = pp.maxHeight;
    _ppPreferredStates
      ..clear()
      ..addAll(pp.preferredStates);
    _ppPreferredDistricts
      ..clear()
      ..addAll(pp.preferredDistricts);
    _ppPreferredCastes
      ..clear()
      ..addAll(pp.preferredCastes);
    _ppPreferredEducation
      ..clear()
      ..addAll(pp.preferredEducation);
    _ppPreferredOccupation
      ..clear()
      ..addAll(pp.preferredOccupation);
    _ppMinIncome = pp.minIncome;
    _ppMaxIncome = pp.maxIncome;
    _ppPreferredMaritalStatus
      ..clear()
      ..addAll(pp.preferredMaritalStatus);
    _ppOtherCtrl.text = pp.otherPreferences ?? '';
    setState(() {
      _prefilledOnce = true;
    });
    // After prefill, ensure dependent lists like districts/castes are loaded
    if (_state != null && _state!.isNotEmpty) {
      _loadDistrictsForState(_state!);
    }
    if (_religion != null && _religion!.isNotEmpty) {
      _loadCastesForReligion(_religion!);
    }
    // Re-enable autosave after fields are populated
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _suspendAutoSave = false;
    });
  }

  Future<void> _loadInitialOptions() async {
    try {
      final states = await MatrimonialService.getStates();
      final educations = await MatrimonialService.getEducations();
      final occupations = await MatrimonialService.getOccupations();
      if (!mounted) return;
      setState(() {
        _stateOptions = states;
        _educationOptions = educations.toSet().toList();
        _occupationOptions = occupations.toSet().toList();
        _stateNameToId
          ..clear()
          ..addEntries(states.map((s) => MapEntry(s.name, s.id)));
      });
      if (_state != null && _state!.isNotEmpty) {
        await _loadDistrictsForState(_state!);
      }
      if (_religion != null && _religion!.isNotEmpty) {
        await _loadCastesForReligion(_religion!);
      }
    } catch (e) {
      // Keep UI functional even if options fail to load
      debugPrint('❌ Failed to load initial options: $e');
    }
  }

  Future<void> _loadDistrictsForState(String stateName) async {
    final id = _stateNameToId[stateName];
    if (id == null) return;
    try {
      final districts = await MatrimonialService.getDistrictsByState(id);
      if (!mounted) return;
      setState(() {
        _districtOptions = districts;
        // Keep current selection if still valid, else clear
        if (_district != null &&
            !_districtOptions.any((d) => d.name == _district)) {
          _district = null;
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to load districts for $stateName: $e');
    }
  }

  Future<void> _loadCastesForReligion(String religion) async {
    try {
      final castes = await MatrimonialService.getCastesByReligion(religion);
      if (!mounted) return;
      setState(() {
        _casteOptions = castes.map((c) => c.name).toSet().toList();
        if (_caste != null && !_casteOptions.contains(_caste)) {
          _caste = null;
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to load castes for $religion: $e');
    }
  }

  @override
  void dispose() {
    // Cancel auto-save timer
    _autoSaveTimer?.cancel();

    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    // _education and _occupation now use dropdowns (no controllers to dispose)
    _aboutCtrl.dispose();
    _annualIncomeCtrl.dispose();
    _workingLocationCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _currentAddrCtrl.dispose();
    _permanentAddrCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherOccCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherOccCtrl.dispose();
    _brothersCtrl.dispose();
    _sistersCtrl.dispose();
    _familyDetailsCtrl.dispose();
    _ppOtherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatrimonialProvider>();
    final auth = context.watch<AuthProvider>();
    final ready = provider.currentUserProfile != null;
    // If profile becomes ready later, prefill once
    if (ready && !_prefilledOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.editProfileTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'deactivate') await _confirmDeactivate();
              if (v == 'delete') await _confirmDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'deactivate',
                child: Text(context.l10n.actionDeactivateProfile),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(context.l10n.actionDeleteProfile),
              ),
            ],
          ),
        ],
        backgroundColor: context.palette.primary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: context.l10n.editTabBasic),
            Tab(text: context.l10n.editTabLocationCareer),
            Tab(text: context.l10n.editTabContact),
            Tab(text: context.l10n.editTabFamily),
            Tab(text: context.l10n.editTabPartner),
            Tab(text: context.l10n.editTabPhotos),
          ],
        ),
      ),
      body: !ready
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(context.l10n.profileLoadingYours),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Basic
                _buildTabSection(
                  title: context.l10n.sectionBasicInfo,
                  isEditing: _editBasic,
                  onToggleEdit: () => setState(() => _editBasic = !_editBasic),
                  enableEdit: ready,
                  child: Form(
                    key: _basicFormKey,
                    child: Column(
                      children: [
                        _requirementBanner(),
                        _rowText(
                          context.l10n.fieldFullName,
                          _nameCtrl,
                          requiredField: true,
                        ),
                        _rowText(
                          context.l10n.authEmailLabel,
                          _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                          helperText: context.l10n.editEmailHelper,
                        ),
                        _rowDropdown(
                          context.l10n.fieldGender,
                          ['Male', 'Female'],
                          _gender,
                          (v) {
                            setState(() => _gender = v!);
                            _scheduleAutoSave('Basic Info');
                          },
                        ),
                        _rowDate(context.l10n.fieldDobRequired, _dob, (d) {
                          setState(() => _dob = d);
                          _scheduleAutoSave('Basic Info');
                        }),
                        _rowDropdown(
                          context.l10n.fieldReligionRequired,
                          AppConstants.religionCategories,
                          _religion,
                          (v) {
                            setState(() {
                              _religion = v;
                              _caste = null;
                            });
                            _loadCastesForReligion(v ?? '');
                            _scheduleAutoSave('Basic Info');
                          },
                        ),
                        _rowDropdown(
                          context.l10n.fieldCasteRequired,
                          _casteOptions,
                          _caste,
                          (v) {
                            setState(() => _caste = v);
                            _scheduleAutoSave('Basic Info');
                          },
                        ),
                        _rowDropdown(
                          context.l10n.fieldMaritalStatus,
                          AppConstants.maritalStatuses,
                          _maritalStatus,
                          (v) {
                            setState(() => _maritalStatus = v!);
                            _scheduleAutoSave('Basic Info');
                          },
                        ),
                        _rowText(
                          context.l10n.fieldAbout,
                          _aboutCtrl,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTabSection(
                  title: context.l10n.editSectionLocationCareer,
                  isEditing: _editLocation,
                  onToggleEdit: () =>
                      setState(() => _editLocation = !_editLocation),
                  enableEdit: ready,
                  child: Form(
                    key: _locationFormKey,
                    child: Column(
                      children: [
                        _requirementBanner(),
                        _rowDropdown(
                          context.l10n.fieldStateRequired,
                          _stateOptions.map((e) => e.name).toList(),
                          _state,
                          (v) {
                            setState(() {
                              _state = v;
                              _district = null;
                            });
                            if (v != null) _loadDistrictsForState(v);
                            _scheduleAutoSave('Location & Career');
                          },
                        ),
                        _rowDropdown(
                          context.l10n.fieldDistrictRequired,
                          _districtOptions.map((e) => e.name).toList(),
                          _district,
                          (v) {
                            setState(() => _district = v);
                            _scheduleAutoSave('Location & Career');
                          },
                        ),
                        _rowText(context.l10n.fieldCity, _cityCtrl),
                        _rowDropdown(
                          context.l10n.fieldEducationRequired,
                          _educationOptions,
                          _education,
                          (v) {
                            setState(() => _education = v);
                            _scheduleAutoSave('Location & Career');
                          },
                        ),
                        _rowDropdown(
                          context.l10n.fieldOccupation,
                          _occupationOptions,
                          _occupation,
                          (v) {
                            setState(() => _occupation = v);
                            _scheduleAutoSave('Location & Career');
                          },
                        ),
                        _rowText(
                          context.l10n.fieldWorkingLocation,
                          _workingLocationCtrl,
                        ),
                        _rowText(
                          context.l10n.fieldAnnualIncome,
                          _annualIncomeCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        _rowNumber(
                          context.l10n.fieldHeightCm,
                          initial: _heightCm,
                          onChanged: (v) => _heightCm = v,
                        ),
                        _rowNumber(
                          context.l10n.fieldWeightKg,
                          initial: _weightKg,
                          onChanged: (v) => _weightKg = v,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTabSection(
                  title: context.l10n.sectionContactInfo,
                  isEditing: _editContact,
                  onToggleEdit: () =>
                      setState(() => _editContact = !_editContact),
                  enableEdit: ready,
                  child: Form(
                    key: _contactFormKey,
                    child: Column(
                      children: [
                        _rowText(
                          context.l10n.fieldPhoneShort,
                          _phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        _rowText(
                          context.l10n.fieldAltPhone,
                          _altPhoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        _rowText(
                          context.l10n.helpWhatsapp,
                          _whatsappCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                        _rowText(
                          context.l10n.fieldCurrentAddress,
                          _currentAddrCtrl,
                          maxLines: 2,
                        ),
                        _rowText(
                          context.l10n.fieldPermanentAddress,
                          _permanentAddrCtrl,
                          maxLines: 2,
                        ),
                        SwitchListTile(
                          value: _showPhone,
                          onChanged: _editContact
                              ? (v) => setState(() => _showPhone = v)
                              : null,
                          title: Text(context.l10n.showPhoneNumber),
                        ),
                        SwitchListTile(
                          value: _showAddress,
                          onChanged: _editContact
                              ? (v) => setState(() => _showAddress = v)
                              : null,
                          title: Text(context.l10n.showAddress),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTabSection(
                  title: context.l10n.sectionFamilyInfo,
                  isEditing: _editFamily,
                  onToggleEdit: () =>
                      setState(() => _editFamily = !_editFamily),
                  enableEdit: ready,
                  child: Form(
                    key: _familyFormKey,
                    child: Column(
                      children: [
                        _rowText(context.l10n.fieldFatherName, _fatherNameCtrl),
                        _rowText(
                          context.l10n.fieldFatherOccupation,
                          _fatherOccCtrl,
                        ),
                        _rowText(context.l10n.fieldMotherName, _motherNameCtrl),
                        _rowText(
                          context.l10n.fieldMotherOccupation,
                          _motherOccCtrl,
                        ),
                        _rowText(
                          context.l10n.fieldBrothers,
                          _brothersCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        _rowText(
                          context.l10n.fieldSisters,
                          _sistersCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        _rowDropdown(
                          context.l10n.fieldFamilyType,
                          [
                            context.l10n.familyNuclear,
                            context.l10n.familyJoint,
                          ],
                          _familyType,
                          (v) => setState(() => _familyType = v),
                        ),
                        _rowDropdown(
                          context.l10n.fieldFamilyValues,
                          [
                            context.l10n.valuesTraditional,
                            context.l10n.valuesModern,
                            context.l10n.valuesModerate,
                          ],
                          _familyValues,
                          (v) => setState(() => _familyValues = v),
                        ),
                        _rowDropdown(
                          context.l10n.fieldFamilyStatus,
                          ['Middle Class', 'Upper Middle Class', 'Rich'],
                          _familyStatus,
                          (v) => setState(() => _familyStatus = v),
                        ),
                        _rowText(
                          context.l10n.fieldFamilyDetails,
                          _familyDetailsCtrl,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildTabSection(
                  title: context.l10n.sectionPartnerPreferences,
                  isEditing: _editPartner,
                  onToggleEdit: () =>
                      setState(() => _editPartner = !_editPartner),
                  enableEdit: ready,
                  child: Form(
                    key: _partnerFormKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _rowNumber(
                                context.l10n.fieldMinAge,
                                initial: _ppMinAge?.toDouble(),
                                onChanged: (v) => _ppMinAge = v?.round(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _rowNumber(
                                context.l10n.fieldMaxAge,
                                initial: _ppMaxAge?.toDouble(),
                                onChanged: (v) => _ppMaxAge = v?.round(),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _rowNumber(
                                context.l10n.fieldMinHeight,
                                initial: _ppMinHeight,
                                onChanged: (v) => _ppMinHeight = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _rowNumber(
                                context.l10n.fieldMaxHeight,
                                initial: _ppMaxHeight,
                                onChanged: (v) => _ppMaxHeight = v,
                              ),
                            ),
                          ],
                        ),
                        _chipsInput(
                          context.l10n.fieldPreferredStates,
                          _ppPreferredStates,
                        ),
                        _chipsInput(
                          context.l10n.fieldPreferredDistricts,
                          _ppPreferredDistricts,
                        ),
                        _chipsInput(
                          context.l10n.fieldPreferredCastes,
                          _ppPreferredCastes,
                        ),
                        _chipsInput(
                          context.l10n.fieldPreferredEducation,
                          _ppPreferredEducation,
                        ),
                        _chipsInput(
                          context.l10n.fieldPreferredOccupations,
                          _ppPreferredOccupation,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _rowNumber(
                                context.l10n.fieldMinIncome,
                                initial: _ppMinIncome,
                                onChanged: (v) => _ppMinIncome = v,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _rowNumber(
                                context.l10n.fieldMaxIncome,
                                initial: _ppMaxIncome,
                                onChanged: (v) => _ppMaxIncome = v,
                              ),
                            ),
                          ],
                        ),
                        _multiSelect(
                          context.l10n.fieldPreferredMaritalStatus,
                          AppConstants.maritalStatuses,
                          _ppPreferredMaritalStatus,
                        ),
                        _rowText(
                          context.l10n.fieldOtherPreferences,
                          _ppOtherCtrl,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Photos
                _buildTabSection(
                  title: context.l10n.profilePhotosTitle,
                  isEditing: _editPhotos,
                  onToggleEdit: () =>
                      setState(() => _editPhotos = !_editPhotos),
                  enableEdit: ready,
                  child: _buildPhotosGrid(context),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: _currentIndex == 0
                  ? null
                  : () {
                      _tabController.animateTo(_currentIndex - 1);
                    },
              icon: const Icon(Icons.chevron_left),
              label: Text(context.l10n.actionPrevious),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isEditingFor(_currentIndex) && !_saving
                  ? () => _saveCurrentSection(provider, auth)
                  : null,
              icon: _saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.palette.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(context.l10n.commonSave),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.accent,
                foregroundColor: context.palette.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                final last = _tabController.length - 1;
                if (_currentIndex < last) {
                  _tabController.animateTo(_currentIndex + 1);
                } else {
                  // On finish, ensure mandatory fields are filled; if not, keep user here
                  if (_isMandatoryFilled()) {
                    Navigator.pop(context);
                    // Optionally inform completion
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.profileSavedLoadingMatches),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // ignore: unawaited_futures
                    context.read<MatrimonialProvider>().refreshMatches();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.fillMandatoryFields),
                        backgroundColor: context.palette.warning,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                _currentIndex == _tabController.length - 1
                    ? Icons.check
                    : Icons.chevron_right,
              ),
              label: Text(
                _currentIndex == _tabController.length - 1
                    ? context.l10n.actionFinish
                    : context.l10n.actionNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeactivate() async {
    if (!mounted) return;
    final provider = context.read<MatrimonialProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final profile = provider.currentUserProfile;
    if (profile == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileNotLoaded),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.actionDeactivateProfile),
        content: Text(context.l10n.deactivateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionDeactivate),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final success = await MatrimonialService.deactivateProfile(profile.id);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileDeactivated),
            backgroundColor: context.palette.success,
          ),
        );
        // Refresh provider state and navigate back to main
        await provider.forceRefreshUserData(auth.user?.id ?? '');
        nav.pop();
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileDeactivateFailed),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (!mounted) return;
    final provider = context.read<MatrimonialProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final profile = provider.currentUserProfile;
    if (profile == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileNotLoaded),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.actionDeleteProfile),
        content: Text(context.l10n.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.error,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final success = await MatrimonialService.deleteProfile(profile.id);
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileDeleted),
            backgroundColor: context.palette.success,
          ),
        );
        // Sign out the user to clear session and navigate to login
        await auth.signOut();
        // Trigger provider cleanup
        provider.clearAllData();
        // Navigate to app root (pop until no more)
        nav.pushNamedAndRemoveUntil('/', (r) => false);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileDeleteFailed),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  // Deprecated: replaced by _buildSectionHeader with a Save button per section

  Widget _rowText(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
    int maxLines = 1,
    bool readOnly = false,
    String? helperText,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        validator: requiredField
            ? (v) => (v == null || v.trim().isEmpty)
                  ? context.l10n.fieldRequired(label)
                  : null
            : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _requirementBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.palette.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Text(context.l10n.mandatoryBanner, style: context.styles.caption),
    );
  }

  Widget _rowDropdown(
    String label,
    List<String> items,
    String? value,
    void Function(String?) onChanged,
  ) {
    // Ensure unique items while preserving order
    final seen = <String>{};
    final uniqueItems = <String>[];
    for (final e in items) {
      if (seen.add(e)) uniqueItems.add(e);
    }
    // Ensure DropdownButton gets a value that exists in items, else null
    final safeValue = (value != null && uniqueItems.contains(value))
        ? value
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: safeValue,
            items: uniqueItems
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(context.optionLabel(e)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _rowDate(
    String label,
    DateTime? value,
    void Function(DateTime) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(now.year - 60),
            lastDate: DateTime(now.year - 18),
            initialDate: value ?? DateTime(now.year - 25),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Text(
            value != null ? context.formatDate(value) : context.l10n.selectDate,
          ),
        ),
      ),
    );
  }

  Widget _rowNumber(
    String label, {
    double? initial,
    required void Function(double?) onChanged,
  }) {
    final ctrl = TextEditingController(text: initial?.toString() ?? '');
    return _rowText(
      label,
      ctrl,
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final d = double.tryParse(v);
        onChanged(d);
      },
    );
  }

  // _rowFreeText removed (switched to DB-backed dropdowns for required fields)

  Widget _chipsInput(String label, List<String> target) {
    final ctrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.styles.subtitle2),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in target)
                Chip(
                  label: Text(item),
                  onDeleted: () => setState(() => target.remove(item)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: context.l10n.chipsInputHint,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final val = ctrl.text.trim();
                  if (val.isNotEmpty) {
                    setState(() {
                      target.add(val);
                      ctrl.clear();
                    });
                  }
                },
                child: const Text('+'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _multiSelect(String label, List<String> options, List<String> target) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Wrap(
          spacing: 8,
          children: options.map((opt) {
            final selected = target.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    target.add(opt);
                  } else {
                    target.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // Removed old single-save method in favor of per-tab Save

  // Tab header with Edit toggle; content below becomes interactive when editing
  Widget _buildTabSection({
    required String title,
    required bool isEditing,
    required VoidCallback onToggleEdit,
    required Widget child,
    bool enableEdit = true,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.styles.heading3)),
              OutlinedButton.icon(
                onPressed: enableEdit ? onToggleEdit : null,
                icon: Icon(isEditing ? Icons.lock_open : Icons.edit, size: 18),
                label: Text(
                  isEditing ? context.l10n.commonDone : context.l10n.actionEdit,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.accent,
                  side: BorderSide(color: context.palette.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: !isEditing,
            child: Opacity(opacity: isEditing ? 1.0 : 0.8, child: child),
          ),
        ],
      ),
    );
  }

  // Helper to save only a section by merging updates into existing profile
  // Auto-save methods (silent saves without snackbars)
  Future<void> _autoSaveBasicInfo(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    debugPrint('💾 Auto-saving Basic Info...');
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          gender: _gender,
          dateOfBirth: _dob ?? existing.dateOfBirth,
          religion: _religion ?? existing.religion,
          caste: _caste ?? existing.caste,
          maritalStatus: _maritalStatus,
          aboutMe: _aboutCtrl.text.trim(),
        );
      },
      context.l10n.savedBasicAuto,
      showSnackbar: false,
      isAutoSave: true,
    );
  }

  Future<void> _autoSaveLocationCareer(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    debugPrint('💾 Auto-saving Location & Career...');
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          state: _state ?? existing.state,
          district: _district ?? existing.district,
          city: _cityCtrl.text.trim(),
          education: _education ?? existing.education,
          occupation: _occupation ?? existing.occupation,
          workingLocation: _workingLocationCtrl.text.trim().isEmpty
              ? existing.workingLocation
              : _workingLocationCtrl.text.trim(),
          annualIncome: double.tryParse(_annualIncomeCtrl.text),
          height: _heightCm,
          weight: _weightKg,
        );
      },
      context.l10n.savedLocationAuto,
      showSnackbar: false,
      isAutoSave: true,
    );
  }

  Future<void> _autoSaveContactInfo(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    debugPrint('💾 Auto-saving Contact Info...');
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          contactInfo: existing.contactInfo.copyWith(
            phoneNumber: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            alternatePhoneNumber: _altPhoneCtrl.text.trim().isEmpty
                ? null
                : _altPhoneCtrl.text.trim(),
            whatsappNumber: _whatsappCtrl.text.trim().isEmpty
                ? null
                : _whatsappCtrl.text.trim(),
            currentAddress: _currentAddrCtrl.text.trim().isEmpty
                ? null
                : _currentAddrCtrl.text.trim(),
            permanentAddress: _permanentAddrCtrl.text.trim().isEmpty
                ? null
                : _permanentAddrCtrl.text.trim(),
            showPhone: _showPhone,
            showAddress: _showAddress,
          ),
        );
      },
      context.l10n.savedContactAuto,
      showSnackbar: false,
      isAutoSave: true,
      saveContact: true,
    );
  }

  Future<void> _autoSaveFamilyInfo(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    debugPrint('💾 Auto-saving Family Info...');
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          familyInfo: existing.familyInfo.copyWith(
            fatherName: _fatherNameCtrl.text.trim().isEmpty
                ? null
                : _fatherNameCtrl.text.trim(),
            fatherOccupation: _fatherOccCtrl.text.trim().isEmpty
                ? null
                : _fatherOccCtrl.text.trim(),
            motherName: _motherNameCtrl.text.trim().isEmpty
                ? null
                : _motherNameCtrl.text.trim(),
            motherOccupation: _motherOccCtrl.text.trim().isEmpty
                ? null
                : _motherOccCtrl.text.trim(),
            numberOfBrothers: int.tryParse(_brothersCtrl.text) ?? 0,
            numberOfSisters: int.tryParse(_sistersCtrl.text) ?? 0,
            familyStatus: _familyStatus,
            familyDetails: _familyDetailsCtrl.text.trim().isEmpty
                ? null
                : _familyDetailsCtrl.text.trim(),
          ),
        );
      },
      context.l10n.savedFamilyAuto,
      showSnackbar: false,
      isAutoSave: true,
      saveFamily: true,
    );
  }

  Future<void> _autoSavePartnerPreferences(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    debugPrint('💾 Auto-saving Partner Preferences...');
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          partnerPreference: existing.partnerPreference.copyWith(
            minAge: _ppMinAge,
            maxAge: _ppMaxAge,
            minHeight: _ppMinHeight,
            maxHeight: _ppMaxHeight,
            preferredStates: _ppPreferredStates,
            preferredDistricts: _ppPreferredDistricts,
            preferredCastes: _ppPreferredCastes,
            preferredEducation: _ppPreferredEducation,
            preferredOccupation: _ppPreferredOccupation,
            preferredMaritalStatus: _ppPreferredMaritalStatus,
            otherPreferences: _ppOtherCtrl.text.trim().isEmpty
                ? null
                : _ppOtherCtrl.text.trim(),
          ),
        );
      },
      context.l10n.savedPartnerAuto,
      showSnackbar: false,
      isAutoSave: true,
      savePartner: true,
    );
  }

  Future<void> _saveSection(
    MatrimonialProvider provider,
    AuthProvider auth,
    MatrimonialUser Function(MatrimonialUser) updater,
    String successMessage, {
    bool showSnackbar = true,
    bool isAutoSave = false,
    bool saveContact = false,
    bool saveFamily = false,
    bool savePartner = false,
  }) async {
    setState(() => _saving = true);
    try {
      debugPrint(
        '💾 _saveSection: Starting ${isAutoSave ? "auto-save" : "manual save"} - $successMessage',
      );

      final existing = provider.currentUserProfile;
      if (existing == null) {
        // Profile isn't ready yet; avoid throwing noisy errors. Inform user on manual save.
        if (!isAutoSave && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.profileStillLoading),
              backgroundColor: context.palette.warning,
            ),
          );
        }
        return;
      }

      debugPrint('✅ _saveSection: Existing profile found - ${existing.name}');
      final updated = updater(existing);
      debugPrint(
        '🔄 _saveSection: Profile updated, calling saveUserProfile...',
      );

      await provider.saveUserProfile(
        updated,
        saveContact: saveContact,
        saveFamily: saveFamily,
        savePartner: savePartner,
      );
      debugPrint('✅ _saveSection: Profile saved successfully');

      if (!mounted) return;

      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAutoSave
                  ? context.l10n.autoSavedPrefix(successMessage)
                  : successMessage,
            ),
            backgroundColor: context.palette.success,
            duration: Duration(seconds: isAutoSave ? 2 : 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ _saveSection: Error - $e');
      if (!mounted) return;

      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAutoSave
                  ? context.l10n.autoSaveFailed
                  : context.l10n.saveFailed,
            ),
            backgroundColor: context.palette.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Per-section save methods
  Future<void> _saveBasicInfo(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    if (!(_basicFormKey.currentState?.validate() ?? true)) return;
    // Additional required checks
    if (_dob == null ||
        (_religion == null || _religion!.trim().isEmpty) ||
        (_caste == null || _caste!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.fillDobReligionCaste),
          backgroundColor: context.palette.warning,
        ),
      );
      return;
    }
    await _saveSection(provider, auth, (existing) {
      return existing.copyWith(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        gender: _gender,
        dateOfBirth: _dob ?? existing.dateOfBirth,
        religion: _religion ?? existing.religion,
        caste: _caste ?? existing.caste,
        maritalStatus: _maritalStatus,
        aboutMe: _aboutCtrl.text.trim(),
      );
    }, context.l10n.savedBasic);
    // If caste updated, refresh matches
    // ignore: unawaited_futures
    provider.refreshMatches();
    setState(() => _editBasic = false);
  }

  Future<void> _saveLocationCareer(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    if (!(_locationFormKey.currentState?.validate() ?? true)) return;
    await _saveSection(provider, auth, (existing) {
      return existing.copyWith(
        state: _state ?? existing.state,
        district: _district ?? existing.district,
        city: _cityCtrl.text.trim(),
        education: _education ?? existing.education,
        occupation: _occupation ?? existing.occupation,
        workingLocation: _workingLocationCtrl.text.trim().isEmpty
            ? existing.workingLocation
            : _workingLocationCtrl.text.trim(),
        annualIncome: double.tryParse(_annualIncomeCtrl.text),
        height: _heightCm,
        weight: _weightKg,
      );
    }, context.l10n.savedLocation);
    // Refresh matches if mandatory fields impacted
    // ignore: unawaited_futures
    provider.refreshMatches();
    setState(() => _editLocation = false);
  }

  Future<void> _saveContactInfo(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    if (!(_contactFormKey.currentState?.validate() ?? true)) return;
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          contactInfo: existing.contactInfo.copyWith(
            phoneNumber: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            alternatePhoneNumber: _altPhoneCtrl.text.trim().isEmpty
                ? null
                : _altPhoneCtrl.text.trim(),
            whatsappNumber: _whatsappCtrl.text.trim().isEmpty
                ? null
                : _whatsappCtrl.text.trim(),
            currentAddress: _currentAddrCtrl.text.trim().isEmpty
                ? null
                : _currentAddrCtrl.text.trim(),
            permanentAddress: _permanentAddrCtrl.text.trim().isEmpty
                ? null
                : _permanentAddrCtrl.text.trim(),
            showPhone: _showPhone,
            showAddress: _showAddress,
          ),
        );
      },
      context.l10n.savedContact,
      saveContact: true,
    );
    setState(() => _editContact = false);
  }

  Future<void> _saveFamilyInfo(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    if (!(_familyFormKey.currentState?.validate() ?? true)) return;
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          familyInfo: existing.familyInfo.copyWith(
            fatherName: _fatherNameCtrl.text.trim().isEmpty
                ? null
                : _fatherNameCtrl.text.trim(),
            fatherOccupation: _fatherOccCtrl.text.trim().isEmpty
                ? null
                : _fatherOccCtrl.text.trim(),
            motherName: _motherNameCtrl.text.trim().isEmpty
                ? null
                : _motherNameCtrl.text.trim(),
            motherOccupation: _motherOccCtrl.text.trim().isEmpty
                ? null
                : _motherOccCtrl.text.trim(),
            numberOfBrothers: int.tryParse(_brothersCtrl.text),
            numberOfSisters: int.tryParse(_sistersCtrl.text),
            familyType: _familyType,
            familyValues: _familyValues,
            familyStatus: _familyStatus,
            familyDetails: _familyDetailsCtrl.text.trim().isEmpty
                ? null
                : _familyDetailsCtrl.text.trim(),
          ),
        );
      },
      context.l10n.savedFamily,
      saveFamily: true,
    );
    setState(() => _editFamily = false);
  }

  Future<void> _savePartnerPreferences(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    if (!(_partnerFormKey.currentState?.validate() ?? true)) return;
    await _saveSection(
      provider,
      auth,
      (existing) {
        return existing.copyWith(
          partnerPreference: existing.partnerPreference.copyWith(
            minAge: _ppMinAge,
            maxAge: _ppMaxAge,
            minHeight: _ppMinHeight,
            maxHeight: _ppMaxHeight,
            preferredStates: List<String>.from(_ppPreferredStates),
            preferredDistricts: List<String>.from(_ppPreferredDistricts),
            preferredCastes: List<String>.from(_ppPreferredCastes),
            preferredEducation: List<String>.from(_ppPreferredEducation),
            preferredOccupation: List<String>.from(_ppPreferredOccupation),
            minIncome: _ppMinIncome,
            maxIncome: _ppMaxIncome,
            preferredMaritalStatus: List<String>.from(
              _ppPreferredMaritalStatus,
            ),
            otherPreferences: _ppOtherCtrl.text.trim().isEmpty
                ? null
                : _ppOtherCtrl.text.trim(),
          ),
        );
      },
      context.l10n.savedPartner,
      savePartner: true,
    );
    // Partner preferences change can influence matches
    // ignore: unawaited_futures
    provider.refreshMatches();
    setState(() => _editPartner = false);
  }

  bool _isMandatoryFilled() {
    bool _hasStr(String? s) => s != null && s.trim().isNotEmpty;
    final dobOk =
        _dob != null &&
        (() {
          final now = DateTime.now();
          final minDob = DateTime(now.year - 18, now.month, now.day);
          return _dob!.isBefore(minDob);
        })();
    final religionOk = _hasStr(_religion);
    final casteOk = _hasStr(_caste);
    final stateOk = _hasStr(_state);
    final districtOk = _hasStr(_district);
    final educationOk = _hasStr(_education);
    return dobOk &&
        religionOk &&
        casteOk &&
        stateOk &&
        districtOk &&
        educationOk;
  }

  // Helpers for bottom Save
  bool _isEditingFor(int index) {
    switch (index) {
      case 0:
        return _editBasic;
      case 1:
        return _editLocation;
      case 2:
        return _editContact;
      case 3:
        return _editFamily;
      case 4:
        return _editPartner;
      case 5:
        return _editPhotos;
      default:
        return false;
    }
  }

  Future<void> _saveCurrentSection(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    switch (_currentIndex) {
      case 0:
        await _saveBasicInfo(provider, auth);
        break;
      case 1:
        await _saveLocationCareer(provider, auth);
        break;
      case 2:
        await _saveContactInfo(provider, auth);
        break;
      case 3:
        await _saveFamilyInfo(provider, auth);
        break;
      case 4:
        await _savePartnerPreferences(provider, auth);
        break;
      case 5:
        await _savePhotos(provider, auth);
        break;
    }
  }

  Widget _buildPhotosGrid(BuildContext context) {
    final tiles = List<Widget>.generate(3, (i) {
      final url = i < _photos.length ? _photos[i] : null;
      return _photoTile(context, i, url);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.photosGuidance, style: context.styles.caption),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: tiles,
        ),
      ],
    );
  }

  Widget _photoTile(BuildContext context, int slot, String? raw) {
    final canEdit = _editPhotos;
    return GestureDetector(
      onTap: canEdit
          ? () {
              debugPrint('[PhotoUI] tile tapped: slot=$slot');
              _onAddOrReplacePhoto(context, slot);
            }
          : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.palette.surfaceMuted,
              border: Border.all(color: context.palette.divider),
              // For Supabase private we may have a storage path; resolve signed URL lazily
              // For HTTP we already store a URL
            ),
            child: raw == null
                ? const Center(child: Icon(Icons.add_a_photo, size: 28))
                : FutureBuilder<String>(
                    future: sl.storageService.getSignedUrl(raw),
                    builder: (ctx, snap) {
                      final show = snap.data ?? raw;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(show, fit: BoxFit.cover),
                      );
                    },
                  ),
          ),
          if (canEdit && raw != null)
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: () => _onDeletePhoto(context, slot),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.palette.imageScrim.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete,
                    color: context.palette.onImage,
                    size: 16,
                    semanticLabel: context.l10n.photoRemove,
                  ),
                ),
              ),
            ),
          if (canEdit)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.palette.imageScrim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.l10n.photoSlot(slot + 1),
                  style: context.styles.micro.copyWith(
                    color: context.palette.onImage,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onAddOrReplacePhoto(BuildContext context, int slot) async {
    debugPrint('[PhotoUI] _onAddOrReplacePhoto begin: slot=$slot');
    final provider = context.read<MatrimonialProvider>();
    final me = provider.currentUserProfile;
    if (me == null) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(context.l10n.photoTake),
              onTap: () {
                debugPrint('[PhotoUI] source selected: camera');
                Navigator.pop(ctx, 'camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.photoGallery),
              onTap: () {
                debugPrint('[PhotoUI] source selected: gallery');
                Navigator.pop(ctx, 'gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.commonCancel),
              onTap: () {
                debugPrint('[PhotoUI] source selection: cancel');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      debugPrint('[PhotoUI] no source selected, abort');
      return;
    }

    // Use DI PhotoService
    final ps = sl.photoService;
    debugPrint('[PhotoUI] calling photoService.pickEditCompressAndUpload');
    final url = await ps.pickEditCompressAndUpload(
      context: context,
      profileId: me.id,
      slotIndex: slot,
      fromCamera: source == 'camera',
    );
    debugPrint('[PhotoUI] pickEditCompressAndUpload done: url=$url');
    if (url == null) {
      debugPrint('[PhotoUI] upload returned null, abort');
      return;
    }

    setState(() {
      if (_photos.length <= slot) {
        // pad with empties
        _photos = List<String>.from(_photos);
        while (_photos.length < slot) {
          _photos.add('');
        }
        if (_photos.length == slot) {
          _photos.add(url);
        } else {
          _photos[slot] = url;
        }
      } else {
        _photos = List<String>.from(_photos);
        _photos[slot] = url;
      }
    });
    debugPrint('[PhotoUI] photos updated: len=${_photos.length} slot=$slot');
  }

  Future<void> _onDeletePhoto(BuildContext context, int slot) async {
    final stored = slot < _photos.length ? _photos[slot] : null;
    if (stored == null || stored.isEmpty) return;
    debugPrint('[PhotoUI] delete requested: slot=$slot path=$stored');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removePhotoTitle),
        content: Text(context.l10n.removePhotoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true) {
      debugPrint('[PhotoUI] delete canceled');
      return;
    }
    await sl.photoService.maybeDeleteByUrl(stored);
    setState(() {
      final list = List<String>.from(_photos);
      if (slot < list.length) {
        list.removeAt(slot);
      }
      _photos = list;
    });
    debugPrint(
      '[PhotoUI] delete complete: slot=$slot newLen=${_photos.length}',
    );
  }

  Future<void> _savePhotos(
    MatrimonialProvider provider,
    AuthProvider auth,
  ) async {
    await _saveSection(provider, auth, (existing) {
      final normalized = _photos.where((e) => e.trim().isNotEmpty).toList();
      return existing.copyWith(photoUrls: normalized);
    }, context.l10n.savedPhotos);
    setState(() => _editPhotos = false);
  }
}
