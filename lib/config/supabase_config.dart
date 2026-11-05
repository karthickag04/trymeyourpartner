class SupabaseConfig {
  static const String supabaseUrl = 'https://lngpmjxiqfskpxbncfgl.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxuZ3BtanhpcWZza3B4Ym5jZmdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYwMzAxMzYsImV4cCI6MjA3MTYwNjEzNn0.kr-_z4Nubwd6k8zbfjH6czuaXUVt-060s2tKFQIO2KY',
  );
  
  // Database table names
  static const String usersTable = 'users';
  static const String matrimonialProfilesTable = 'matrimonial_profiles';
  static const String profileInteractionsTable = 'profile_interactions';
  static const String matchesTable = 'matches';
  static const String interestsTable = 'interests';
  
  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String profileImagesBucket = 'profile-images';
  
  // Auth settings
  static const int sessionTimeoutMinutes = 60;
  static const bool enableAutoRefresh = true;
}
