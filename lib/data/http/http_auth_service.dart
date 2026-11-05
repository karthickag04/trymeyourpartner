import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';

class HttpAuthService implements AuthService {
  final String baseUrl;
  final http.Client _client;

  // Cached session
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  String? _email;
  String? _fullName;
  String? _avatarUrl;

  // Broadcast auth stream
  final StreamController<String?> _authCtrl =
      StreamController<String?>.broadcast();

  // Serialize refresh calls
  Future<bool>? _refreshing;

  HttpAuthService(this._client, {required this.baseUrl});

  // Preference keys
  static const _kAccess = 'auth.accessToken';
  static const _kRefresh = 'auth.refreshToken';
  static const _kUserId = 'auth.userId';
  static const _kEmail = 'auth.email';
  static const _kFullName = 'auth.fullName';
  static const _kAvatar = 'auth.avatarUrl';

  Future<void> _ensureLoaded() async {
    if (_userId != null || _accessToken != null || _refreshToken != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_kAccess);
    _refreshToken = prefs.getString(_kRefresh);
    _userId = prefs.getString(_kUserId);
    _email = prefs.getString(_kEmail);
    _fullName = prefs.getString(_kFullName);
    _avatarUrl = prefs.getString(_kAvatar);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_kAccess, _accessToken!);
    } else {
      await prefs.remove(_kAccess);
    }
    if (_refreshToken != null) {
      await prefs.setString(_kRefresh, _refreshToken!);
    } else {
      await prefs.remove(_kRefresh);
    }
    if (_userId != null) {
      await prefs.setString(_kUserId, _userId!);
    } else {
      await prefs.remove(_kUserId);
    }
    if (_email != null && _email!.isNotEmpty) {
      await prefs.setString(_kEmail, _email!);
    } else {
      await prefs.remove(_kEmail);
    }
    if (_fullName != null && _fullName!.isNotEmpty) {
      await prefs.setString(_kFullName, _fullName!);
    } else {
      await prefs.remove(_kFullName);
    }
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      await prefs.setString(_kAvatar, _avatarUrl!);
    } else {
      await prefs.remove(_kAvatar);
    }
  }

  void _setSession(Map json) {
    // Support both camelCase and snake_case keys
    _accessToken = (json['accessToken'] ?? json['access_token'])?.toString();
    _refreshToken =
        (json['refreshToken'] ?? json['refresh_token'])?.toString() ??
        _refreshToken;
    final user = json['user'];
    if (user is Map) {
      _userId = (user['id'] ?? user['user_id'])?.toString() ?? _userId;
      _email = user['email']?.toString() ?? _email;
      _fullName =
          (user['fullName'] ?? user['full_name'])?.toString() ?? _fullName;
      _avatarUrl =
          (user['avatarUrl'] ?? user['avatar_url'])?.toString() ?? _avatarUrl;
    }
  }

  Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$normalized');
  }

  Map<String, String> _jsonHeaders() => const {
    'content-type': 'application/json',
    'accept': 'application/json',
  };

  @override
  Stream<String?> authStateChanges() async* {
    // Emit cached/loaded state first if available
    await _ensureLoaded();
    yield _userId;
    // Then forward subsequent changes
    yield* _authCtrl.stream;
  }

  @override
  Future<String?> currentUserEmail() async {
    await _ensureLoaded();
    return _email;
  }

  @override
  Future<String?> currentUserId() async {
    await _ensureLoaded();
    return _userId;
  }

  @override
  Future<String?> currentAccessToken() async {
    await _ensureLoaded();
    return _accessToken;
  }

  @override
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await _client.post(
      _uri('/auth/signup'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        if (fullName != null) 'fullName': fullName,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Signup failed (${res.statusCode})');
    }
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (data is! Map) return false;
    _setSession(data);
    await _persist();
    _authCtrl.add(_userId);
    return _userId != null && _accessToken != null;
  }

  @override
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _uri('/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Login failed (${res.statusCode})');
    }
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (data is! Map) return false;
    _setSession(data);
    await _persist();
    _authCtrl.add(_userId);
    return _userId != null && _accessToken != null;
  }

  @override
  Future<bool> signInWithProvider(
    String providerId, {
    String? redirectUri,
  }) async {
    // Not implemented for generic HTTP backend in this app.
    throw UnsupportedError('OAuth provider "$providerId" not configured');
  }

  @override
  Future<void> signOut() async {
    await _ensureLoaded();
    try {
      // Best-effort logout; ignore server errors
      await _client.post(
        _uri('/auth/logout'),
        headers: _jsonHeaders(),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
    } catch (_) {}
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    _fullName = null;
    _avatarUrl = null;
    await _persist();
    _authCtrl.add(null);
  }

  @override
  Future<bool> resetPassword(String email) async {
    final res = await _client.post(
      _uri('/auth/reset'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  @override
  Future<bool> resendEmailVerification(String email) async {
    final res = await _client.post(
      _uri('/auth/resend-verification'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  @override
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    await _ensureLoaded();
    if (_accessToken == null) return false;
    Future<http.Response> doPut() => _client.put(
      _uri('/profiles/me'),
      headers: {..._jsonHeaders(), 'authorization': 'Bearer ${_accessToken!}'},
      body: jsonEncode({
        if (fullName != null) 'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      }),
    );
    var res = await doPut();
    if (res.statusCode == 401) {
      final refreshed = await tryRefresh();
      if (refreshed) {
        res = await doPut();
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Update cached fields
      if (fullName != null) _fullName = fullName;
      if (avatarUrl != null) _avatarUrl = avatarUrl;
      await _persist();
      return true;
    }
    return false;
  }

  // Exposed for DI to use inside unauthorized retry closure
  Future<bool> tryRefresh() async {
    await _ensureLoaded();
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    // De-dupe concurrent refresh calls
    if (_refreshing != null) return await _refreshing!;
    final completer = Completer<bool>();
    _refreshing = completer.future;
    try {
      final res = await _client.post(
        _uri('/auth/refresh'),
        headers: _jsonHeaders(),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        completer.complete(false);
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        if (data is Map && (data['accessToken'] != null)) {
          _setSession(data);
          await _persist();
          // User id unchanged; no need to emit unless previously null
          if (_userId != null) {
            _authCtrl.add(_userId);
          }
          completer.complete(true);
        } else {
          completer.complete(false);
        }
      }
    } catch (_) {
      completer.complete(false);
    } finally {
      // Reset so a new refresh can be initiated later
      _refreshing = null;
    }
    return await completer.future;
  }
}
