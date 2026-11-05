import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/services/presence_service.dart';
import '../../../shared/models/presence_status.dart';

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
    final color = online ? Colors.green : Colors.grey;
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (!widget.showText) return dot;
    final text = online ? 'Online' : _formatLastSeen(s?.lastActiveAt);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: widget.textColor ?? Colors.white70,
          ),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime? last) {
    if (last == null) return 'Offline';
    final now = DateTime.now();
    final diff = now.difference(last);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m == 1 ? '1 minute ago' : '$m minutes ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? 'An hour ago' : '$h hours ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      if (d == 1) return 'Yesterday';
      return '$d days ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return w == 1 ? 'A week ago' : '$w weeks ago';
    }
    final months = (diff.inDays / 30).floor();
    return months == 1 ? 'A month ago' : '$months months ago';
  }
}
