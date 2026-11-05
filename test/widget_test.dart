// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:trymeyourpartner/main.dart';

void main() {
  testWidgets('App widget builds without errors', (WidgetTester tester) async {
    // Build the real app widget
    await tester.pumpWidget(const TryMeYourPartnerApp());

    // Basic smoke: Splash text is present
    expect(find.text('Loading your experience...'), findsOneWidget);
  });
}
