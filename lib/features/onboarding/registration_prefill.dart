import '../../shared/models/matrimonial_user.dart';
import '../../shared/services/matrimonial_service.dart';

/// What the registration form starts with for a member who already saved some
/// details, so they only fill in what is missing. Empty strings become null.
class RegistrationPrefill {
  const RegistrationPrefill({
    this.name,
    this.gender,
    this.dateOfBirth,
    this.phone,
    this.whatsapp,
    this.city,
    this.religion,
    this.caste,
    this.subCaste,
    this.state,
    this.district,
    this.occupation,
    this.createdBy,
    this.workStatus,
    this.qualifications = const [],
  });

  final String? name;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? phone;
  final String? whatsapp;
  final String? city;
  final String? religion;
  final String? caste;
  final String? subCaste;
  final String? state;
  final String? district;
  final String? occupation;
  final String? createdBy;
  final String? workStatus;
  final List<Map<String, String>> qualifications;

  static String? _v(String? s) {
    final t = s?.trim() ?? '';
    return t.isEmpty ? null : t;
  }

  /// A placeholder date (e.g. a new profile's default of "today") is not a
  /// date of birth the member chose.
  static DateTime? _dob(DateTime d, DateTime now) {
    final adultBefore = DateTime(now.year - 18, now.month, now.day);
    return d.isBefore(adultBefore) ? d : null;
  }

  factory RegistrationPrefill.from(
    MatrimonialUser profile, {
    RegistrationExtras extras = const RegistrationExtras(),
    DateTime? now,
  }) {
    return RegistrationPrefill(
      name: _v(profile.name),
      gender: _v(profile.gender),
      dateOfBirth: _dob(profile.dateOfBirth, now ?? DateTime.now()),
      phone: _v(profile.contactInfo.phoneNumber),
      whatsapp: _v(profile.contactInfo.whatsappNumber),
      city: _v(profile.city),
      religion: _v(profile.religion),
      caste: _v(profile.caste),
      subCaste: _v(profile.subCaste),
      state: _v(profile.state),
      district: _v(profile.district),
      occupation: _v(profile.occupation),
      createdBy: _v(extras.createdBy),
      workStatus: _v(extras.workStatus),
      qualifications: extras.qualifications,
    );
  }
}

/// A phone number from the form, or the stored one when the box was left
/// empty: an empty box must never erase a saved number.
String? keepStoredIfBlank(String typed, String? stored) {
  final t = typed.trim();
  return t.isEmpty ? stored : t;
}
