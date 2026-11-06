import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/shared/theme/theme.dart';
import 'package:trymeyourpartner/shared/theme/tokens.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in {
    'light': AppPalette.light,
    'dark': AppPalette.dark,
  }.entries) {
    final p = entry.value;
    group('${entry.key} palette', () {
      final backgrounds = {
        'background': p.background,
        'surface': p.surface,
        'cardBackground': p.cardBackground,
      };
      final textRoles = {
        'textPrimary': p.textPrimary,
        'textSecondary': p.textSecondary,
        'textTertiary': p.textTertiary,
        'primary': p.primary,
        'accent': p.accent,
        'error': p.error,
        'success': p.success,
        'warning': p.warning,
        'info': p.info,
      };
      for (final t in textRoles.entries) {
        for (final b in backgrounds.entries) {
          test('${t.key} on ${b.key} is at least 4.5:1', () {
            expect(contrast(t.value, b.value), greaterThanOrEqualTo(4.5));
          });
        }
      }
      for (final fill in {
        'primary': p.primary,
        'accent': p.accent,
        'success': p.success,
      }.entries) {
        test('onPrimary on ${fill.key} is at least 4.5:1', () {
          expect(contrast(p.onPrimary, fill.value), greaterThanOrEqualTo(4.5));
        });
      }
      test('onImage on imageScrim is at least 4.5:1', () {
        expect(contrast(p.onImage, p.imageScrim), greaterThanOrEqualTo(4.5));
      });
      test('text on the status containers is at least 4.5:1', () {
        for (final c in [
          p.errorContainer,
          p.successContainer,
          p.warningContainer,
          p.infoContainer,
          p.secondary,
          p.surfaceMuted,
        ]) {
          expect(contrast(p.textPrimary, c), greaterThanOrEqualTo(4.5));
          expect(contrast(p.textSecondary, c), greaterThanOrEqualTo(4.5));
        }
      });
    });
  }

  for (final build in [AppTheme.light, AppTheme.dark]) {
    group('ColorScheme from ${build == AppTheme.light ? 'light' : 'dark'}', () {
      testWidgets('on-colours meet 4.5:1', (_) async {
        final s = build(null).colorScheme;
        expect(contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(s.onError, s.error), greaterThanOrEqualTo(4.5));
        expect(contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
        expect(
          contrast(s.onSurfaceVariant, s.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(s.onPrimaryContainer, s.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(s.onInverseSurface, s.inverseSurface),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(s.primary, s.surface), greaterThanOrEqualTo(4.5));
      });
      testWidgets('every theme carries the brand palette', (_) async {
        expect(build(null).extension<AppPalette>(), isNotNull);
      });
    });
  }

  testWidgets('light and dark themes have the expected brightness', (_) async {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });

  // ThemeData tests run as widget tests: google_fonts then never reaches the
  // network, which plain tests would try (and fail) to do.
  testWidgets('Tamil uses the Noto Sans Tamil font', (_) async {
    final ta = AppTheme.light(const Locale('ta'));
    expect(ta.textTheme.bodyMedium?.fontFamily, contains('NotoSansTamil'));
    final en = AppTheme.light(const Locale('en'));
    expect(en.textTheme.bodyMedium?.fontFamily, contains('Inter'));
  });
}
