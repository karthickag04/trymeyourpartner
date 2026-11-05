import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/shared/services/lookup_ids.dart';

void main() {
  test('nothing chosen saves no id', () {
    expect(requireLookupId('caste', null, null), isNull);
    expect(requireLookupId('caste', '  ', null), isNull);
  });

  test('a chosen name with a match saves its id', () {
    expect(requireLookupId('caste', 'Pillai', 'c1'), 'c1');
  });

  test(
    'a chosen name without a match stops the save instead of saving null',
    () {
      expect(
        () => requireLookupId('caste', 'Pillai', null),
        throwsA(
          isA<LookupNotFoundException>()
              .having((e) => e.field, 'field', 'caste')
              .having((e) => e.value, 'value', 'Pillai'),
        ),
      );
      expect(
        () => requireLookupId('district', 'Tiruchirappalli', ''),
        throwsA(isA<LookupNotFoundException>()),
      );
    },
  );
}
