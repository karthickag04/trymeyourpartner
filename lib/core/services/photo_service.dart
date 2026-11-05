import 'package:flutter/widgets.dart';

/// Backend-agnostic photo workflow used by UI: pick -> edit -> compress -> upload.
/// Implementations must use the DI-provided StorageService internally for uploads.
abstract class PhotoService {
  /// Pick image (camera/gallery), allow user editing (crop/rotate),
  /// optional programmatic flip, then compress to ~20–30 KB JPEG and upload.
  /// Returns the public URL on success, or null if user cancels.
  Future<String?> pickEditCompressAndUpload({
    required BuildContext context,
    required String profileId,
    required int slotIndex, // 0..2
    required bool fromCamera,
  });

  /// Optionally delete a photo by URL, if the underlying storage supports resolving
  /// URLs to paths. Implementations may no-op if not resolvable.
  Future<void> maybeDeleteByUrl(String url);
}
