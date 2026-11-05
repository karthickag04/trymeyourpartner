import 'package:flutter/material.dart';

/// Design tokens: the single source for colour roles, spacing, radii and
/// sizes. Screens read colours from the theme (`context.palette`,
/// `Theme.of(context).colorScheme`) so light and dark both work; nothing in
/// `lib/features` should use raw `Color(...)` values.

/// Brand colour roles that the Material [ColorScheme] does not cover.
///
/// Every role has a light and a dark value. Text roles (`textPrimary`,
/// `textSecondary`, `textTertiary`, and the status colours used for text)
/// meet a 4.5:1 contrast ratio against `background`, `surface` and
/// `cardBackground` in both themes; `test/theme_tokens_test.dart` checks this.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Main brand red: headings, prices, primary actions on brand screens.
  final Color primary;

  /// Text and icons placed on [primary] (and on [accent]).
  final Color onPrimary;

  /// Soft brand tint used as a container behind brand-coloured content.
  final Color secondary;

  /// Deeper brand red used for emphasis and brand buttons.
  final Color accent;

  /// Page background.
  final Color background;

  /// Raised areas: forms, sheets, sections.
  final Color surface;

  /// Slightly darker/lighter than [surface]: chips, input fills, placeholders.
  final Color surfaceMuted;

  /// Card background.
  final Color cardBackground;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color divider;
  final Color shadow;

  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  /// Background tints behind status messages (error, success, warning, info).
  final Color errorContainer;
  final Color successContainer;
  final Color warningContainer;
  final Color infoContainer;

  /// Heart / like icon colour.
  final Color heartRed;

  /// Light brand tint used for highlights and selected chips.
  final Color lightRed;

  /// Premium / gold badge colour.
  final Color premium;

  /// Fixed dark backdrop behind photos and the splash screen. It stays dark
  /// in both themes, so content on it uses [onImage].
  final Color imageScrim;

  /// Text and icons placed over photos, gradients and [imageScrim].
  final Color onImage;

  /// Brand gradient used for hero headers.
  final List<Color> brandGradient;

  const AppPalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.shadow,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.errorContainer,
    required this.successContainer,
    required this.warningContainer,
    required this.infoContainer,
    required this.heartRed,
    required this.lightRed,
    required this.premium,
    required this.imageScrim,
    required this.onImage,
    required this.brandGradient,
  });

  /// Light values: the app's existing red / white / black look.
  static const light = AppPalette(
    primary: Color(0xFFDC143C),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFFFEBEE),
    accent: Color(0xFFB71C1C),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAFA),
    surfaceMuted: Color(0xFFF1F3F5),
    cardBackground: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A202C),
    textSecondary: Color(0xFF424242),
    textTertiary: Color(0xFF666666),
    divider: Color(0xFFE0E0E0),
    shadow: Color(0x1A000000),
    error: Color(0xFFC62828),
    success: Color(0xFF2E7D32),
    warning: Color(0xFFB45309),
    info: Color(0xFF1565C0),
    errorContainer: Color(0xFFFDECEA),
    successContainer: Color(0xFFE8F5E9),
    warningContainer: Color(0xFFFFF4E5),
    infoContainer: Color(0xFFE3F2FD),
    heartRed: Color(0xFFE53E3E),
    lightRed: Color(0xFFFFCDD2),
    premium: Color(0xFFB7791F),
    imageScrim: Color(0xFF0A0A0A),
    onImage: Color(0xFFFFFFFF),
    brandGradient: [Color(0xFFD81B60), Color(0xFFDC143C)],
  );

  /// Dark values: designed for a dark background, not inverted. Brand reds
  /// are lightened so they stay readable, and content on them turns dark.
  static const dark = AppPalette(
    primary: Color(0xFFFF7A8E),
    onPrimary: Color(0xFF1A0006),
    secondary: Color(0xFF3B1A20),
    accent: Color(0xFFFF8A80),
    background: Color(0xFF121212),
    surface: Color(0xFF1C1C1E),
    surfaceMuted: Color(0xFF2A2A2D),
    cardBackground: Color(0xFF232326),
    textPrimary: Color(0xFFECECEC),
    textSecondary: Color(0xFFC2C2C2),
    textTertiary: Color(0xFFA0A0A0),
    divider: Color(0xFF3A3A3D),
    shadow: Color(0x66000000),
    error: Color(0xFFFF8A80),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF90CAF9),
    errorContainer: Color(0xFF3D1F1F),
    successContainer: Color(0xFF1E3322),
    warningContainer: Color(0xFF3A2C15),
    infoContainer: Color(0xFF1A2B3D),
    heartRed: Color(0xFFFF6B6B),
    lightRed: Color(0xFF4A2027),
    premium: Color(0xFFF6C453),
    imageScrim: Color(0xFF0A0A0A),
    onImage: Color(0xFFFFFFFF),
    brandGradient: [Color(0xFF8E1240), Color(0xFF9B1028)],
  );

  @override
  AppPalette copyWith({Color? primary, Color? onPrimary}) => AppPalette(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    secondary: secondary,
    accent: accent,
    background: background,
    surface: surface,
    surfaceMuted: surfaceMuted,
    cardBackground: cardBackground,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    divider: divider,
    shadow: shadow,
    error: error,
    success: success,
    warning: warning,
    info: info,
    errorContainer: errorContainer,
    successContainer: successContainer,
    warningContainer: warningContainer,
    infoContainer: infoContainer,
    heartRed: heartRed,
    lightRed: lightRed,
    premium: premium,
    imageScrim: imageScrim,
    onImage: onImage,
    brandGradient: brandGradient,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      secondary: l(secondary, other.secondary),
      accent: l(accent, other.accent),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      cardBackground: l(cardBackground, other.cardBackground),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      divider: l(divider, other.divider),
      shadow: l(shadow, other.shadow),
      error: l(error, other.error),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      errorContainer: l(errorContainer, other.errorContainer),
      successContainer: l(successContainer, other.successContainer),
      warningContainer: l(warningContainer, other.warningContainer),
      infoContainer: l(infoContainer, other.infoContainer),
      heartRed: l(heartRed, other.heartRed),
      lightRed: l(lightRed, other.lightRed),
      premium: l(premium, other.premium),
      imageScrim: l(imageScrim, other.imageScrim),
      onImage: l(onImage, other.onImage),
      brandGradient: [
        for (var i = 0; i < brandGradient.length; i++)
          l(brandGradient[i], other.brandGradient[i]),
      ],
    );
  }
}

