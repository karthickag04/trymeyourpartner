import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trymeyourpartner/app/preferences/user_preferences.dart';
import 'package:trymeyourpartner/l10n/app_localizations.dart';
import 'package:trymeyourpartner/main.dart';
import 'package:trymeyourpartner/shared/theme/language_text_scale.dart';
import 'package:trymeyourpartner/shared/theme/theme.dart';
import 'package:trymeyourpartner/shared/widgets/display_settings.dart';

import 'helpers/signed_out_auth.dart';

double _scaleAt(WidgetTester tester, Finder f) =>
    MediaQuery.textScalerOf(tester.element(f)).scale(10) / 10;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the whole app follows the text size: language x choice', (
    tester,
  ) async {
    final prefs = UserPreferences(locale: const Locale('ta'));
    await tester.pumpWidget(
      TryMeYourPartnerApp(authService: SignedOutAuth(), preferences: prefs),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
    final screen = find.byType(Scaffold).first;
    expect(_scaleAt(tester, screen), closeTo(0.9, 1e-9)); // Tamil, Standard

    await prefs.setTextSize(TextSizeChoice.large);
    await tester.pumpAndSettle();
    expect(_scaleAt(tester, screen), closeTo(0.9 * 1.15, 1e-9));

    await prefs.setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(_scaleAt(tester, screen), closeTo(1.15, 1e-9)); // English, Large
  });

  testWidgets('the choice is remembered on the device', (tester) async {
    final prefs = await UserPreferences.load();
    expect(prefs.textSize, TextSizeChoice.standard);
    await prefs.setTextSize(TextSizeChoice.extraLarge);

    final again = await UserPreferences.load();
    expect(again.textSize, TextSizeChoice.extraLarge);
  });

  testWidgets('an unknown saved value falls back to Standard', (tester) async {
    SharedPreferences.setMockInitialValues({
      UserPreferences.textSizeKey: 'huge',
    });
    final prefs = await UserPreferences.load();
    expect(prefs.textSize, TextSizeChoice.standard);
  });

  testWidgets('Settings > Text size changes text across the app', (
    tester,
  ) async {
    final prefs = UserPreferences(locale: const Locale('en'));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: prefs,
        child: Consumer<UserPreferences>(
          builder: (context, p, _) => MaterialApp(
            theme: AppTheme.light(p.locale),
            locale: p.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => LanguageTextScale(
              memberFactor: p.textSize.factor,
              child: child!,
            ),
            home: const Scaffold(body: DisplaySettings()),
          ),
        ),
      ),
    );
    expect(find.text('Text size'), findsOneWidget);
    expect(find.textContaining('Standard'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Extra large'));
    await tester.pumpAndSettle();
    expect(prefs.textSize, TextSizeChoice.extraLarge);
    expect(find.textContaining('Extra large ·'), findsOneWidget);
    expect(_scaleAt(tester, find.byType(DisplaySettings)), closeTo(1.3, 1e-9));
  });
}
