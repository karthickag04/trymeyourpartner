import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();
typedef RefreshCallback = Future<bool> Function();

class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final Duration timeout;
  final TokenProvider? _getToken;
  final RefreshCallback? _onUnauthorized;

  ApiClient(
    this._client, {
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    TokenProvider? getToken,
    RefreshCallback? onUnauthorized,
  }) : _getToken = getToken,
       _onUnauthorized = onUnauthorized;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(
      '$baseUrl/$normalized',
    ).replace(queryParameters: query?.map((k, v) => MapEntry(k, v.toString())));
  }

  Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    final token = _getToken == null ? null : await _getToken();
    if (token != null && token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _client
          .get(_uri(path, query), headers: await _headers())
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      final retried = await _maybeRefreshAndRetry(() async {
        final res = await _client
            .get(_uri(path, query), headers: await _headers())
            .timeout(timeout);
        return _handle(res);
      }, e);
      return retried;
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    try {
      final res = await _client
          .post(_uri(path), headers: await _headers(), body: _encode(body))
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      final retried = await _maybeRefreshAndRetry(() async {
        final res = await _client
            .post(_uri(path), headers: await _headers(), body: _encode(body))
            .timeout(timeout);
        return _handle(res);
      }, e);
      return retried;
    }
  }

  Future<dynamic> put(String path, {Object? body}) async {
    try {
      final res = await _client
          .put(_uri(path), headers: await _headers(), body: _encode(body))
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      final retried = await _maybeRefreshAndRetry(() async {
        final res = await _client
            .put(_uri(path), headers: await _headers(), body: _encode(body))
            .timeout(timeout);
        return _handle(res);
      }, e);
      return retried;
    }
  }

  Future<dynamic> delete(String path, {Object? body}) async {
    try {
      final res = await _client
          .delete(_uri(path), headers: await _headers(), body: _encode(body))
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      final retried = await _maybeRefreshAndRetry(() async {
        final res = await _client
            .delete(_uri(path), headers: await _headers(), body: _encode(body))
            .timeout(timeout);
        return _handle(res);
      }, e);
      return retried;
    }
  }

  Object? _encode(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode == 204) return null; // No content
    dynamic data;
    try {
      data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      data = res.body; // fall back to raw body for non-JSON
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    if (res.statusCode == 401) {
      throw _ApiException('Unauthorized', status: res.statusCode, data: data);
    }
    final msg = (data is Map && data['message'] is String)
        ? data['message'] as String
        : 'HTTP ${res.statusCode}';
    throw _ApiException(msg, status: res.statusCode, data: data);
  }

  Future<dynamic> _maybeRefreshAndRetry(
    Future<dynamic> Function() retry,
    Object error,
  ) async {
    final is401 = error is _ApiException && error.status == 401;
    if (!is401 || _onUnauthorized == null) {
      // propagate original error
      throw error;
    }
    final ok = await _onUnauthorized();
    if (!ok) {
      throw error;
    }
    // Retry once after successful refresh
    return await retry();
  }
}

class _ApiException implements Exception {
  final String message;
  final int? status;
  final dynamic data;
  _ApiException(this.message, {this.status, this.data});
  @override
  String toString() => status != null ? 'ApiError[$status]: $message' : message;
}
