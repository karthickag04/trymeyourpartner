import 'package:flutter/material.dart';
import '../widgets/storage_image.dart';
import 'package:provider/provider.dart';
import '../providers/matrimonial_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_card_horizontal.dart';
import 'profile_detail_screen.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load interests when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final matrimonialProvider = context.read<MatrimonialProvider>();

      if (authProvider.user != null) {
        matrimonialProvider.loadReceivedInterests(authProvider.user!.id);
        matrimonialProvider.loadSentInterests(authProvider.user!.id);
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
        title: const Text('Interests'),
        backgroundColor: Colors.pink.shade50,
        elevation: 0,
        foregroundColor: Colors.pink.shade800,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReceivedInterests(), _buildSentInterests()],
      ),
    );
  }

  Widget _buildReceivedInterests() {
    return Consumer<MatrimonialProvider>(
      builder: (context, matrimonialProvider, child) {
        if (matrimonialProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 16),
                Text('Loading received interests...'),
              ],
            ),
          );
        }

        final receivedInterests = matrimonialProvider.receivedInterests;

        if (receivedInterests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No interests received yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'When someone shows interest in your profile,\nthey will appear here.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.pink.shade50,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receivedInterests.length,
            itemBuilder: (context, index) {
              final profile = receivedInterests[index];
              return ProfileCardHorizontal(
                profile: profile,
                onTap: () => _showProfileDetails(profile),
                onAccept: () => _acceptInterest(profile),
                onReject: () => _declineInterest(profile),
                isShortlisted: false,
                isInterestSent: context
                    .read<MatrimonialProvider>()
                    .isInterestSent(profile.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSentInterests() {
    return Consumer<MatrimonialProvider>(
      builder: (context, matrimonialProvider, child) {
        if (matrimonialProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 16),
                Text('Loading sent interests...'),
              ],
            ),
          );
        }

        final sentInterests = matrimonialProvider.sentInterests;

        if (sentInterests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No interests sent yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Browse profiles and send interests\nto start connecting.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          color: Colors.pink.shade50,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sentInterests.length,
            itemBuilder: (context, index) {
              final profile = sentInterests[index];
              return ProfileCardHorizontal(
                profile: profile,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailScreen(profile: profile),
                    ),
                  );
                },
                isShortlisted: false,
                isInterestSent: context
                    .read<MatrimonialProvider>()
                    .isInterestSent(profile.id),
              );
            },
          ),
        );
      },
    );
  }

  void _showProfileDetails(dynamic profile) {
    // Show profile details modal - similar to search screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child:
                              (profile.profileImageUrl != null &&
                                  profile.profileImageUrl!.isNotEmpty)
                              ? StorageImage(
                                  src: profile.profileImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: Center(
                                    child: Text(
                                      profile.name.isNotEmpty
                                          ? profile.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  emptyWidget: Center(
                                    child: Text(
                                      profile.name.isNotEmpty
                                          ? profile.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    profile.name.isNotEmpty
                                        ? profile.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${profile.age} years • ${profile.city}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  profile.aboutMe ?? 'No information provided',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _acceptInterest(dynamic profile) {
    final auth = context.read<AuthProvider>();
    final mat = context.read<MatrimonialProvider>();
    final uid = auth.user?.id;
    if (uid == null) return;
    mat
        .acceptInterest(fromProfileId: profile.id, toAuthUserId: uid)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Interest from ${profile.name} accepted!'),
              backgroundColor: Colors.green,
            ),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept interest: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  void _declineInterest(dynamic profile) {
    final auth = context.read<AuthProvider>();
    final mat = context.read<MatrimonialProvider>();
    final uid = auth.user?.id;
    if (uid == null) return;
    mat
        .rejectInterest(fromProfileId: profile.id, toAuthUserId: uid)
        .then((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Interest from ${profile.name} declined'),
              backgroundColor: Colors.orange,
            ),
          );
        })
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to decline interest: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }
}
