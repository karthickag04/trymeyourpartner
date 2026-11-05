import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/features/settings/account_settings.dart';
import 'package:trymeyourpartner/l10n/app_localizations.dart';
import 'package:trymeyourpartner/shared/theme/theme.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(const Locale('en')),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Builder(builder: (_) => child)),
);

const _email = 'member@example.com';

void main() {
  testWidgets('Change password sends a reset link to the member email', (
    tester,
  ) async {
    final sent = <String>[];
    await tester.pumpWidget(
      _app(
        ChangePasswordTile(
          email: _email,
          sendResetLink: (e) async => sent.add(e),
        ),
      ),
    );

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    expect(find.textContaining(_email), findsOneWidget);

    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();
    expect(sent, [_email]);
    expect(
      find.text('Check $_email for the link to set a new password.'),
      findsOneWidget,
    );
  });

  testWidgets('Cancel sends nothing', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      _app(
        ChangePasswordTile(
          email: _email,
          sendResetLink: (e) async => sent.add(e),
        ),
      ),
    );

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(sent, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('A failed send tells the member to try again', (tester) async {
    await tester.pumpWidget(
      _app(
        ChangePasswordTile(
          email: _email,
          sendResetLink: (_) async => throw Exception('network'),
        ),
      ),
    );

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not send the link. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('About shows the app name and description', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppAbout(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('TryMeYourPartner'), findsOneWidget);
    expect(
      find.text(
        'A matrimony app for Tamil and Indian families around the world.',
      ),
      findsOneWidget,
    );
  });
}
