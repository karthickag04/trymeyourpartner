import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/l10n/app_localizations.dart';
import 'package:trymeyourpartner/shared/theme/language_text_scale.dart';

/// The effective text scale seen by widgets, for [locale] and the member's
/// own system font-size setting [system].
Future<double> _scaleSeen(
  WidgetTester tester,
  Locale locale, {
  double system = 1.0,
}) async {
  late double seen;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(system)),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => LanguageTextScale(child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.textScalerOf(context).scale(10) / 10;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return seen;
}

void main() {
  testWidgets('English text keeps its size', (tester) async {
    expect(await _scaleSeen(tester, const Locale('en')), 1.0);
  });

  testWidgets('Tamil text is drawn at 90 %', (tester) async {
    expect(await _scaleSeen(tester, const Locale('ta')), closeTo(0.9, 1e-9));
  });

  testWidgets("the member's larger system font still makes Tamil larger", (
    tester,
  ) async {
    expect(
      await _scaleSeen(tester, const Locale('ta'), system: 1.3),
      closeTo(1.17, 1e-9),
    );
  });
}
