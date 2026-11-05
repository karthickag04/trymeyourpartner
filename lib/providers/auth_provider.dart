import 'package:flutter/foundation.dart';
// import 'package:url_launcher/url_launcher.dart';
import '../services/user_service.dart';
import '../di/service_locator.dart';
import '../core/services/auth_service.dart';
import '../services/auth/auth_user.dart';

class AuthProvider with ChangeNotifier {
  late final AuthService _auth;

  // OAuth client id managed in Supabase dashboard

  // Minimal user projection to decouple from Supabase types
  String? _userId;
  String? _userEmail;
  String? _fullName;
  String? _avatarUrl;
  bool _isLoading = true;
  String _error = '';

  // Getters
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _userId != null;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Backward-compatible user getter (used widely as auth.user?.id)
  AppAuthUser? get user => _userId == null
      ? null
      : AppAuthUser(
          id: _userId!,
          email: _userEmail,
          fullName: _fullName,
          avatarUrl: _avatarUrl,
          emailVerified: true,
        );

  AuthProvider() {
    _auth = sl.authService;
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes via repository
    _auth.authStateChanges().listen((id) async {
      final wasAuthenticated = _userId != null;
      final previousUserId = _userId;
      _userId = id;

      // Create/update user profile when user signs in
      if (_userId != null) {
        try {
          // Fetch email/full name from a user profile table if available (best-effort)
          final profile = await UserService.getUserProfile(_userId!);
          // The login itself is the source of truth for the email.
          _userEmail =
              await _auth.currentUserEmail() ?? profile?['email'] as String?;
          _fullName = profile?['full_name'] as String?;
          _avatarUrl = profile?['avatar_url'] as String?;
          await UserService.upsertUserProfile(
            userId: _userId!,
            email: _userEmail ?? '',
            fullName: _fullName ?? '',
            avatarUrl: _avatarUrl ?? '',
          );

          // If user just logged in or session restored with different user, trigger data loading
          if (!wasAuthenticated || previousUserId != _userId) {
            debugPrint(
              '🔑 User authenticated (${_userEmail ?? ''}) - triggering data reload',
            );
            _triggerDataReload();
          }
        } catch (e) {
          debugPrint('Failed to sync user profile: $e');
        }
      } else if (wasAuthenticated) {
        // User signed out
        debugPrint('🚪 User signed out - triggering data cleanup');
        _triggerSignOut();
      }

      _isLoading = false;
      notifyListeners();
    });

    // Check current session
    _auth.currentUserId().then((value) async {
      _userId = value;

      // If user is already authenticated (session restored), trigger data loading
      if (_userId != null) {
        debugPrint('🔄 Session restored - triggering data reload');
        try {
          await UserService.upsertUserProfile(
            userId: _userId!,
            email: _userEmail ?? '',
            fullName: _fullName ?? '',
            avatarUrl: _avatarUrl ?? '',
          );
          _triggerDataReload();
        } catch (e) {
          debugPrint('Failed to sync user profile on session restore: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // Trigger matrimonial data reload when authentication changes
  void _triggerDataReload() {
    // Use a callback to notify when matrimonial data should be reloaded
    if (onAuthStateChanged != null && _userId != null) {
      onAuthStateChanged!(_userId!);
    }
  }

  // Trigger data cleanup when user signs out
  void _triggerSignOut() {
    if (onUserSignedOut != null) {
      onUserSignedOut!();
    }
  }

  // Callback for authentication state changes
  Function(String userId)? onAuthStateChanged;

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _setLoading(true);
      _error = '';

      final ok = await _auth.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (ok) {
        // Create user profile in database
        try {
          await UserService.upsertUserProfile(
            userId: await _auth.currentUserId() ?? '',
            email: email,
            fullName: fullName,
          );
        } catch (e) {
          debugPrint('Failed to create user profile: $e');
          // Continue anyway - profile can be created later
        }

        // In generic mode we don't gate on email verification here
        return true;
      }

      _error = 'Failed to create account';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      _error = '';

      final ok = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      return ok;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google using Pure OAuth (No Firebase needed)
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = '';

      // Use Supabase's built-in Google OAuth
      final ok = await _auth.signInWithProvider(
        'google',
        redirectUri: kIsWeb
            ? '${Uri.base.origin}/auth/callback'
            : 'com.trymeyourpartner://oauth-callback',
      );
      return ok;
    } catch (e) {
      _error = 'Google Sign-In failed: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _error = '';

      await _auth.resetPassword(email);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resend email verification
  Future<bool> resendEmailVerification() async {
    try {
      _setLoading(true);
      _error = '';

      if (_userEmail == null || _userEmail!.isEmpty) {
        _error = 'No user email found';
        return false;
      }

      await _auth.resendEmailVerification(_userEmail!);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if email is verified
  bool get isEmailVerified => true; // Not enforced at UI layer in generic mode

  // Get verification status message
  String get verificationMessage {
    if (_userId == null) return '';
    if (isEmailVerified) return '';
    return 'Please verify your email address to access all features.';
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userId = null;
      _userEmail = null;
      _fullName = null;
      _avatarUrl = null;

      // Trigger data cleanup
      if (onUserSignedOut != null) {
        onUserSignedOut!();
      }

      debugPrint('🚪 User signed out - triggering data cleanup');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Callback for when user signs out
  VoidCallback? onUserSignedOut;

  // Update user profile
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    try {
      // Lightweight update: avoid toggling global isLoading to prevent layout jumps
      _error = '';

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final ok = await _auth.updateProfile(
        fullName: updates['full_name'],
        avatarUrl: updates['avatar_url'],
      );
      if (ok) {
        // Refresh local cache so UI updates immediately
        if (fullName != null) _fullName = fullName;
        if (avatarUrl != null) _avatarUrl = avatarUrl;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      // no-op: keep UI responsive without global spinner
    }
  }

  // Get user profile data
  Map<String, dynamic>? get userProfile {
    if (_userId == null) return null;
    return {
      'id': _userId,
      'email': _userEmail,
      'full_name': _fullName ?? '',
      'avatar_url': _avatarUrl ?? '',
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
