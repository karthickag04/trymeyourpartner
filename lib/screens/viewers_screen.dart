import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/matrimonial_provider.dart';
import '../utils/constants.dart';
import '../widgets/profile_card_horizontal.dart';
import 'profile_detail_screen.dart';

class ViewersScreen extends StatelessWidget {
  const ViewersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('People who viewed you'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer2<AuthProvider, MatrimonialProvider>(
        builder: (context, auth, provider, child) {
          final userId = auth.user?.id;
          return RefreshIndicator(
            onRefresh: () async {
              if (userId != null) {
                await provider.loadViewersOfMe(userId);
              }
            },
            child: _buildBody(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MatrimonialProvider provider) {
    if (provider.viewersOfMe.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: AppDimensions.iconXL * 1.5,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              const Text(
                'No profile views yet',
                style: AppTextStyles.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              const Text(
                'We’ll show people who viewed your profile here',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: provider.viewersOfMe.length,
      itemBuilder: (context, index) {
        final profile = provider.viewersOfMe[index];
        final matrimonialProvider = context.read<MatrimonialProvider>();
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
          onInterest: () => matrimonialProvider.sendInterest(profile.id),
          isInterestSent: matrimonialProvider.isInterestSent(profile.id),
          onShortlist: () => matrimonialProvider.toggleShortlist(profile.id),
          isShortlisted: matrimonialProvider.isProfileShortlisted(profile.id),
        );
      },
    );
  }
}
