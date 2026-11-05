import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_provider.dart';
import 'shared/state/matrimonial_provider.dart';
import 'shared/theme/theme.dart';
import 'shared/theme/constants.dart';
import 'app/config/supabase_config.dart';
import 'app/di/service_locator.dart';
import 'app/router.dart';
import 'core/services/auth_service.dart';

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

  // Profiles opened with context.push also show their URL (/p/<code>).
  GoRouter.optionURLReflectsImperativeAPIs = true;

  runApp(const TryMeYourPartnerApp());
}

class TryMeYourPartnerApp extends StatelessWidget {
  /// Tests pass a fake sign-in service; the app uses the configured backend.
  final AuthService? authService;
  const TryMeYourPartnerApp({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(auth: authService)),
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
      child: const _RoutedApp(),
    );
  }
}

/// Builds the router once, after the providers exist.
class _RoutedApp extends StatefulWidget {
  const _RoutedApp();

  @override
  State<_RoutedApp> createState() => _RoutedAppState();
}

class _RoutedAppState extends State<_RoutedApp> {
  late final GoRouter _router = buildRouter(context.read<AuthProvider>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
