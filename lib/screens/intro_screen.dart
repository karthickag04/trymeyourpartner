import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isVideoInitialized = false;
  bool _showSkipButton = false;
  bool _isVideoCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
    _checkFirstLaunch();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/trymeyourpartner-intro.mp4',
    );

    _videoController
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            debugPrint(
              'Video initialized. Duration: ${_videoController.value.duration}',
            );
            _videoController.play();
            _fadeController.forward();

            // Show skip button after 5 seconds (less intrusive)
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted && !_isVideoCompleted) {
                setState(() {
                  _showSkipButton = true;
                });
              }
            });
          }
        })
        .catchError((error) {
          debugPrint('Error initializing video: $error');
          // If video fails to load, skip to splash screen
          _navigateToSplash();
        });

    _videoController.addListener(() {
      // Check if video has reached the end (with small buffer for precision)
      if (_videoController.value.position >=
          _videoController.value.duration - const Duration(milliseconds: 100)) {
        if (!_isVideoCompleted &&
            _videoController.value.duration.inMilliseconds > 0) {
          _isVideoCompleted = true;
          debugPrint(
            'Video completed. Duration: ${_videoController.value.duration}',
          );
          _navigateToSplash();
        }
      }
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    // Mark as not first launch for future reference (but don't skip video)
    if (isFirstLaunch) {
      await prefs.setBool('is_first_launch', false);
    }

    // Always play full video regardless of first launch or not
    // Video will complete naturally and then navigate to splash
  }

  void _navigateToSplash() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _skipIntro() {
    _videoController.pause();
    _navigateToSplash();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player - Full Screen
          if (_isVideoInitialized)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover, // Ensures video covers entire screen
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            ),

          // Loading indicator while video initializes
          if (!_isVideoInitialized)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

          // Skip Button
          if (_showSkipButton && _isVideoInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showSkipButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _skipIntro,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // No logo overlay during video - completely full screen experience
          // Logo will appear in splash screen after video completes
        ],
      ),
    );
  }
}
