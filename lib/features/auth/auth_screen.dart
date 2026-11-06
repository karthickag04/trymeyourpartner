import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import '../../l10n/l10n.dart';
import '../../shared/theme/constants.dart';
import '../../shared/widgets/language_selector.dart';

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
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LanguageSelector(),
              ),

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
            color: context.palette.accent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          child: Icon(
            Icons.favorite,
            size: 60,
            color: context.palette.onPrimary,
          ),
        ),

        const SizedBox(height: AppDimensions.paddingL),

        Text(
          context.l10n.appName,
          style: context.styles.heading1.copyWith(
            color: context.palette.accent,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: AppDimensions.paddingS),

        Text(
          context.l10n.authTagline,
          style: context.styles.subtitle1.copyWith(
            color: context.palette.textSecondary,
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
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: context.palette.shadow,
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
                color: context.palette.accent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: context.palette.onPrimary,
              unselectedLabelColor: context.palette.textSecondary,
              tabs: [
                Tab(text: context.l10n.authSignIn),
                Tab(text: context.l10n.authSignUp),
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
              style: context.styles.body1,
              decoration: InputDecoration(
                labelText: context.l10n.authEmailLabel,
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.authEmailRequired;
                }
                if (!value.contains('@')) {
                  return context.l10n.authEmailInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: context.styles.body1,
              decoration: InputDecoration(
                labelText: context.l10n.authPasswordLabel,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? context.l10n.authShowPassword
                      : context.l10n.authHidePassword,
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
                  return context.l10n.authPasswordRequired;
                }
                if (value.length < 6) {
                  return context.l10n.authPasswordTooShort(6);
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
                  color: context.palette.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  _errorMessage(context, authProvider.error),
                  style: context.styles.caption.copyWith(
                    color: context.palette.error,
                  ),
                ),
              ),

            const SizedBox(height: AppDimensions.paddingL),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.accent,
                  foregroundColor: context.palette.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                child: authProvider.isLoading
                    ? CircularProgressIndicator(
                        color: context.palette.onPrimary,
                      )
                    : Text(context.l10n.authSignIn),
              ),
            ),

            // Forgot Password
            TextButton(
              onPressed: _forgotPassword,
              child: Text(
                context.l10n.authForgotPassword,
                style: context.styles.caption.copyWith(
                  color: context.palette.accent,
                ),
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
              style: context.styles.body1,
              decoration: InputDecoration(
                labelText: context.l10n.authFullNameLabel,
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.authFullNameRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: context.styles.body1,
              decoration: InputDecoration(
                labelText: context.l10n.authEmailLabel,
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.authEmailRequired;
                }
                if (!value.contains('@')) {
                  return context.l10n.authEmailInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: context.styles.body1,
              decoration: InputDecoration(
                labelText: context.l10n.authPasswordLabel,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? context.l10n.authShowPassword
                      : context.l10n.authHidePassword,
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
                  return context.l10n.authPasswordRequired;
                }
                if (value.length < 6) {
                  return context.l10n.authPasswordTooShort(6);
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
                  color: context.palette.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  _errorMessage(context, authProvider.error),
                  style: context.styles.caption.copyWith(
                    color: context.palette.error,
                  ),
                ),
              ),

            const SizedBox(height: AppDimensions.paddingL),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.accent,
                  foregroundColor: context.palette.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                ),
                child: authProvider.isLoading
                    ? CircularProgressIndicator(
                        color: context.palette.onPrimary,
                      )
                    : Text(context.l10n.authSignUp),
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
              context.l10n.authOrContinueWith,
              style: context.styles.caption.copyWith(
                color: context.palette.textSecondary,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Google Sign In Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: authProvider.isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: Text(context.l10n.authContinueWithGoogle),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingM,
                  ),
                  side: BorderSide(color: context.palette.divider),
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
        SnackBar(
          content: Text(context.l10n.authWelcomeBack),
          backgroundColor: context.palette.success,
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
          SnackBar(
            content: Text(context.l10n.authAccountCreated),
            backgroundColor: context.palette.success,
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
        title: Text(context.l10n.authCheckEmailTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_unread,
              size: 64,
              color: context.palette.accent,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              context.l10n.authVerificationSent(_emailController.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              context.l10n.authVerificationInstruction,
              textAlign: TextAlign.center,
              style: context.styles.body2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonOk),
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
          SnackBar(
            content: Text(context.l10n.authSignedInWithGoogle),
            backgroundColor: context.palette.success,
          ),
        );
      } else if (authProvider.error.contains('not configured')) {
        // Show dialog for Google OAuth not configured
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.authGoogleUnavailableTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 48,
                  color: context.palette.warning,
                ),
                SizedBox(height: 16),
                Text(
                  context.l10n.authGoogleUnavailableBody,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.commonOk),
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
          SnackBar(
            content: Text(context.l10n.authEnterEmailFirst),
            backgroundColor: context.palette.warning,
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
        SnackBar(
          content: Text(context.l10n.authPasswordResetSent),
          backgroundColor: context.palette.success,
        ),
      );
    }
  }

  /// Turns the sign-in service's message into a translated, friendly one.
  /// Unknown errors get a generic message instead of raw exception text.
  String _errorMessage(BuildContext context, String raw) {
    final l = context.l10n;
    final e = raw.toLowerCase();
    if (e.contains('invalid login credentials')) {
      return l.authErrorInvalidCredentials;
    }
    if (e.contains('already registered') || e.contains('already exists')) {
      return l.authErrorAlreadyRegistered;
    }
    if (e.contains('not confirmed')) return l.authErrorEmailNotConfirmed;
    if (e.contains('google')) return l.authErrorGoogleFailed;
    if (e.contains('failed to create account')) return l.authErrorSignUpFailed;
    if (e.contains('socket') ||
        e.contains('network') ||
        e.contains('failed host lookup') ||
        e.contains('clientexception')) {
      return l.authErrorNetwork;
    }
    return l.commonSomethingWentWrong;
  }
}
