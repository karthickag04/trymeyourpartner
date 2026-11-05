import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tmyp_admin_console/src/app.dart';
import 'package:tmyp_admin_console/src/models.dart';
import 'package:tmyp_admin_console/src/session/session_controller.dart';

import 'fake_backend.dart';

Future<SessionController> pumpConsole(
  WidgetTester tester,
  FakeBackend backend, {
  Size size = const Size(1280, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = SessionController(auth: backend, data: backend);
  addTearDown(controller.dispose);
  await controller.start();
  await tester.pumpWidget(AdminApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

Finder navLabel(String label) => find.descendant(
  of: find.byKey(const Key('console-nav')),
  matching: find.text(label),
);

void main() {
  testWidgets('sign-in screen renders', (tester) async {
    await pumpConsole(tester, FakeBackend());
    expect(find.text('Staff console'), findsOneWidget);
    expect(find.byKey(const Key('email')), findsOneWidget);
    expect(find.byKey(const Key('password')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.byKey(const Key('console-nav')), findsNothing);
  });

  testWidgets('sign-in asks for both fields', (tester) async {
    final backend = FakeBackend();
    await pumpConsole(tester, backend);
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your work email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(backend.signedIn, isFalse);
  });

  testWidgets('a non-staff user is refused and signed out', (tester) async {
    final backend = FakeBackend(staff: null);
    await pumpConsole(tester, backend);
    await tester.enterText(
      find.byKey(const Key('email')),
      'member@example.com',
    );
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();

    expect(find.text('No staff access'), findsOneWidget);
    expect(find.textContaining('does not have staff access'), findsOneWidget);
    expect(backend.signOutCalls, 1);
    expect(backend.signedIn, isFalse);
    expect(find.byKey(const Key('console-nav')), findsNothing);

    await tester.tap(find.text('Back to sign-in'));
    await tester.pumpAndSettle();
    expect(find.text('Staff console'), findsOneWidget);
  });

  testWidgets('first sign-in enrols an authenticator before any staff page', (
    tester,
  ) async {
    final backend = FakeBackend(
      staff: staffProfile('staff', {'moderation.manage'}),
    );
    await pumpConsole(tester, backend);
    await tester.enterText(find.byKey(const Key('email')), 's@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();

    expect(find.text('Set up your authenticator app'), findsOneWidget);
    expect(find.text('JBSW Y3DP EHPK 3PXP'), findsOneWidget);
    expect(find.byKey(const Key('console-nav')), findsNothing);
    expect(find.text('Dashboard'), findsNothing);

    await tester.enterText(find.byKey(const Key('totp-code')), '123456');
    await tester.tap(find.byKey(const Key('verify')));
    await tester.pumpAndSettle();
    expect(backend.verifiedCode, '123456');
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('an enrolled staff member enters a code on every sign-in', (
    tester,
  ) async {
    final backend = FakeBackend(
      staff: staffProfile('staff', {}),
      signedIn: true,
      verifiedFactorId: 'factor-1',
    );
    await pumpConsole(tester, backend);
    expect(find.text('Enter your authenticator code'), findsOneWidget);
    expect(find.byKey(const Key('totp-secret')), findsNothing);
  });

  group('navigation shows only permitted sections', () {
    Future<void> signedInAs(WidgetTester tester, StaffProfile p) => pumpConsole(
      tester,
      FakeBackend(staff: p, signedIn: true, sessionVerified: true),
    );

    testWidgets('branch manager: dashboard and staff', (tester) async {
      await signedInAs(
        tester,
        staffProfile('branch_manager', {
          'staff.view',
          'staff.manage',
        }, branchName: 'Branch X'),
      );
      expect(navLabel('Dashboard'), findsOneWidget);
      expect(navLabel('Staff'), findsOneWidget);
      expect(navLabel('Roles & permissions'), findsNothing);
      expect(find.text('Branch manager'), findsOneWidget);
      expect(find.text('Branch X'), findsOneWidget);
    });

    testWidgets('admin: dashboard, staff, roles; no settings', (tester) async {
      await signedInAs(
        tester,
        staffProfile('admin', {'staff.view', 'roles.view'}),
      );
      expect(navLabel('Dashboard'), findsOneWidget);
      expect(navLabel('Staff'), findsOneWidget);
      expect(navLabel('Roles & permissions'), findsOneWidget);
      expect(navLabel('Settings'), findsNothing);
    });

    testWidgets('system admin: every section', (tester) async {
      await signedInAs(tester, staffProfile('system_admin', {}));
      for (final label in [
        'Dashboard',
        'Staff',
        'Roles & permissions',
        'Settings',
      ]) {
        expect(navLabel(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('staff: dashboard only, no navigation bar', (tester) async {
      await signedInAs(tester, staffProfile('staff', {'moderation.manage'}));
      expect(find.byKey(const Key('console-nav')), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget); // role row on the dashboard
      expect(find.text('Roles & permissions'), findsNothing);
    });

    testWidgets('narrow window uses a bottom navigation bar', (tester) async {
      await pumpConsole(
        tester,
        FakeBackend(
          staff: staffProfile('admin', {'staff.view'}),
          signedIn: true,
          sessionVerified: true,
        ),
        size: const Size(600, 900),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(navLabel('Staff'), findsOneWidget);
    });

    testWidgets('a section without permission cannot be opened by URL', (
      tester,
    ) async {
      final c = await pumpConsole(
        tester,
        FakeBackend(
          staff: staffProfile('branch_manager', {
            'staff.view',
          }, branchName: 'Branch X'),
          signedIn: true,
          sessionVerified: true,
        ),
      );
      expect(c.stage, SessionStage.ready);
      // Navigate directly to /roles: the redirect sends the user back.
      tester.element(find.text('Dashboard').first).go('/roles');
      await tester.pumpAndSettle();
      expect(find.text('Roles & permissions'), findsNothing);
      expect(find.text('Dashboard'), findsWidgets);
    });
  });

  testWidgets('staff list shows the accounts the database returns', (
    tester,
  ) async {
    await pumpConsole(
      tester,
      FakeBackend(
        staff: staffProfile('branch_manager', {
          'staff.view',
        }, branchName: 'Branch X'),
        signedIn: true,
        sessionVerified: true,
        staffList: [
          StaffMember(
            id: 's1',
            displayName: 'Staff X',
            role: 'staff',
            status: 'active',
            createdAt: DateTime.utc(2026, 11, 6),
            branchName: 'Branch X',
          ),
        ],
      ),
    );
    await tester.tap(navLabel('Staff'));
    await tester.pumpAndSettle();
    expect(find.text('Staff · Branch X'), findsOneWidget);
    expect(find.text('Staff X'), findsOneWidget);
  });

  testWidgets('roles matrix is read-only without roles.manage', (tester) async {
    await pumpConsole(
      tester,
      FakeBackend(
        staff: staffProfile('admin', {'roles.view'}),
        signedIn: true,
        sessionVerified: true,
      ),
    );
    await tester.tap(navLabel('Roles & permissions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Read-only'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('system admin can edit the matrix, except its own column', (
    tester,
  ) async {
    final backend = FakeBackend(
      staff: staffProfile('system_admin', {'roles.view', 'roles.manage'}),
      signedIn: true,
      sessionVerified: true,
    );
    await pumpConsole(tester, backend, size: const Size(2200, 1200));
    await tester.tap(navLabel('Roles & permissions'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(2 * 6));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Checkbox &&
            w.key == const Key('grant-system_admin-staff.view'),
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('grant-team_lead-staff.view')));
    await tester.pumpAndSettle();
    expect(backend.grants, contains('team_lead|staff.view'));
  });

  group('settings', () {
    Future<FakeBackend> openSettings(WidgetTester tester) async {
      final backend = FakeBackend(
        staff: staffProfile('system_admin', {'platform.settings'}),
        signedIn: true,
        sessionVerified: true,
      );
      await pumpConsole(tester, backend);
      await tester.tap(navLabel('Settings'));
      await tester.pumpAndSettle();
      return backend;
    }

    testWidgets('system admin changes a setting', (tester) async {
      final backend = await openSettings(tester);
      final field = find.byKey(const Key('setting-maintenance'));
      expect(field, findsOneWidget);
      await tester.enterText(
        field,
        '{"enabled": true, "message": "Back soon"}',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-maintenance')));
      await tester.pumpAndSettle();
      expect(backend.settings['maintenance'], {
        'enabled': true,
        'message': 'Back soon',
      });
      expect(find.text('Saved maintenance'), findsOneWidget);
    });

    testWidgets('invalid JSON cannot be saved', (tester) async {
      final backend = await openSettings(tester);
      await tester.enterText(
        find.byKey(const Key('setting-maintenance')),
        '{"enabled": tru',
      );
      await tester.pump();
      expect(find.text('Not valid JSON'), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('save-maintenance')),
      );
      expect(save.onPressed, isNull);
      expect(backend.settings['maintenance'], {
        'enabled': false,
        'message': '',
      });
    });

    testWidgets('a refused change is reported, not shown as saved', (
      tester,
    ) async {
      final backend = await openSettings(tester);
      backend.settingsWritable = false;
      await tester.enterText(
        find.byKey(const Key('setting-maintenance')),
        '{"enabled": true}',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-maintenance')));
      await tester.pumpAndSettle();
      expect(
        find.text('Not saved: Not allowed to change this setting'),
        findsOneWidget,
      );
    });
  });
}
