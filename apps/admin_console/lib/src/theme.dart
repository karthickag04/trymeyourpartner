import 'package:flutter/material.dart';

/// Brand crimson, shared with the member app.
const brandColor = Color(0xFFDC143C);

ThemeData consoleTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