/// Spacing, radii and sizes (the same in every theme).
class AppDimensions {
  static const double paddingXXS = 2.0;
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingSM = 12.0;
  static const double paddingM = 16.0;
  static const double paddingML = 20.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  static const double radiusPill = 999.0;

  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  /// Minimum size of anything that can be tapped (Material guidance).
  static const double minTapTarget = 48.0;

  static const double cardHeight = 200.0;
  static const double cardWidth = 140.0;
  static const double bannerHeight = 400.0;

  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 80.0;
}

/// Shorthands for reading theme tokens in widgets.
extension ThemeTokens on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
  AppTextStyles get styles => AppTextStyles(Theme.of(this).textTheme);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Named text styles taken from the active theme's [TextTheme], so they follow
/// light/dark mode and the locale's font.
class AppTextStyles {
  final TextTheme _t;
  const AppTextStyles(this._t);

  TextStyle get heading1 => _t.headlineLarge!;
  TextStyle get heading2 => _t.headlineMedium!;
  TextStyle get heading3 => _t.headlineSmall!;
  TextStyle get title => _t.titleLarge!;
  TextStyle get subtitle1 => _t.titleMedium!;
  TextStyle get subtitle2 => _t.titleSmall!;
  TextStyle get body1 => _t.bodyLarge!;
  TextStyle get body2 => _t.bodyMedium!;
  TextStyle get caption => _t.bodySmall!;
  TextStyle get button => _t.labelLarge!;
  TextStyle get label => _t.labelMedium!;
  TextStyle get overline => _t.labelSmall!;

  /// 10px text for badges and dense cards only.
  TextStyle get micro => _t.labelSmall!.copyWith(fontSize: 10);
}
