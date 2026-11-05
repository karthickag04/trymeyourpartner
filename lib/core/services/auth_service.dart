abstract class AuthService {
  Stream<String?> authStateChanges();
  Future<String?> currentUserId();
  Future<String?> currentUserEmail();
  Future<String?> currentAccessToken();

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  });
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  });
  Future<bool> signInWithProvider(String providerId, {String? redirectUri});
  Future<void> signOut();

  Future<bool> resetPassword(String email);
  Future<bool> resendEmailVerification(String email);
  Future<bool> updateProfile({String? fullName, String? avatarUrl});
}
