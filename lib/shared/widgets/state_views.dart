import 'package:flutter/material.dart';

import '../theme/constants.dart';

/// Centered icon, title, explanation and an optional next action, for empty
/// lists and similar states.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: palette.textTertiary),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.styles.title.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: context.styles.body2.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDimensions.paddingM),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A spinner with a short message underneath.
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: context.colors.primary),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.paddingM),
            Text(message!, style: context.styles.body2),
          ],
        ],
      ),
    );
  }
}
