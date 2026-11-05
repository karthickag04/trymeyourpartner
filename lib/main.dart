import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_provider.dart';
import 'shared/state/matrimonial_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/onboarding/profile_completion_gate.dart';
import 'shared/theme/theme.dart';
import 'shared/theme/constants.dart';
import 'app/config/supabase_config.dart';
import 'app/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine backend mode from dart-define and initialize Supabase first if needed
  const backendStr = String.fromEnvironment(
    'BACKEND_MODE',
    defaultValue: 'supabase',
  );
  final mode = backendStr.toLowerCase() == 'http'
      ? BackendMode.http
      : BackendMode.supabase;

  if (mode == BackendMode.supabase) {
    if (SupabaseConfig.supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_KEY is not set. Copy .env.example to .env, add the '
        'publishable key, and run with --dart-define-from-file=.env',
      );
    }
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Now configure dependency injection with the selected mode
  sl.configure(mode: mode);

  runApp(const TryMeYourPartnerApp());
}

class TryMeYourPartnerApp extends StatelessWidget {
  const TryMeYourPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Auto-refresh matrimonial data whenever auth user changes
        ChangeNotifierProxyProvider<AuthProvider, MatrimonialProvider>(
          create: (_) => MatrimonialProvider(),
          update: (context, auth, matrimony) {
            final provider = matrimony ?? MatrimonialProvider();
            final user = auth.user;
            if (user == null) {
              provider.clearAllData();
            }
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme, // Changed to light theme for matrimonial
        darkTheme: AppTheme.lightTheme,
        themeMode: ThemeMode.light, // Changed to light mode
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(), // Start with splash screen
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        // Show main app if authenticated, otherwise show auth screen
        // Route authenticated users through the profile completion gate
        return authProvider.isAuthenticated
            ? const ProfileCompletionGate()
            : const AuthScreen();
      },
    );
  }
}
