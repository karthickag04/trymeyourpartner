// Deprecated: replaced by UnifiedNotificationsScreen and NotificationsPagerScreen.
// Kept for reference; not used in navigation. Consider deleting after verification.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/matrimonial_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_card_horizontal.dart';
import 'profile_detail_screen.dart';

@Deprecated('Use UnifiedNotificationsScreen/NotificationsPagerScreen')
class _LegacyNotificationsScreen extends StatefulWidget {
  _LegacyNotificationsScreen()
    : assert(() {
        // Prevent accidental usage in debug builds
        // ignore: avoid_print
        print('Deprecated _LegacyNotificationsScreen constructed');
        return true;
      }());

  @override
  State<_LegacyNotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_LegacyNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final mat = context.read<MatrimonialProvider>();
      final uid = auth.user?.id;
      if (uid != null) {
        await Future.wait([
          mat.loadReceivedInterests(uid),
          mat.loadAcceptedConnections(uid),
          mat.loadSentInterests(uid),
        ]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Accepted'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_requestsTab(), _acceptedTab()],
      ),
    );
  }

  Widget _requestsTab() {
    return Consumer2<MatrimonialProvider, AuthProvider>(
      builder: (context, mat, auth, _) {
        final items = mat.receivedInterests;
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border,
            title: 'No new requests',
            subtitle: 'Interests received will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = items[index];
            return ProfileCardHorizontal(
              profile: p,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailScreen(profile: p),
                  ),
                );
              },
              onAccept: () async {
                final uid = auth.user?.id;
                if (uid == null) return;
                await mat.acceptInterest(
                  fromProfileId: p.id,
                  toAuthUserId: uid,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Accepted interest from ${p.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onReject: () async {
                final uid = auth.user?.id;
                if (uid == null) return;
                await mat.rejectInterest(
                  fromProfileId: p.id,
                  toAuthUserId: uid,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Declined interest from ${p.name}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              isShortlisted: false,
              isInterestSent: context
                  .read<MatrimonialProvider>()
                  .isInterestSent(p.id),
            );
          },
        );
      },
    );
  }

  Widget _acceptedTab() {
    return Consumer<MatrimonialProvider>(
      builder: (context, mat, _) {
        final items = mat.acceptedConnections;
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No accepted connections yet',
            subtitle: 'When interests are accepted, they appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = items[index];
            return ProfileCardHorizontal(
              profile: p,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileDetailScreen(profile: p),
                  ),
                );
              },
              isShortlisted: mat.isProfileShortlisted(p.id),
              isInterestSent: context
                  .read<MatrimonialProvider>()
                  .isInterestSent(p.id),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
