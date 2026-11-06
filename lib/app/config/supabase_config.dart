class SupabaseConfig {
  static const String supabaseUrl = 'https://lngpmjxiqfskpxbncfgl.supabase.co';

  /// Supabase publishable key (sb_publishable_...), passed at build time:
  ///   flutter run --dart-define-from-file=.env
  /// See .env.example. There is deliberately no default.
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY');

  // Database table names
  static const String usersTable = 'users';
  static const String matrimonialProfilesTable = 'matrimonial_profiles';
  static const String profileInteractionsTable = 'profile_interactions';
  static const String matchesTable = 'matches';
  static const String interestsTable = 'interests';

  // Auth settings
  static const int sessionTimeoutMinutes = 60;
  static const bool enableAutoRefresh = true;
}
