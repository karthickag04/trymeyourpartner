import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trymeyourpartner/core/services/auth_service.dart';
import 'package:trymeyourpartner/main.dart';

/// A signed-out session with no backend behind it.
class _SignedOutAuth implements AuthService {
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

void main() {
  testWidgets('starts on the splash screen', (tester) async {
    await tester.pumpWidget(TryMeYourPartnerApp(authService: _SignedOutAuth()));
    expect(find.text('Loading your experience...'), findsOneWidget);
    // Let the splash animation finish so no timers are left pending.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a signed-out visitor ends up on the sign-in screen', (
    tester,
  ) async {
    await tester.pumpWidget(TryMeYourPartnerApp(authService: _SignedOutAuth()));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Sign In'), findsWidgets);
  });
}
