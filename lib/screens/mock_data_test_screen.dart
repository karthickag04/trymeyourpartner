import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/matrimonial_provider.dart';
import '../widgets/profile_card.dart';

class MockDataTestScreen extends StatefulWidget {
  const MockDataTestScreen({super.key});

  @override
  State<MockDataTestScreen> createState() => _MockDataTestScreenState();
}

class _MockDataTestScreenState extends State<MockDataTestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTestData();
    });
  }

  Future<void> _loadTestData() async {
    final provider = Provider.of<MatrimonialProvider>(context, listen: false);

    // Initialize the provider (this will check database availability)
    await provider.initialize();

    // Load current user profile (will use mock data if database is not available)
    await provider.loadCurrentUserProfile('test_user_id');

    // Load matches (will use mock data if database is not available)
    await provider.loadMatches('test_user_id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Data Test'),
        backgroundColor: Colors.pink[100],
      ),
      body: Consumer<MatrimonialProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading matrimonial data...'),
                  Text(
                    'If database is not available, mock data will be used',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTestData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data source indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: provider.isInitialized
                        ? Colors.green[50]
                        : Colors.orange[50],
                    border: Border.all(
                      color: provider.isInitialized
                          ? Colors.green
                          : Colors.orange,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            provider.isInitialized
                                ? Icons.check_circle
                                : Icons.warning,
                            color: provider.isInitialized
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Data Source',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: provider.isInitialized
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The app is currently using ${provider.isInitialized ? 'database or mock' : 'unknown'} data. '
                        'If Supabase database is not available, mock data will be automatically used.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Current user profile section
                if (provider.currentUserProfile != null) ...[
                  const Text(
                    'Your Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ProfileCard(
                    profile: provider.currentUserProfile!,
                    onTap: () {},
                    isShortlisted: false, // Default for test screen
                  ),
                  const SizedBox(height: 24),
                ],

                // Matches section
                const Text(
                  'Potential Matches',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (provider.matchedProfiles.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No matches found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.matchedProfiles.length,
                    itemBuilder: (context, index) {
                      final profile = provider.matchedProfiles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProfileCard(
                          profile: profile,
                          onTap: () {
                            // Show profile details
                            _showProfileDetails(context, profile);
                          },
                          isShortlisted: false, // Default for mock test screen
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTestData,
        backgroundColor: Colors.pink[300],
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showProfileDetails(BuildContext context, profile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(profile.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Age: ${profile.age}'),
                Text('Location: ${profile.city}, ${profile.district}'),
                Text('Caste: ${profile.caste}'),
                Text('Education: ${profile.education}'),
                Text('Occupation: ${profile.occupation}'),
                Text('Height: ${profile.heightInFeetInches}'),
                const SizedBox(height: 12),
                Text('About: ${profile.aboutMe ?? "No description available"}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Interest sent to ${profile.name}!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Send Interest'),
            ),
          ],
        );
      },
    );
  }
}
