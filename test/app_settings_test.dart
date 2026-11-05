import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trymeyourpartner/app/settings/app_settings.dart';
import 'package:trymeyourpartner/app/settings/maintenance_gate.dart';
import 'package:trymeyourpartner/features/settings/help_screen.dart';

class _FakeSource implements AppSettingsSource {
  Map<String, dynamic> values;
  _FakeSource(this.values);
  @override
  Future<Map<String, dynamic>> fetch() async => values;
}

Future<AppSettings> _settings(Map<String, dynamic> values) async {
  final s = AppSettings(_FakeSource(values));
  await s.refresh();
  return s;
}

Widget _host(AppSettings s, Widget child) => ChangeNotifierProvider.value(
  value: s,
  child: MaterialApp(home: child),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults apply when nothing is configured', () async {
    final s = await _settings({});
    expect(s.maintenanceEnabled, isFalse);
    expect(s.isFeatureEnabled('contact_reveal'), isTrue);
    expect(s.freeMonthlyContactReveals, 5);
    expect(s.defaultLocale, 'en');
  });

  test('reads admin-controlled values', () async {
    final s = await _settings({
      'features': {'contact_reveal': false},
      'free_plan': {'monthly_contact_reveals': 9},
      'default_locale': 'ta',
    });
    expect(s.isFeatureEnabled('contact_reveal'), isFalse);
    expect(s.isFeatureEnabled('anything_else'), isTrue);
    expect(s.freeMonthlyContactReveals, 9);
    expect(s.defaultLocale, 'ta');
  });

  test('keeps the last good values when the server is unreachable', () async {
    final source = _FakeSource({
      'maintenance': {'enabled': true, 'message': 'Back at 6pm'},
    });
    final s = AppSettings(source);
    await s.refresh();
    source.values = {}; // empty answer = keep what we have
    await s.refresh();
    expect(s.maintenanceMessage, 'Back at 6pm');
  });

  testWidgets('maintenance mode replaces the app with a notice', (t) async {
    final s = await _settings({
      'maintenance': {'enabled': true, 'message': 'Back at 6pm'},
    });
    await t.pumpWidget(_host(s, const MaintenanceGate(child: Text('the app'))));
    expect(find.text('Under maintenance'), findsOneWidget);
    expect(find.text('Back at 6pm'), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  testWidgets('the app shows normally when maintenance is off', (t) async {
    final s = await _settings({
      'maintenance': {'enabled': false},
    });
    await t.pumpWidget(_host(s, const MaintenanceGate(child: Text('the app'))));
    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('Help shows the configured support contacts', (t) async {
    final s = await _settings({
      'support': {
        'email': 'help@example.com',
        'phone': '',
        'whatsapp': '+91 90000 00000',
      },
    });
    await t.pumpWidget(_host(s, const HelpScreen()));
    expect(find.text('help@example.com'), findsOneWidget);
    expect(find.text('+91 90000 00000'), findsOneWidget);
    expect(find.text('Phone'), findsNothing); // empty contacts are hidden
  });
}
