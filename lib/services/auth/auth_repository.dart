import 'auth_user.dart';

abstract class AuthRepository {
  Stream<AppAuthUser?> authStateChanges();
  Future<AppAuthUser?> getCurrentUser();

  Future<AppAuthUser?> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  Future<AppAuthUser?> signInWithPassword({
    required String email,
    required String password,
  });

  Future<bool> signInWithProvider(String providerId, {String? redirectUri});

  Future<void> signOut();

  Future<bool> resetPassword(String email);
  Future<bool> resendEmailVerification(String email);
  Future<bool> updateProfile({String? fullName, String? avatarUrl});
}
