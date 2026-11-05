import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class UserService {
  // Lazily access the Supabase client to avoid touching Supabase.instance too early
  static SupabaseClient get _supabase => Supabase.instance.client;

  // Get user profile with extended data
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      final msg = e.toString();
      // If the optional public.users table doesn't exist, just skip without failing the app
      if (msg.contains('PGRST205') ||
          msg.contains("Could not find the table 'public.users'")) {
        return null;
      }
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Create or update user profile
  static Future<bool> upsertUserProfile({
    required String userId,
    required String email,
    String? fullName,
    String? avatarUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.usersTable).upsert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'preferences': preferences ?? {},
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      final msg = e.toString();
      // If the optional public.users table doesn't exist, ignore silently
      if (msg.contains('PGRST205') ||
          msg.contains("Could not find the table 'public.users'")) {
        return true;
      }
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get user's matrimonial profile
  static Future<Map<String, dynamic>?> getMatrimonialProfile(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.matrimonialProfilesTable)
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get matrimonial profile: $e');
    }
  }

  // Update matrimonial profile
  static Future<bool> updateMatrimonialProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.matrimonialProfilesTable).upsert({
        'auth_user_id': userId,
        ...profileData,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to update matrimonial profile: $e');
    }
  }

  // Get user's interests/likes
  static Future<List<String>> getUserInterests(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profileInteractionsTable)
          .select('to_profile_id')
          .eq('from_profile_id', userId)
          .eq('interaction_type', 'interest');

      return List<String>.from(
        response.map((item) => item['to_profile_id']).toList(),
      );
    } catch (e) {
      throw Exception('Failed to get user interests: $e');
    }
  }

  // Add interest/like
  static Future<bool> addInterest(String userId, String targetProfileId) async {
    try {
      await _supabase.from(SupabaseConfig.profileInteractionsTable).insert({
        'from_profile_id': userId,
        'to_profile_id': targetProfileId,
        'interaction_type': 'interest',
      });

      return true;
    } catch (e) {
      if (e.toString().contains('duplicate')) {
        // Already liked, return true
        return true;
      }
      throw Exception('Failed to add interest: $e');
    }
  }

  // Remove interest/unlike
  static Future<bool> removeInterest(
    String userId,
    String targetProfileId,
  ) async {
    try {
      await _supabase
          .from(SupabaseConfig.profileInteractionsTable)
          .delete()
          .eq('from_profile_id', userId)
          .eq('to_profile_id', targetProfileId)
          .eq('interaction_type', 'interest');

      return true;
    } catch (e) {
      throw Exception('Failed to remove interest: $e');
    }
  }

  // Check if user has shown interest
  static Future<bool> hasInterest(String userId, String targetProfileId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profileInteractionsTable)
          .select('id')
          .eq('from_profile_id', userId)
          .eq('to_profile_id', targetProfileId)
          .eq('interaction_type', 'interest')
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get user's matches
  static Future<List<Map<String, dynamic>>> getUserMatches(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.matchesTable)
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('status', 'matched')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get user matches: $e');
    }
  }
}
