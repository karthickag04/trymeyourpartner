import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/state/matrimonial_provider.dart';
import 'home_screen.dart';
import '../discovery/matches_screen.dart';
import '../discovery/search_screen.dart';
import '../interests/interests_screen.dart';
import '../profile/profile_screen.dart';
// Legacy notifications are now hidden in favor of unified notifications.
// import '../screens/notification_center_screen.dart';
import '../notifications/notifications_service.dart';

class MatrimonialMainScreen extends StatefulWidget {
  const MatrimonialMainScreen({super.key});

  @override
  State<MatrimonialMainScreen> createState() => _MatrimonialMainScreenState();
}

class _MatrimonialMainScreenState extends State<MatrimonialMainScreen> {
  int _currentIndex = 0;
  final _notifService = NotificationsService();

  final List<Widget> _screens = [
    const NewMatrimonialHomeScreen(),
    const MatchesScreen(),
    const SearchScreen(),
    const InterestsScreen(),
    const ProfileScreen(),
  ];

  List<BottomNavigationBarItem> _buildNavItems(BuildContext context) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.favorite_rounded),
        label: 'Matches',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_rounded),
        label: 'Search',
      ),
      BottomNavigationBarItem(icon: _InterestsIcon(), label: 'Interests'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Profile',
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
          String text;
          if (type == 'message') {
            text =
                (row['payload'] as Map<String, dynamic>?)?['message']
                    ?.toString() ??
                'New message';
          } else if (type == 'interest_sent') {
            text = 'You received a new interest';
          } else if (type == 'interest_accepted') {
            text = 'Your interest was accepted';
          } else if (type == 'interest_rejected') {
            text = 'Your interest was rejected';
          } else {
            text = 'New notification';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restore last selected tab if available to prevent jumps back to Home on rebuilds
    int? stored;
    try {
      stored =
          PageStorage.of(
                context,
              ).readState(context, identifier: 'main_tab_index')
              as int?;
    } catch (_) {}
    if (stored != null && stored != _currentIndex) {
      setState(() => _currentIndex = stored!);
    }
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
                  content: Text(msg),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            });
          }
          return IndexedStack(index: _currentIndex, children: _screens);
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Persist the selected tab so a rebuild doesn't reset it to 0
            try {
              PageStorage.of(context).writeState(
                context,
                _currentIndex,
                identifier: 'main_tab_index',
              );
            } catch (_) {}
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: _buildNavItems(context),
        ),
      ),
    );
  }
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
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(minWidth: 16),
          child: Text(
            '$c',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
