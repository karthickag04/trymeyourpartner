import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_provider.dart';
import 'shared/state/matrimonial_provider.dart';
import 'shared/theme/theme.dart';
import 'app/config/supabase_config.dart';
import 'app/preferences/user_preferences.dart';
import 'l10n/app_localizations.dart';
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

  // Theme and language choices apply from the first frame.
  final preferences = await UserPreferences.load();

  runApp(TryMeYourPartnerApp(preferences: preferences));
}

class TryMeYourPartnerApp extends StatelessWidget {
  /// Tests pass a fake sign-in service; the app uses the configured backend.
  final AuthService? authService;

  /// Saved theme and language choices; defaults (system theme, device
  /// language) when not given.
  final UserPreferences? preferences;
  const TryMeYourPartnerApp({super.key, this.authService, this.preferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserPreferences>(
          create: (_) => preferences ?? UserPreferences(),
        ),
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
    final prefs = context.watch<UserPreferences>();
    // The font depends on the language actually shown, which follows the
    // device when the member has not picked one.
    final shownLocale =
        prefs.locale ??
        basicLocaleListResolution(
          WidgetsBinding.instance.platformDispatcher.locales,
          AppLocalizations.supportedLocales,
        );
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light(shownLocale),
      darkTheme: AppTheme.dark(shownLocale),
      themeMode: prefs.themeMode,
      locale: prefs.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
