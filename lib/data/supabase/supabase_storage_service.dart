import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/storage_service.dart';

class SupabaseStorageService implements StorageService {
  // Lazily access the client to avoid early Supabase.instance usage
  SupabaseClient get _client => Supabase.instance.client;
  // Use a private bucket for profile photos (create this in Supabase Dashboard)
  final String bucket = 'profiles';

  @override
  Future<String> upload(
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    final uid = _client.auth.currentUser?.id;
    // ignore: avoid_print
    print(
      '[Photo][SupabaseStorage] uid=$uid bucket=$bucket path=$path contentType=$contentType',
    );
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType),
        );
    // Return storage object path (not a public URL)
    return path;
  }

  @override
  Future<void> delete(String path) async {
    await _client.storage.from(bucket).remove([path]);
  }

  @override
  Future<String> getSignedUrl(
    String path, {
    Duration expires = const Duration(hours: 6),
  }) async {
    // If a full URL is accidentally passed, return it unchanged
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final secs = expires.inSeconds;
    final res = await _client.storage.from(bucket).createSignedUrl(path, secs);
    return res;
  }
}
