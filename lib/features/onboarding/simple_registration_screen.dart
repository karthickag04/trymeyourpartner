import 'package:flutter/material.dart';
import '../../l10n/formatters.dart';
import '../../l10n/option_labels.dart';
import '../../shared/widgets/language_selector.dart';
import '../../l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../shared/services/matrimonial_service.dart';
import '../../shared/theme/constants.dart';

class SimpleRegistrationScreen extends StatefulWidget {
  const SimpleRegistrationScreen({super.key});

  @override
  State<SimpleRegistrationScreen> createState() =>
      _SimpleRegistrationScreenState();
}

class _SimpleRegistrationScreenState extends State<SimpleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers / values
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _disciplineCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String? _gender; // Male/Female
  String? _state;
  String? _district;
  String? _religion;
  String? _caste;
  String? _subCaste;
  DateTime? _dob;
  bool _saving = false;
  String? _createdBy; // self/sibling/parents/guardian
  String? _workStatus; // business/salaried/not_working
  String? _occupationCategory;
  String? _selectedQualificationType;

  // Data sources
  List<String> _stateOptions = [];
  List<String> _districtOptions = [];
  List<String> _casteOptions = [];
  List<String> _occupationCategories = [];
  List<String> _qualificationTypes = [];
  final List<Map<String, String>> _qualifications = []; // {type, discipline}

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = (auth.user?.fullName ?? '').trim();
    // Email comes from auth; not editable here by spec
    _loadLookups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsCtrl.dispose();
    _qualificationCtrl.dispose();
    _disciplineCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final p = context.read<MatrimonialProvider>();
    await p.prefetchLookups();
    if (!mounted) return;
    setState(() {
      _stateOptions = p.states.map((e) => e.name).toList();
    });
    _occupationCategories = await MatrimonialService.getOccupationCategories();
    if (!mounted) return;
    _qualificationTypes = await MatrimonialService.getQualificationTypes();
    if (!mounted) return;
    // After lookups, try to prefill from existing profile data
    _prefillFromProfile();
  }

  void _prefillFromProfile() {
    final matrimony = context.read<MatrimonialProvider>();
    final profile = matrimony.currentUserProfile;
    if (profile == null) return;
    // Prefill basic fields only if user hasn't typed anything yet
    if ((_gender == null || _gender!.isEmpty) && profile.gender.isNotEmpty) {
      _gender = profile.gender;
    }
    if ((_state == null || _state!.isEmpty) && profile.state.isNotEmpty) {
      _state = profile.state;
      // Trigger districts load based on prefilled state
      // ignore: discarded_futures
      _onStateChanged(_state);
    }
    if ((_district == null || _district!.isEmpty) &&
        profile.district.isNotEmpty) {
      // We'll set this after districts load if it exists in options
      _district = profile.district;
    }
    if ((_religion == null || _religion!.isEmpty) &&
        profile.religion.isNotEmpty) {
      _religion = profile.religion;
      // Preload castes for this religion
      // ignore: discarded_futures
      _onReligionChanged(_religion);
    }
  }

  Future<void> _onStateChanged(String? stateName) async {
    _state = stateName;
    _district = null;
    if (stateName == null) {
      if (!mounted) return;
      setState(() => _districtOptions = []);
      return;
    }
    final p = context.read<MatrimonialProvider>();
    // Resolve state id via provider cache
    final st = p.states.firstWhere(
      (s) => s.name == stateName,
      orElse: () => p.states.first,
    );
    // Ensure provider has loaded districts for this state (populates cache)
    try {
      await p.prefetchLookups(stateId: st.id);
    } catch (_) {}
    final districts = p.districtsFor(st.id);
    if (!mounted) return;
    setState(() {
      _districtOptions = districts.map((d) => d.name).toList();
      // If we had a remembered district, keep it if present; otherwise default to first
      if (_district != null && !_districtOptions.contains(_district)) {
        _district = null;
      }
      if (_district == null && _districtOptions.isNotEmpty) {
        _district = _districtOptions.first;
      }
    });
  }

  Future<void> _onReligionChanged(String? religion) async {
    _religion = religion;
    _caste = null;
    if (religion == null) {
      if (!mounted) return;
      setState(() => _casteOptions = []);
      return;
    }
    final p = context.read<MatrimonialProvider>();
    await p.prefetchLookups(religion: religion);
    final castes = p.castesForReligion(religion);
    if (!mounted) return;
    setState(() {
      // Deduplicate while preserving order
      final seen = <String>{};
      _casteOptions = [
        for (final name in castes.map((c) => c.name))
          if (seen.add(name)) name,
      ];
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final matrimony = context.read<MatrimonialProvider>();
    final auth = context.read<AuthProvider>();
    final profile = matrimony.currentUserProfile;
    if (profile == null || auth.user == null) return;

    setState(() => _saving = true);
    try {
      debugPrint('🔁 _save: start for profile=${profile.id}');
      // Derive an education value if the single field is empty but the
      // multi-qualification list has entries (used by mandatory check).
      final String effectiveEducation = (() {
        final typed = _qualificationCtrl.text.trim();
        if (typed.isNotEmpty) return typed;
        if (_qualifications.isNotEmpty) {
          final first = _qualifications.first;
          final t = (first['type'] ?? '').trim();
          final d = (first['discipline'] ?? '').trim();
          return d.isNotEmpty ? '$t - $d' : t;
        }
        return profile.education;
      })();

      final updated = profile.copyWith(
        name: _nameCtrl.text.trim().isEmpty
            ? profile.name
            : _nameCtrl.text.trim(),
        gender: _gender ?? profile.gender,
        dateOfBirth: _dob ?? profile.dateOfBirth,
        religion: _religion ?? profile.religion,
        caste: _caste ?? profile.caste,
        subCaste: _subCaste ?? profile.subCaste,
        state: _state ?? profile.state,
        district: _district ?? profile.district,
        city: _cityCtrl.text.trim().isEmpty
            ? profile.city
            : _cityCtrl.text.trim(),
        education: effectiveEducation,
        occupation: _occupationCategory ?? profile.occupation,
        contactInfo: profile.contactInfo.copyWith(
          phoneNumber: _phoneCtrl.text.trim(),
          whatsappNumber: _whatsCtrl.text.trim(),
        ),
      );

      debugPrint('🔁 _save: calling provider.saveUserProfile');
      await matrimony.saveUserProfile(
        updated,
        saveContact: true,
        saveFamily: false,
        savePartner: false,
      );
      debugPrint('🔁 _save: saveUserProfile returned');

      // Save extras: created_by, work_status, occupation category name
      final pid = matrimony.currentUserProfile?.id ?? updated.id;
      debugPrint('🔁 _save: calling updateRegistrationExtras for pid=$pid');
      await MatrimonialService.updateRegistrationExtras(
        pid,
        createdBy: _createdBy,
        workStatus: _workStatus,
      );
      debugPrint('🔁 _save: updateRegistrationExtras returned');

      // Save multi-qualifications list
      if (_qualifications.isNotEmpty) {
        debugPrint(
          '🔁 _save: calling setProfileQualifications count=${_qualifications.length}',
        );
        await MatrimonialService.setProfileQualifications(pid, _qualifications);
        debugPrint('🔁 _save: setProfileQualifications returned');
      }

      // If the widget is still mounted, show success feedback and schedule
      // a post-frame navigation. Scheduling in a post-frame callback reduces
      // the chance of racing with parent rebuilds that may remove this widget.
      if (mounted) {
        debugPrint(
          '🔁 _save: showing success snackbar and scheduling navigation',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.registrationProfileCreated),
            backgroundColor: context.palette.success,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            debugPrint('🔁 _save: postFrameNav aborted; widget unmounted');
            return;
          }
          try {
            debugPrint('🔁 _save: navigating to home (postFrame)');
            context.go(AppRoutes.home);
          } catch (e) {
            debugPrint('🔁 _save: navigation failed: $e');
          }
        });
      } else {
        debugPrint(
          '🔁 _save: completed; widget unmounted — cannot navigate from here',
        );
      }
    } catch (e) {
      debugPrint('🔁 _save: caught error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.registrationSaveFailed),
          backgroundColor: context.palette.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matrimony = context.watch<MatrimonialProvider>();
    final p = matrimony.currentUserProfile;
    final email = context.watch<AuthProvider>().user?.email ?? '';
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.registrationTitle),
          backgroundColor: context.palette.primary,
          foregroundColor: context.palette.onPrimary,
        ),
        body: p == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language first, so the rest of the form is read in
                      // the member's own language.
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppDimensions.paddingM,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.l10n.registrationLanguageHint,
                                  style: context.styles.body2,
                                ),
                              ),
                              const LanguageSelector(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      Text(
                        context.l10n.registrationEmailFromLogin,
                        style: context.styles.subtitle2,
                      ),
                      const SizedBox(height: 6),
                      Text(email, style: context.styles.body2),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldFullName,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.l10n.validationNameRequired
                            : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        items: [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text(context.l10n.genderMale),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text(context.l10n.genderFemale),
                          ),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldGender,
                        ),
                        validator: (v) => v == null
                            ? context.l10n.validationSelectGender
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dobCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldDateOfBirth,
                        ),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(
                              now.year - 25,
                              now.month,
                              now.day,
                            ),
                            firstDate: DateTime(now.year - 70),
                            lastDate: DateTime(
                              now.year - 18,
                              now.month,
                              now.day,
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              _dob = picked;
                              _dobCtrl.text = context.formatDate(picked);
                            });
                          }
                        },
                        validator: (_) => _dob == null
                            ? context.l10n.validationSelectDob
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldPhone,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? context.l10n.validationPhone
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _whatsCtrl,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldWhatsapp,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? context.l10n.validationWhatsapp
                            : null,
                      ),
                      const SizedBox(height: 8),
                      // Created by
                      DropdownButtonFormField<String>(
                        value: _createdBy,
                        items: [
                          DropdownMenuItem(
                            value: 'self',
                            child: Text(context.l10n.createdBySelf),
                          ),
                          DropdownMenuItem(
                            value: 'sibling',
                            child: Text(context.l10n.createdBySibling),
                          ),
                          DropdownMenuItem(
                            value: 'parents',
                            child: Text(context.l10n.createdByParents),
                          ),
                          DropdownMenuItem(
                            value: 'guardian',
                            child: Text(context.l10n.createdByGuardian),
                          ),
                        ],
                        onChanged: (v) => setState(() => _createdBy = v),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldProfileCreatedBy,
                        ),
                        validator: (v) =>
                            v == null ? context.l10n.validationSelectOne : null,
                      ),
                      const SizedBox(height: 8),
                      // Work status
                      DropdownButtonFormField<String>(
                        value: _workStatus,
                        items: [
                          DropdownMenuItem(
                            value: 'business',
                            child: Text(context.l10n.workBusiness),
                          ),
                          DropdownMenuItem(
                            value: 'salaried',
                            child: Text(context.l10n.workSalaried),
                          ),
                          DropdownMenuItem(
                            value: 'not_working',
                            child: Text(context.l10n.workNotWorking),
                          ),
                        ],
                        onChanged: (v) => setState(() => _workStatus = v),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldWorkStatus,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Occupation category
                      DropdownButtonFormField<String>(
                        value: _occupationCategory,
                        items: _occupationCategories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _occupationCategory = v),
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldOccupationCategory,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Qualifications multi-entry
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedQualificationType,
                              items: _qualificationTypes
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedQualificationType = v;
                                  if (v != null) _qualificationCtrl.text = v;
                                });
                              },
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: context.l10n.fieldQualification,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: context.l10n.fieldDiscipline,
                              ),
                              controller: _disciplineCtrl,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: ElevatedButton(
                              onPressed: () {
                                final q = _qualificationCtrl.text.trim();
                                final d = _disciplineCtrl.text.trim();
                                if (q.isEmpty) return;
                                _qualifications.add({
                                  'type': q,
                                  'discipline': d,
                                });
                                setState(() {
                                  _selectedQualificationType = null;
                                  _qualificationCtrl.clear();
                                  _disciplineCtrl.clear();
                                });
                              },
                              child: Text(context.l10n.actionAdd),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_qualifications.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: _qualifications
                              .map(
                                (e) => Chip(
                                  label: Text(
                                    e['discipline']?.isNotEmpty == true
                                        ? '${e['type']} - ${e['discipline']}'
                                        : e['type']!,
                                  ),
                                  onDeleted: () {
                                    setState(() => _qualifications.remove(e));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldCity,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _religion,
                        items: AppConstants.religionCategories
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(context.optionLabel(e)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => _onReligionChanged(v),
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldReligion,
                        ),
                        validator: (v) =>
                            v == null ? context.l10n.validationReligion : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _caste,
                        items: _casteOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _caste = v),
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldCaste,
                        ),
                        validator: (v) =>
                            v == null ? context.l10n.validationCaste : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldSubCasteOptional,
                        ),
                        onChanged: (v) => _subCaste = v,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _state,
                        items: _stateOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => _onStateChanged(v),
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldState,
                        ),
                        validator: (v) =>
                            v == null ? context.l10n.validationState : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _district,
                        items: _districtOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _district = v),
                        decoration: InputDecoration(
                          labelText: context.l10n.fieldDistrict,
                        ),
                        validator: (v) =>
                            v == null ? context.l10n.validationDistrict : null,
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.l10n.actionSaveAndContinue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
