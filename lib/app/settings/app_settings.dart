import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/errors/report_error.dart';

/// Where settings come from. The app reads the `app_settings` table; tests
/// supply a fake.
abstract class AppSettingsSource {
  Future<Map<String, dynamic>> fetch();
}

class SupabaseAppSettingsSource implements AppSettingsSource {
  @override
  Future<Map<String, dynamic>> fetch() async {
    final rows = await Supabase.instance.client
        .from('app_settings')
        .select('key,value');
    return {
      for (final r in (rows as List)) (r as Map)['key'] as String: r['value'],
    };
  }
}

/// Admin-controlled settings (roadmap P1-12): maintenance mode, support
/// contacts, feature switches, plan limits, default language.
///
/// Loaded at start-up and whenever the app returns to the foreground; the
/// last good copy is kept on the device so the app works offline. Screens
/// read values from here instead of hard-coding them.
class AppSettings extends ChangeNotifier with WidgetsBindingObserver {
  static const _cacheKey = 'app_settings.cache';

  final AppSettingsSource _source;
  Map<String, dynamic> _values = const {};

  AppSettings(this._source);

  /// Loads the cached copy, then refreshes from the server, and refreshes
  /// again each time the app is resumed.
  Future<void> start() async {
    await _loadCache();
    WidgetsBinding.instance.addObserver(this);
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final fresh = await _source.fetch();
      if (fresh.isEmpty) return;
      _values = fresh;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(fresh));
    } catch (_) {
      // Keep the last known values when offline or the server is unreachable.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        _values = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        notifyListeners();
      }
    } catch (e, st) {
      reportError(e, st, where: 'app_settings');
    }
  }

  Map<String, dynamic> _map(String key) {
    final v = _values[key];
    return v is Map ? Map<String, dynamic>.from(v) : const {};
  }

  String _str(String key, String field) =>
      (_map(key)[field] as String?)?.trim() ?? '';

  bool get maintenanceEnabled => _map('maintenance')['enabled'] == true;
  String get maintenanceMessage => _str('maintenance', 'message');

  String get supportEmail => _str('support', 'email');
  String get supportPhone => _str('support', 'phone');
  String get supportWhatsapp => _str('support', 'whatsapp');
  bool get hasSupportContact =>
      supportEmail.isNotEmpty ||
      supportPhone.isNotEmpty ||
      supportWhatsapp.isNotEmpty;

  /// Features are on unless an admin switched them off.
  bool isFeatureEnabled(String feature) => _map('features')[feature] != false;

  int get freeMonthlyContactReveals =>
      (_map('free_plan')['monthly_contact_reveals'] as num?)?.toInt() ?? 5;

  String get defaultLocale {
    final v = _values['default_locale'];
    return v is String && v.isNotEmpty ? v : 'en';
  }
}
