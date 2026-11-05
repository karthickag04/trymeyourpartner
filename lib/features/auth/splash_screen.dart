import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../shared/theme/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo scale animation
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Text fade animation
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    // Slide animation for tagline
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );
  }

  void _startSplashSequence() async {
    // Start logo animation
    await _logoController.forward();

    // Small delay then start text animation
    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();

    // Wait a bit more then navigate
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      _navigateToApp();
    }
  }

  void _navigateToApp() {
    // The router sends signed-out visitors to /login.
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              Color(0xFF0A0A0A),
              AppColors.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spacer to push content up slightly
                const Spacer(flex: 2),

                // App Logo with animation
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  color: AppColors.accent,
                                  size: 60,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // App Name with fade animation
                FadeTransition(
                  opacity: _textAnimation,
                  child: const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _textAnimation,
                    child: const Text(
                      'Learn • Stream • Grow',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Loading indicator
                FadeTransition(
                  opacity: _textAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading your experience...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
