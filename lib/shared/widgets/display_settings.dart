import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/preferences/user_preferences.dart';
import '../../l10n/l10n.dart';
import '../theme/constants.dart';
import 'language_selector.dart';

/// Appearance (System / Light / Dark) and Language (English / தமிழ்)
/// controls. Both change the app at once and are remembered on the device.
class DisplaySettings extends StatelessWidget {
  const DisplaySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<UserPreferences>();
    final l = context.l10n;
    final current = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(icon: Icons.brightness_6_outlined, text: l.settingsAppearance),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(l.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(l.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(l.themeDark),
              ),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (s) => prefs.setThemeMode(s.first),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        _Label(icon: Icons.translate, text: l.languageLabel),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final code in UserPreferences.supportedLanguageCodes)
                ButtonSegment(
                  value: code,
                  label: Text(languageName(context, code)),
                ),
            ],
            selected: {current},
            onSelectionChanged: (s) => prefs.setLocale(Locale(s.first)),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Label({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconS + 4,
            color: context.colors.primary,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Text(text, style: context.styles.subtitle2),
        ],
      ),
    );
  }
}
