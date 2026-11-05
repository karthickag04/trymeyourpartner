import 'package:flutter/material.dart';

import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
import '../theme/constants.dart';

/// A small red pill with a count ("3", "99+"). [semanticLabel] describes the
/// count for screen readers, e.g. "3 new interests".
class CountBadge extends StatelessWidget {
  final int count;
  final String? semanticLabel;
  final int max;
  const CountBadge({
    super.key,
    required this.count,
    this.semanticLabel,
    this.max = 99,
  });

  @override
  Widget build(BuildContext context) {
    final text = count > max
        ? context.l10n.countOverflow(max)
        : context.formatNumber(count);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: context.palette.error,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM + 2),
      ),
      child: Semantics(
        label: semanticLabel ?? text,
        excludeSemantics: true,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.styles.micro.copyWith(
            color: context.colors.onError,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
