/// Build-time settings, passed with `--dart-define-from-file=.env`
/// (see `.env.example`). There is deliberately no default key.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseKey,
    required this.apiBaseUrl,
  });

  const AppConfig.fromEnvironment()
    : supabaseUrl = const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://lngpmjxiqfskpxbncfgl.supabase.co',
      ),
      supabaseKey = const String.fromEnvironment('SUPABASE_KEY'),
      apiBaseUrl = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      );

  /// Supabase project URL.
  final String supabaseUrl;

  /// Publishable key (sb_publishable_...). Never the secret key.
  final String supabaseKey;

  /// Backend API base URL (serves /admin/v1).
  final String apiBaseUrl;

  bool get isComplete => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
