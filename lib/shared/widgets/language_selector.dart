import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/preferences/user_preferences.dart';
import '../../l10n/l10n.dart';

/// Display name of each supported language, written in that language.
String languageName(BuildContext context, String code) => switch (code) {
  'ta' => context.l10n.languageTamil,
  _ => context.l10n.languageEnglish,
};

/// A compact button that shows the current language and lets the visitor
/// switch it. Used where there is no settings page yet (sign-in,
/// registration).
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      tooltip: context.l10n.languageChooseTooltip,
      initialValue: current,
      onSelected: (code) =>
          context.read<UserPreferences>().setLocale(Locale(code)),
      itemBuilder: (context) => [
        for (final code in UserPreferences.supportedLanguageCodes)
          PopupMenuItem(value: code, child: Text(languageName(context, code))),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate),
              const SizedBox(width: 8),
              Text(languageName(context, current)),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
