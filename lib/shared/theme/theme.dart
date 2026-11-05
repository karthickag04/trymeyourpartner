import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Builds the light and dark [ThemeData] from the design tokens.
///
/// The font depends on the language: Inter for English, Noto Sans Tamil for
/// Tamil (Inter has no Tamil glyphs). Latin text inside Tamil screens still
/// renders with the Tamil font's Latin set, and Inter is kept as a fallback.
class AppTheme {
  AppTheme._();

  static ThemeData light([Locale? locale]) =>
      _build(_lightScheme, AppPalette.light, locale);

  static ThemeData dark([Locale? locale]) =>
      _build(_darkScheme, AppPalette.dark, locale);

  /// Kept for callers that do not care about the locale.
  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFD81B60),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFCE4EC),
    onPrimaryContainer: Color(0xFF5C0A2A),
    secondary: Color(0xFFF8BBD9),
    onSecondary: Color(0xFF2D3748),
    secondaryContainer: Color(0xFFFCE4EC),
    onSecondaryContainer: Color(0xFF5C0A2A),
    tertiary: Color(0xFF1565C0),
    onTertiary: Color(0xFFFFFFFF),
    error: Color(0xFFC62828),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFDECEA),
    onErrorContainer: Color(0xFF5F1414),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF2D3748),
    onSurfaceVariant: Color(0xFF4A5568),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFAFAFA),
    surfaceContainer: Color(0xFFF7FAFC),
    surfaceContainerHigh: Color(0xFFF1F3F5),
    surfaceContainerHighest: Color(0xFFE9ECEF),
    outline: Color(0xFF8A94A6),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF2D3748),
    onInverseSurface: Color(0xFFF7FAFC),
    inversePrimary: Color(0xFFFF8FB1),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF8FB1),
    onPrimary: Color(0xFF3E0019),
    primaryContainer: Color(0xFF7A1340),
    onPrimaryContainer: Color(0xFFFFD9E3),
    secondary: Color(0xFFE7B6C8),
    onSecondary: Color(0xFF2D1520),
    secondaryContainer: Color(0xFF4A2733),
    onSecondaryContainer: Color(0xFFFFD9E3),
    tertiary: Color(0xFF90CAF9),
    onTertiary: Color(0xFF0D2A45),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF3B0A08),
    errorContainer: Color(0xFF5F1A16),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF1C1C1E),
    onSurface: Color(0xFFECECEC),
    onSurfaceVariant: Color(0xFFC2C2C2),
    surfaceContainerLowest: Color(0xFF121212),
    surfaceContainerLow: Color(0xFF1C1C1E),
    surfaceContainer: Color(0xFF232326),
    surfaceContainerHigh: Color(0xFF2A2A2D),
    surfaceContainerHighest: Color(0xFF343438),
    outline: Color(0xFF8E8E93),
    outlineVariant: Color(0xFF3A3A3D),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFFECECEC),
    onInverseSurface: Color(0xFF1C1C1E),
    inversePrimary: Color(0xFFD81B60),
  );

  static bool _isTamil(Locale? locale) => locale?.languageCode == 'ta';

  static TextTheme _textTheme(ColorScheme s, AppPalette p) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: s.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: s.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: s.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: s.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: s.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: p.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: s.onSurfaceVariant,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: s.onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: p.textTertiary,
      ),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }

  static ThemeData _build(ColorScheme s, AppPalette p, Locale? locale) {
    final tamil = _isTamil(locale);
    final base = _textTheme(s, p);
    final textTheme = tamil
        ? GoogleFonts.notoSansTamilTextTheme(base)
        : GoogleFonts.interTextTheme(base);
    final fontFamily = tamil
        ? GoogleFonts.notoSansTamil().fontFamily
        : GoogleFonts.inter().fontFamily;
    final fallback = <String>[
      if (tamil) GoogleFonts.inter().fontFamily!,
      if (!tamil) GoogleFonts.notoSansTamil().fontFamily!,
    ];
    final isDark = s.brightness == Brightness.dark;

    const radiusM = BorderRadius.all(Radius.circular(AppDimensions.radiusM));
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppDimensions.paddingL,
      vertical: AppDimensions.paddingSM,
    );
    const minButtonSize = Size(64, AppDimensions.minTapTarget);

    return ThemeData(
      useMaterial3: true,
      brightness: s.brightness,
      colorScheme: s,
      fontFamily: fontFamily,
      fontFamilyFallback: fallback,
      textTheme: textTheme.apply(fontFamilyFallback: fallback),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [p],

      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.divider,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? s.surface : p.background,
        foregroundColor: s.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: p.shadow,
        iconTheme: IconThemeData(color: s.onSurface),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: s.onSurface,
          fontFamilyFallback: fallback,
        ),
        centerTitle: false,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? s.surface : p.background,
        selectedItemColor: s.primary,
        unselectedItemColor: isDark ? p.textTertiary : const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),

      cardTheme: CardThemeData(
        color: p.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: p.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.radiusL),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.cardBackground,
        surfaceTintColor: Colors.transparent,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.cardBackground,
        surfaceTintColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.inverseSurface,
        contentTextStyle: TextStyle(color: s.onInverseSurface),
        actionTextColor: s.inversePrimary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.primary,
          foregroundColor: s.onPrimary,
          elevation: 2,
          shadowColor: p.shadow,
          minimumSize: minButtonSize,
          shape: const RoundedRectangleBorder(borderRadius: radiusM),
          padding: buttonPadding,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButtonSize,
          shape: const RoundedRectangleBorder(borderRadius: radiusM),
          padding: buttonPadding,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.primary,
          minimumSize: minButtonSize,
          side: BorderSide(color: s.outline),
          shape: const RoundedRectangleBorder(borderRadius: radiusM),
          padding: buttonPadding,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.primary,
          minimumSize: const Size(48, AppDimensions.minTapTarget),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppDimensions.minTapTarget),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? s.surfaceContainerHigh : const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: s.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: s.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: s.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: BorderSide(color: s.error),
        ),
        labelStyle: TextStyle(color: s.onSurfaceVariant),
        hintStyle: TextStyle(color: p.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingSM,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceMuted,
        selectedColor: s.primaryContainer,
        labelStyle: TextStyle(color: s.onSurface),
        side: BorderSide(color: s.outlineVariant),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppDimensions.radiusL),
          ),
        ),
      ),

      dividerTheme: DividerThemeData(color: p.divider, thickness: 1),

      listTileTheme: ListTileThemeData(
        iconColor: s.onSurfaceVariant,
        textColor: s.onSurface,
        minVerticalPadding: AppDimensions.paddingS,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: s.primary,
        unselectedLabelColor: s.onSurfaceVariant,
        indicatorColor: s.primary,
        dividerColor: p.divider,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.primary,
        linearTrackColor: s.outlineVariant,
        circularTrackColor: s.outlineVariant,
      ),
    );
  }
}
