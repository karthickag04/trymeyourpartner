// Deprecated: replaced by UnifiedNotificationsScreen/NotificationsPagerScreen.
// Kept only for reference; not used in navigation.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import '../../app/di/service_locator.dart';
import 'notifications_service.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';

@Deprecated('Use UnifiedNotificationsScreen/NotificationsPagerScreen')
class _LegacyNotificationCenterScreen extends StatefulWidget {
  const _LegacyNotificationCenterScreen();

  @override
  State<_LegacyNotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends State<_LegacyNotificationCenterScreen> {
  // Supabase-only realtime helper; used only when backendMode == supabase
  final _legacyRealtime = NotificationsService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void dispose() {
    // Safe to call; will be a no-op if not subscribed
    _legacyRealtime.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<MatrimonialProvider>().currentUserProfile;
      if (p == null) {
        setState(() => _loading = false);
        return;
      }
      await _load(p.id);
      if (sl.backendMode == BackendMode.supabase) {
        await _legacyRealtime.subscribeForProfile(
          profileId: p.id,
          onInsert: (row) {
            if (!mounted) return;
            setState(() {
              _items.insert(0, row);
            });
          },
        );
      }
    });
  }

  Future<void> _load(String profileId) async {
    setState(() => _loading = true);
    final list = await sl.notificationService.fetchNotifications(profileId);
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _markRead(String id) async {
    await sl.notificationService.markRead(id);
    if (!mounted) return;
    setState(() {
      final idx = _items.indexWhere((e) => e['id'] == id);
      if (idx >= 0)
        _items[idx] = {
          ..._items[idx],
          'read_at': DateTime.now().toIso8601String(),
        };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.notificationsMarkAllRead,
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: () async {
              final p = context.read<MatrimonialProvider>().currentUserProfile;
              if (p == null) return;
              await sl.notificationService.markAllRead(p.id);
              if (!mounted) return;
              setState(() {
                _items = _items
                    .map(
                      (e) => {
                        ...e,
                        'read_at': DateTime.now().toIso8601String(),
                      },
                    )
                    .toList();
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = _items[index];
                final type = (n['type'] as String?) ?? 'system';
                final payload = (n['payload'] as Map<String, dynamic>?);
                final read = n['read_at'] != null;
                final title = _titleFor(type, payload);
                final subtitle = _subtitleFor(type, payload);
                return ListTile(
                  leading: Icon(
                    _iconFor(type),
                    color: read
                        ? context.palette.textTertiary
                        : context.colors.primary,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(subtitle),
                  trailing: read
                      ? null
                      : TextButton(
                          onPressed: () => _markRead(n['id'] as String),
                          child: Text(context.l10n.notificationsMarkRead),
                        ),
                );
              },
            ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'message':
        return Icons.message_outlined;
      case 'interest_sent':
        return Icons.favorite_border;
      case 'interest_accepted':
        return Icons.favorite;
      default:
        return Icons.notifications_none;
    }
  }

  String _titleFor(String type, Map<String, dynamic>? payload) {
    final l = context.l10n;
    switch (type) {
      case 'message':
        return l.notificationNewMessage;
      case 'interest_sent':
        return l.notificationNewInterest;
      case 'interest_accepted':
        return l.notificationInterestAccepted;
      default:
        return l.notificationGeneric;
    }
  }

  String _subtitleFor(String type, Map<String, dynamic>? payload) {
    if (payload == null) return '';
    if (type == 'message') {
      return payload['message']?.toString() ?? '';
    }
    return '';
  }
}
