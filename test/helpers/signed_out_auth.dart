import 'dart:async';

import 'package:trymeyourpartner/core/services/auth_service.dart';

/// A signed-out session with no backend behind it.
class SignedOutAuth implements AuthService {
  final _changes = StreamController<String?>.broadcast();

  @override
  Stream<String?> authStateChanges() => _changes.stream;
  @override
  Future<String?> currentUserId() async => null;
  @override
  Future<String?> currentUserEmail() async => null;
  @override
  Future<Map<String, dynamic>> currentUserMetadata() async => const {};
  @override
  Future<String?> currentAccessToken() async => null;
  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async => false;
  @override
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async => false;
  @override
  Future<bool> signInWithProvider(
    String providerId, {
    String? redirectUri,
  }) async => false;
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> resetPassword(String email) async => false;
  @override
  Future<bool> resendEmailVerification(String email) async => false;
  @override
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async =>
      false;
}
