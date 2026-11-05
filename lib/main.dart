import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_provider.dart';
import 'shared/state/matrimonial_provider.dart';
import 'shared/theme/theme.dart';
import 'shared/theme/language_text_scale.dart';
import 'app/config/supabase_config.dart';
import 'app/preferences/user_preferences.dart';
import 'l10n/app_localizations.dart';
import 'app/di/service_locator.dart';
import 'app/router.dart';
import 'app/settings/app_settings.dart';
import 'app/settings/maintenance_gate.dart';
import 'core/services/auth_service.dart';

/// `--dart-define=FULL_ERRORS=true` (debug builds) prints every framework
/// error in full, e.g. each layout overflow with its file and line, instead of
/// only the first one. Used for the layout sweeps in docs/PROGRESS_TRACKER.md.
const _fullErrors = bool.fromEnvironment('FULL_ERRORS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode && _fullErrors) {
    FlutterError.onError = (details) =>
        FlutterError.dumpErrorToConsole(details, forceReport: true);
  }

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

  // Admin-controlled settings: cached copy first, then refreshed from the server.
  final settings = AppSettings(SupabaseAppSettingsSource());
  await settings.start();

  // Theme and language choices apply from the first frame.
  final preferences = await UserPreferences.load();

  runApp(TryMeYourPartnerApp(appSettings: settings, preferences: preferences));
}

class TryMeYourPartnerApp extends StatelessWidget {
  /// Tests pass a fake sign-in service; the app uses the configured backend.
  final AuthService? authService;

  /// Admin-controlled settings; tests pass one built on a fake source.
  final AppSettings? appSettings;

  /// Saved theme and language choices; defaults (system theme, the admin's
  /// default language) when not given.
  final UserPreferences? preferences;
  const TryMeYourPartnerApp({
    super.key,
    this.authService,
    this.appSettings,
    this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(
          value: appSettings ?? AppSettings(const _NoSettings()),
        ),
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
    final settings = context.watch<AppSettings>();
    // The member's own choice wins; otherwise the admin's default language.
    final shownLocale = prefs.effectiveLocale(settings.defaultLocale);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light(shownLocale),
      darkTheme: AppTheme.dark(shownLocale),
      themeMode: prefs.themeMode,
      locale: shownLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) => LanguageTextScale(
        memberFactor: prefs.textSize.factor,
        child: MaintenanceGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Used when no settings were supplied (e.g. in tests): app defaults only.
class _NoSettings implements AppSettingsSource {
  const _NoSettings();
  @override
  Future<Map<String, dynamic>> fetch() async => const {};
}
