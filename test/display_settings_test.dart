import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trymeyourpartner/app/preferences/user_preferences.dart';
import 'package:trymeyourpartner/l10n/app_localizations.dart';
import 'package:trymeyourpartner/shared/theme/theme.dart';
import 'package:trymeyourpartner/shared/widgets/display_settings.dart';

/// The Appearance and Language controls from the Profile tab, in an app that
/// follows the preferences like the real one does.
Widget _app(UserPreferences prefs) => ChangeNotifierProvider.value(
  value: prefs,
  child: Consumer<UserPreferences>(
    builder: (context, p, _) => MaterialApp(
      theme: AppTheme.light(p.locale),
      darkTheme: AppTheme.dark(p.locale),
      themeMode: p.themeMode,
      locale: p.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: DisplaySettings()),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Appearance switches between light and dark', (tester) async {
    final prefs = UserPreferences(
      themeMode: ThemeMode.light,
      locale: const Locale('en'),
    );
    await tester.pumpWidget(_app(prefs));
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(DisplaySettings))).brightness;
    expect(brightness(), Brightness.light);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(prefs.themeMode, ThemeMode.dark);
    expect(brightness(), Brightness.dark);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(prefs.themeMode, ThemeMode.system);
  });

  testWidgets('Language switches the whole screen to Tamil and back', (
    tester,
  ) async {
    final prefs = UserPreferences(locale: const Locale('en'));
    await tester.pumpWidget(_app(prefs));
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();
    expect(prefs.locale, const Locale('ta'));
    expect(find.text('தோற்றம்'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
  });
}
