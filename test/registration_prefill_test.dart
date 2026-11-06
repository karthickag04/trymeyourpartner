import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/features/onboarding/registration_prefill.dart';
import 'package:trymeyourpartner/shared/services/matrimonial_service.dart';

import 'helpers/profiles.dart';

void main() {
  final now = DateTime(2026, 11, 5);

  test('a returning member sees everything they already saved', () {
    final pre = RegistrationPrefill.from(
      sampleProfile({'caste': null, 'caste_id': null}),
      extras: const RegistrationExtras(
        createdBy: 'self',
        workStatus: 'business',
        qualifications: [
          {'type': 'PG', 'discipline': 'Msc., CS'},
        ],
      ),
      now: now,
    );
    expect(pre.name, 'Rwms Test');
    expect(pre.gender, 'Male');
    expect(pre.dateOfBirth, DateTime(1992, 4, 4));
    expect(pre.phone, '9000002110');
    expect(pre.whatsapp, '9000002110');
    expect(pre.city, 'Tiruchirapalli');
    expect(pre.religion, 'Hindu');
    expect(pre.state, 'Tamil Nadu');
    expect(pre.district, 'Tiruchirappalli');
    expect(pre.occupation, 'Teaching and Training');
    expect(pre.createdBy, 'self');
    expect(pre.workStatus, 'business');
    expect(pre.qualifications, [
      {'type': 'PG', 'discipline': 'Msc., CS'},
    ]);
    // Only the missing detail is left to fill in.
    expect(pre.caste, isNull);
  });

  test(
    'a brand-new profile starts empty (placeholder date is not a birthday)',
    () {
      final pre = RegistrationPrefill.from(
        sampleProfile({
          'name': '',
          'date_of_birth': '2026-11-05',
          'city': '',
          'contact_info': <String, dynamic>{},
        }),
        now: now,
      );
      expect(pre.name, isNull);
      expect(pre.dateOfBirth, isNull);
      expect(pre.phone, isNull);
      expect(pre.city, isNull);
    },
  );

  test('an empty phone box never erases the saved number', () {
    expect(keepStoredIfBlank('', '9000002110'), '9000002110');
    expect(keepStoredIfBlank('   ', '9000002110'), '9000002110');
    expect(keepStoredIfBlank(' 9123456789 ', '9000002110'), '9123456789');
    expect(keepStoredIfBlank('', null), isNull);
  });
}
