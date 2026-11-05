import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trymeyourpartner/app/preferences/user_preferences.dart';
import 'package:trymeyourpartner/main.dart';

import 'helpers/signed_out_auth.dart';

/// Pumps the app signed out and waits for the sign-in screen.
Future<void> _pumpSignIn(WidgetTester tester, UserPreferences prefs) async {
  await tester.pumpWidget(
    TryMeYourPartnerApp(authService: SignedOutAuth(), preferences: prefs),
  );
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('switching the theme mode changes the brightness', (
    tester,
  ) async {
    final prefs = UserPreferences(themeMode: ThemeMode.light);
    await _pumpSignIn(tester, prefs);
    expect(_brightness(tester), Brightness.light);

    await prefs.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);

    await prefs.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
  });

  testWidgets('system theme mode follows the platform brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpSignIn(tester, UserPreferences());
    expect(_brightness(tester), Brightness.dark);
  });

  testWidgets('switching the locale to Tamil shows Tamil on sign-in', (
    tester,
  ) async {
    final prefs = UserPreferences(locale: const Locale('en'));
    await _pumpSignIn(tester, prefs);
    expect(find.text('Sign In'), findsWidgets);

    await prefs.setLocale(const Locale('ta'));
    await tester.pumpAndSettle();
    expect(find.text('உள்நுழைக'), findsWidgets);
    expect(find.text('Sign In'), findsNothing);
  });

  testWidgets('the language menu on the sign-in screen switches language', (
    tester,
  ) async {
    final prefs = UserPreferences(locale: const Locale('en'));
    await _pumpSignIn(tester, prefs);

    await tester.tap(find.byTooltip('Change language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('தமிழ்').last);
    await tester.pumpAndSettle();

    expect(prefs.locale, const Locale('ta'));
    expect(find.text('உள்நுழைக'), findsWidgets);
  });

  test('choices are saved and loaded again', () async {
    final first = await UserPreferences.load();
    expect(first.themeMode, ThemeMode.system);
    expect(first.locale, isNull);

    await first.setThemeMode(ThemeMode.dark);
    await first.setLocale(const Locale('ta'));

    final second = await UserPreferences.load();
    expect(second.themeMode, ThemeMode.dark);
    expect(second.locale, const Locale('ta'));
  });

  test('unsupported languages are ignored', () async {
    final prefs = await UserPreferences.load();
    await prefs.setLocale(const Locale('fr'));
    expect(prefs.locale, isNull);
  });
}
