import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';

class SupabaseAuthService implements AuthService {
  // Lazily access the Supabase client to avoid touching Supabase.instance
  // during object construction.
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<String?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((e) => e.session?.user.id);
  }

  @override
  Future<String?> currentUserId() async => _client.auth.currentUser?.id;

  @override
  Future<String?> currentAccessToken() async =>
      _client.auth.currentSession?.accessToken;

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {if (fullName != null) 'full_name': fullName},
    );
    return res.user != null;
  }

  @override
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user != null;
  }

  @override
  Future<bool> signInWithProvider(
    String providerId, {
    String? redirectUri,
  }) async {
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
    await _client.auth.signInWithOAuth(
      p,
      redirectTo: kIsWeb
          ? (redirectUri ?? '${Uri.base.origin}/auth/callback')
          : redirectUri,
    );
    return true;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<bool> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
    return true;
  }

  @override
  Future<bool> resendEmailVerification(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
    return true;
  }

  @override
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    await _client.auth.updateUser(UserAttributes(data: updates));
    return true;
  }
}
