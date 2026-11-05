import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The member's display choices: light/dark/system theme and app language.
///
/// Stored on the device with shared_preferences, so they apply before
/// sign-in (for example on the sign-in and registration screens).
class UserPreferences extends ChangeNotifier {
  static const themeModeKey = 'prefs.themeMode';
  static const localeKey = 'prefs.locale';

  /// Languages the app is translated into.
  static const supportedLanguageCodes = ['en', 'ta'];

  ThemeMode _themeMode;
  Locale? _locale;
  SharedPreferences? _prefs;

  UserPreferences({ThemeMode themeMode = ThemeMode.system, Locale? locale})
    : _themeMode = themeMode,
      _locale = locale;

  /// Reads saved choices. Missing or unknown values fall back to the system
  /// theme and the device language.
  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final p = UserPreferences(
      themeMode: _parseThemeMode(prefs.getString(themeModeKey)),
      locale: _parseLocale(prefs.getString(localeKey)),
    );
    p._prefs = prefs;
    return p;
  }

  ThemeMode get themeMode => _themeMode;

  /// The chosen language, or null to follow the device language.
  Locale? get locale => _locale;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, mode.name);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale != null &&
        !supportedLanguageCodes.contains(locale.languageCode)) {
      return;
    }
    if (locale?.languageCode == _locale?.languageCode) return;
    _locale = locale == null ? null : Locale(locale.languageCode);
    notifyListeners();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    if (_locale == null) {
      await prefs.remove(localeKey);
    } else {
      await prefs.setString(localeKey, _locale!.languageCode);
    }
  }

  static ThemeMode _parseThemeMode(String? value) => ThemeMode.values
      .firstWhere((m) => m.name == value, orElse: () => ThemeMode.system);

  static Locale? _parseLocale(String? value) =>
      value != null && supportedLanguageCodes.contains(value)
      ? Locale(value)
      : null;
}
