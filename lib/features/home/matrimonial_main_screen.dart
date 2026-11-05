import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
// Legacy notifications are now hidden in favor of unified notifications.
// import '../screens/notification_center_screen.dart';
import '../notifications/notifications_service.dart';
import '../../l10n/formatters.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';

/// The tabbed main screen. Each tab has its own URL; [shell] (from the router)
/// keeps every tab's state while switching.
class MatrimonialMainScreen extends StatefulWidget {
  final StatefulNavigationShell shell;
  const MatrimonialMainScreen({super.key, required this.shell});

  @override
  State<MatrimonialMainScreen> createState() => _MatrimonialMainScreenState();
}

class _MatrimonialMainScreenState extends State<MatrimonialMainScreen> {
  final _notifService = NotificationsService();

  List<BottomNavigationBarItem> _buildNavItems(BuildContext context) {
    final l = context.l10n;
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_rounded),
        label: l.navHome,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.favorite_rounded),
        label: l.navMatches,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.search_rounded),
        label: l.navSearch,
      ),
      BottomNavigationBarItem(icon: _InterestsIcon(), label: l.navInterests),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_rounded),
        label: l.navProfile,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // ProxyProvider in main.dart handles loading on auth changes.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<MatrimonialProvider>().currentUserProfile;
      if (p == null) return;
      await _notifService.subscribeForProfile(
        profileId: p.id,
        onInsert: (row) {
          if (!mounted) return;
          final type = row['type'] as String?;
          if (type == null) return;
          final l = context.l10n;
          String text;
          if (type == 'message') {
            text =
                (row['payload'] as Map<String, dynamic>?)?['message']
                    ?.toString() ??
                l.toastNewMessage;
          } else if (type == 'interest_sent') {
            text = l.toastInterestReceived;
          } else if (type == 'interest_accepted') {
            text = l.toastInterestAccepted;
          } else if (type == 'interest_rejected') {
            text = l.toastInterestRejected;
          } else {
            text = l.toastNewNotification;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(text),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              // No inline open action; unified notifications available from Home bell
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MatrimonialProvider>(
        builder: (context, p, child) {
          // Show lightweight realtime toasts
          final msg = p.takeRealtimeToast();
          if (msg != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messenger = ScaffoldMessenger.maybeOf(context);
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(_toastText(context, msg)),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            });
          }
          return widget.shell;
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: context.palette.shadow,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.shell.currentIndex,
          // Tapping the current tab again returns it to its first page.
          onTap: (index) => widget.shell.goBranch(
            index,
            initialLocation: index == widget.shell.currentIndex,
          ),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: context.styles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: context.styles.overline.copyWith(
            fontWeight: FontWeight.w500,
          ),
          items: _buildNavItems(context),
        ),
      ),
    );
  }
}

/// The provider reports realtime events with fixed English messages; show
/// them in the member's language.
String _toastText(BuildContext context, String message) {
  final l = context.l10n;
  return switch (message) {
    'You have a new interest' => l.toastInterestReceived,
    'Interests updated' => l.toastInterestsUpdated,
    'Your interest was accepted' => l.toastInterestAccepted,
    'An interest was withdrawn' => l.toastInterestWithdrawn,
    _ => message,
  };
}

class _InterestsIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_rounded),
        Positioned(right: -6, top: -2, child: _InterestsBadge()),
      ],
    );
  }
}

class _InterestsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<
      // ignore: always_specify_types
      MatrimonialProvider
    >(
      builder: (context, p, _) {
        final c = p.receivedInterests.length;
        if (c == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: context.palette.error,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(minWidth: 16),
          child: Semantics(
            label: context.l10n.interestsBadgeLabel(c),
            excludeSemantics: true,
            child: Text(
              context.formatNumber(c),
              style: context.styles.micro.copyWith(
                color: context.colors.onError,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
