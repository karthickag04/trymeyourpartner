import 'matrimonial_user.dart';

/// The required details: religion, caste, state, district, education and a
/// date of birth at least 18 years ago.
bool hasMandatoryProfileFields(MatrimonialUser profile, {DateTime? now}) {
  bool has(String? s) => s != null && s.trim().isNotEmpty;
  final today = now ?? DateTime.now();
  final adultBefore = DateTime(today.year - 18, today.month, today.day);
  return has(profile.religion) &&
      has(profile.caste) &&
      has(profile.state) &&
      has(profile.district) &&
      has(profile.education) &&
      profile.dateOfBirth.isBefore(adultBefore);
}
