import 'dart:convert' show base64Encode;
import '../../core/services/storage_service.dart';
import 'http_client.dart';

class HttpStorageService implements StorageService {
  final ApiClient api;
  HttpStorageService(this.api);

  @override
  Future<String> upload(
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    // Using JSON base64 to keep it simple for now; switch to multipart if server supports it
    final body = {
      'path': path,
      'contentType': contentType,
      'data': base64Encode(bytes),
    };
    final res = await api.post('/storage/upload', body: body) as Map;
    final url = (res['url'] ?? res['publicUrl'] ?? '').toString();
    if (url.isEmpty) {
      throw Exception('Upload failed: no URL returned');
    }
    return url;
  }

  @override
  Future<void> delete(String path) async {
    await api.delete('/storage', body: {'path': path});
  }

  @override
  Future<String> getSignedUrl(
    String path, {
    Duration expires = const Duration(hours: 6),
  }) async {
    // HTTP backend already returns a permanent URL; if this is a path, request a URL
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final res =
        await api.post(
              '/storage/signed-url',
              body: {'path': path, 'expiresIn': expires.inSeconds},
            )
            as Map?;
    final url = (res?['url'] ?? '').toString();
    return url.isNotEmpty ? url : path;
  }
}
