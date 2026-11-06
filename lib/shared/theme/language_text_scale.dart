import 'package:flutter/widgets.dart';

/// Tamil letters are wider and taller than Latin ones at the same font size,
/// and Tamil words are longer, so the same layout overflows. Tamil text is
/// drawn at 90 %: enough to fit English-sized layouts, while staying readable
/// for older family members. Anything below about 0.88 hurts readability.
const Map<String, double> languageTextScale = {'ta': 0.9};

double textScaleFor(Locale? locale) =>
    languageTextScale[locale?.languageCode] ?? 1.0;

/// Multiplies the member's own font-size setting (accessibility) by the
/// language factor, so larger system text still means larger app text.
class LanguageTextScaler extends TextScaler {
  const LanguageTextScaler(this.inner, this.factor);

  final TextScaler inner;
  final double factor;

  @override
  double scale(double fontSize) => inner.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => inner.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is LanguageTextScaler &&
      other.inner == inner &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(inner, factor);
}

/// Applies the language factor and the member's text-size choice
/// ([memberFactor], Settings > Text size) to everything below it, on top of
/// the phone's own font-size setting.
class LanguageTextScale extends StatelessWidget {
  const LanguageTextScale({
    super.key,
    required this.child,
    this.memberFactor = 1.0,
  });

  final Widget child;
  final double memberFactor;

  @override
  Widget build(BuildContext context) {
    final factor =
        textScaleFor(Localizations.maybeLocaleOf(context)) * memberFactor;
    if (factor == 1.0) return child;
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(textScaler: LanguageTextScaler(mq.textScaler, factor)),
      child: child,
    );
  }
}
