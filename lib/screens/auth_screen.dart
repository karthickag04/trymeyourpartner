import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.paddingXL),

              // App Logo and Welcome
              _buildHeader(),

              const SizedBox(height: AppDimensions.paddingXL),

              // Auth Form
              _buildAuthForm(),

              const SizedBox(height: AppDimensions.paddingL),

              // Social Login
              _buildSocialLogin(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Logo (you can replace with actual logo)
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          child: const Icon(
            Icons.play_circle_filled,
            size: 60,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: AppDimensions.paddingL),

        Text(
          AppConstants.appName,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: AppDimensions.paddingS),

        Text(
          'Your Educational Streaming Platform',
          style: AppTextStyles.subtitle1.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Tab Bar
            TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Sign In'),
                Tab(text: 'Sign Up'),
              ],
            ),

            const SizedBox(height: AppDimensions.paddingL),

            // Tab Views
            SizedBox(
              height: 350, // Increased height to prevent overflow
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: _buildSignInForm()),
                  SingleChildScrollView(child: _buildSignUpForm()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Error Message
            if (authProvider.error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  authProvider.error,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),

            const SizedBox(height: AppDimensions.paddingL),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign In'),
              ),
            ),

            // Forgot Password
            TextButton(
              onPressed: _forgotPassword,
              child: Text(
                'Forgot Password?',
                style: AppTextStyles.caption.copyWith(color: AppColors.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignUpForm() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Error Message
            if (authProvider.error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  authProvider.error,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),

            const SizedBox(height: AppDimensions.paddingL),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialLogin() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            Text(
              'Or continue with',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Google Sign In Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: authProvider.isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                  side: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Navigation will be handled by AuthWrapper
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome back!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Welcome to TryMeYourPartner!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (authProvider.error.contains('verification')) {
        // Show verification dialog
        _showVerificationDialog();
      }
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Check Your Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_unread, size: 64, color: AppColors.accent),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'We\'ve sent a verification link to ${_emailController.text}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'Please click the link in your email to verify your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signInWithGoogle();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in with Google!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (authProvider.error.contains('not configured')) {
        // Show dialog for Google OAuth not configured
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Google Sign-In Unavailable'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 48, color: AppColors.warning),
                SizedBox(height: 16),
                Text(
                  'Google Sign-In is not configured for this app yet. Please use email sign-in instead.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your email first'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
