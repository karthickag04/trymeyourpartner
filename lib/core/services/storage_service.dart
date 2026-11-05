abstract class StorageService {
  /// Upload a file to a backend-specific bucket/location.
  /// Returns:
  /// - Supabase: storage object path within the bucket (not a permanent URL)
  /// - HTTP backend: a permanent URL
  Future<String> upload(String path, List<int> bytes, {String? contentType});

  /// Delete by storage path (Supabase) or server-side path identifier (HTTP).
  Future<void> delete(String path);

  /// Resolve a displayable URL from a storage path, using signed URLs where needed.
  /// Implementations may ignore [expires] if not applicable and just return the input
  /// (e.g., when [path] is already an absolute URL).
  Future<String> getSignedUrl(
    String path, {
    Duration expires = const Duration(hours: 6),
  });
}
