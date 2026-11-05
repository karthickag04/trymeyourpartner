import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trymeyourpartner/main.dart';

import 'helpers/signed_out_auth.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts on the splash screen', (tester) async {
    await tester.pumpWidget(TryMeYourPartnerApp(authService: SignedOutAuth()));
    expect(find.text('Loading your experience...'), findsOneWidget);
    // Let the splash animation finish so no timers are left pending.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a signed-out visitor ends up on the sign-in screen', (
    tester,
  ) async {
    await tester.pumpWidget(TryMeYourPartnerApp(authService: SignedOutAuth()));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Sign In'), findsWidgets);
  });
}
