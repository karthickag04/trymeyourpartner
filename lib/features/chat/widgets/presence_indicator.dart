import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/services/presence_service.dart';
import '../../../l10n/formatters.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/models/presence_status.dart';
import '../../../shared/theme/constants.dart';

class PresenceIndicator extends StatefulWidget {
  final String profileId;
  final bool showText;
  final Duration pollEvery;
  final Color? textColor;
  const PresenceIndicator({
    super.key,
    required this.profileId,
    this.showText = true,
    this.pollEvery = const Duration(seconds: 60),
    this.textColor,
  });

  @override
  State<PresenceIndicator> createState() => _PresenceIndicatorState();
}

class _PresenceIndicatorState extends State<PresenceIndicator> {
  final PresenceService _presence = sl.presenceService;
  PresenceStatus? _status;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(widget.pollEvery, (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant PresenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final s = await _presence.getPresence(widget.profileId);
      if (!mounted) return;
      setState(() => _status = s);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final online = s?.isOnline ?? false;
    final palette = context.palette;
    final color = online ? palette.success : palette.textTertiary;
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final last = s?.lastActiveAt;
    final text = online
        ? context.l10n.presenceOnline
        : last == null
        ? context.l10n.presenceOffline
        : context.relativeTime(last);
    if (!widget.showText) {
      return Semantics(label: text, child: dot);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: AppDimensions.paddingXS),
        Text(
          text,
          style: context.styles.overline.copyWith(
            fontSize: 10,
            color: widget.textColor ?? palette.onImage.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
