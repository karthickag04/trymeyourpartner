import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/matrimonial_provider.dart';
import '../services/matrimonial_service.dart';
import 'matrimonial_main_screen.dart';
import '../utils/constants.dart';

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
          const SnackBar(
            content: Text('Profile created'),
            backgroundColor: AppColors.success,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            debugPrint('🔁 _save: postFrameNav aborted; widget unmounted');
            return;
          }
          try {
            debugPrint(
              '🔁 _save: navigating to MatrimonialMainScreen (postFrame)',
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MatrimonialMainScreen()),
              (route) => false,
            );
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
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
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
          title: const Text('Complete Registration'),
          backgroundColor: AppColors.primary,
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
                      Text(
                        'Email (from login)',
                        style: AppTextStyles.subtitle2,
                      ),
                      const SizedBox(height: 6),
                      Text(email, style: AppTextStyles.body2),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name required'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        validator: (v) => v == null ? 'Select gender' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dobCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
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
                              _dobCtrl.text =
                                  '${picked.year}-${picked.month}-${picked.day}';
                            });
                          }
                        },
                        validator: (_) =>
                            _dob == null ? 'Select date of birth' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Valid phone required'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _whatsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Valid WhatsApp required'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      // Created by
                      DropdownButtonFormField<String>(
                        value: _createdBy,
                        items: const [
                          DropdownMenuItem(value: 'self', child: Text('Self')),
                          DropdownMenuItem(
                            value: 'sibling',
                            child: Text('Sibling'),
                          ),
                          DropdownMenuItem(
                            value: 'parents',
                            child: Text('Parents'),
                          ),
                          DropdownMenuItem(
                            value: 'guardian',
                            child: Text('Guardian'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _createdBy = v),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Profile created by',
                        ),
                        validator: (v) => v == null ? 'Select one' : null,
                      ),
                      const SizedBox(height: 8),
                      // Work status
                      DropdownButtonFormField<String>(
                        value: _workStatus,
                        items: const [
                          DropdownMenuItem(
                            value: 'business',
                            child: Text('Business'),
                          ),
                          DropdownMenuItem(
                            value: 'salaried',
                            child: Text('Salaried'),
                          ),
                          DropdownMenuItem(
                            value: 'not_working',
                            child: Text('Currently not working'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _workStatus = v),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Work status',
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
                        decoration: const InputDecoration(
                          labelText: 'Occupation category',
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
                              decoration: const InputDecoration(
                                labelText: 'Qualification',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Discipline/Domain',
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
                              child: const Text('Add'),
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
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _religion,
                        items: AppConstants.religionCategories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => _onReligionChanged(v),
                        decoration: const InputDecoration(
                          labelText: 'Religion',
                        ),
                        validator: (v) =>
                            v == null ? 'Religion required' : null,
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
                        decoration: const InputDecoration(labelText: 'Caste'),
                        validator: (v) => v == null ? 'Caste required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Sub Caste (optional)',
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
                        decoration: const InputDecoration(labelText: 'State'),
                        validator: (v) => v == null ? 'State required' : null,
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
                        decoration: const InputDecoration(
                          labelText: 'District',
                        ),
                        validator: (v) =>
                            v == null ? 'District required' : null,
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
                              : const Text('Save and Continue'),
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
