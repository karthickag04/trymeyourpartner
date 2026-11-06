import 'package:trymeyourpartner/shared/models/matrimonial_user.dart';

/// A member profile with every required detail saved; override fields to
/// make it incomplete.
MatrimonialUser sampleProfile([Map<String, dynamic> overrides = const {}]) {
  return MatrimonialUser.fromJson({
    'id': 'p1',
    'profile_id': 'MP1',
    'name': 'Rwms Test',
    'gender': 'Male',
    'date_of_birth': '1992-04-04',
    'religion': 'Hindu',
    'caste': {'name': 'Pillai'},
    'state': {'name': 'Tamil Nadu'},
    'district': {'name': 'Tiruchirappalli'},
    'city': 'Tiruchirapalli',
    'education': 'PG - Msc., CS',
    'occupation': 'Teaching and Training',
    'created_at': '2026-11-04T09:59:15Z',
    'updated_at': '2026-11-05T15:07:23Z',
    'contact_info': {
      'phone_number': '9000002110',
      'whatsapp_number': '9000002110',
    },
    ...overrides,
  });
}
