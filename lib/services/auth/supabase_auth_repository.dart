import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';
import 'auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;
  SupabaseAuthRepository(this._supabase);

  AppAuthUser? _map(User? user) {
    if (user == null) return null;
  final String? createdAtStr = user.createdAt;
    return AppAuthUser(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
      avatarUrl: user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      emailVerified: user.emailConfirmedAt != null,
    );
  }

  @override
  Stream<AppAuthUser?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((event) => _map(event.session?.user));
  }

  @override
  Future<AppAuthUser?> getCurrentUser() async => _map(_supabase.auth.currentUser);

  @override
  Future<AppAuthUser?> signUp({required String email, required String password, String? fullName}) async {
    final res = await _supabase.auth.signUp(email: email, password: password, data: {
      if (fullName != null) 'full_name': fullName,
    });
  return _map(res.user);
  }

  @override
  Future<AppAuthUser?> signInWithPassword({required String email, required String password}) async {
    final res = await _supabase.auth.signInWithPassword(email: email, password: password);
    return _map(res.user);
  }

  @override
  Future<bool> signInWithProvider(String providerId, {String? redirectUri}) async {
    final provider = providerId.toLowerCase();
    OAuthProvider? p;
    switch (provider) {
      case 'google':
        p = OAuthProvider.google;
        break;
      case 'github':
        p = OAuthProvider.github;
        break;
      case 'azure':
        p = OAuthProvider.azure;
        break;
      default:
        throw UnsupportedError('Provider not supported: $providerId');
    }
    await _supabase.auth.signInWithOAuth(
      p,
      redirectTo: kIsWeb
          ? (redirectUri ?? '${Uri.base.origin}/auth/callback')
          : redirectUri,
    );
    // Supabase returns void here; successful call implies we handed off to the provider
    return true;
  }

  @override
  Future<void> signOut() => _supabase.auth.signOut();

  @override
  Future<bool> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
    return true;
  }

  @override
  Future<bool> resendEmailVerification(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
    return true;
  }

  @override
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    await _supabase.auth.updateUser(UserAttributes(data: updates));
    return true;
  }
}
