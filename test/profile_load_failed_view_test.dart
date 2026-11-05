import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/features/onboarding/profile_completion_gate.dart';
import 'package:trymeyourpartner/l10n/app_localizations.dart';
import 'package:trymeyourpartner/shared/theme/theme.dart';

void main() {
  testWidgets('a failed profile load offers a retry, not an empty form', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Locale('en')),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileLoadFailedView(onRetry: () => retries++),
      ),
    );
    expect(find.textContaining("couldn't load your profile"), findsOneWidget);
    expect(find.textContaining('Your details are safe'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });
}
