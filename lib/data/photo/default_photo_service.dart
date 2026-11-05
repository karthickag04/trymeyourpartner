import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image/image.dart' as img;
import '../../core/services/photo_service.dart';
import '../../core/services/storage_service.dart';
import '../../di/service_locator.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class DefaultPhotoService implements PhotoService {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storage = sl.storageService;

  void _log(String message) {
    // Log to both Flutter debug stream and stdout so it appears in terminal and devtools.
    debugPrint(message);
    // In some run configurations, debugPrint may not surface in the terminal; mirror via print.
    // ignore: avoid_print
    print(message);
  }

  @override
  Future<String?> pickEditCompressAndUpload({
    required BuildContext context,
    required String profileId,
    required int slotIndex,
    required bool fromCamera,
  }) async {
    try {
      _log(
        '[Photo] ENTER pickEditCompressAndUpload: fromCamera=$fromCamera slot=$slotIndex profile=$profileId',
      );

      final granted = await _ensurePermissions(fromCamera: fromCamera);
      if (!granted) {
        _log('[Photo] permissions not granted, ABORT');
        return null;
      }

      _log(
        '[Photo] invoking picker: source=${fromCamera ? 'camera' : 'gallery'}',
      );
      final XFile? file = await (fromCamera
          ? _picker.pickImage(source: ImageSource.camera, imageQuality: 100)
          : _picker.pickImage(source: ImageSource.gallery, imageQuality: 100));
      if (file == null) {
        _log('[Photo] picker returned null (cancelled)');
        _log('[Photo] EXIT pickEditCompressAndUpload (cancelled)');
        return null; // user cancelled
      }
      _log('[Photo] picker OK: path=${file.path}');

      // Open lightweight editor for crop/rotate/flip
      final bytes = await file.readAsBytes();
      _log('[Photo] opening editor...');
      final edited = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ImageEditor(image: bytes),
        ),
      );
      final Uint8List toProcess = edited ?? bytes;
      _log(
        '[Photo] editor complete: edited=${edited != null} bytes=${toProcess.length}',
      );

      // Decode, resize keeping aspect ratio, and encode JPEG with quality loop
      final decoded = img.decodeImage(toProcess);
      if (decoded == null) throw Exception('Failed to decode image');
      final int maxSide = 720;
      final int w = decoded.width;
      final int h = decoded.height;
      final double scale = (w > h ? maxSide / w : maxSide / h).clamp(0.0, 1.0);
      final int newW = (w * scale).round();
      final int newH = (h * scale).round();
      final resized = img.copyResize(decoded, width: newW, height: newH);

      int q = 60; // start quality
      const int targetMax = 30 * 1024; // ~30KB
      Uint8List finalBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: q),
      );
      while (finalBytes.lengthInBytes > targetMax && q > 25) {
        q -= 5;
        finalBytes = Uint8List.fromList(img.encodeJpg(resized, quality: q));
      }
      _log(
        '[Photo] compress stats: origWxH=${w}x${h} newWxH=${newW}x${newH} size=${finalBytes.lengthInBytes}B quality=$q',
      );

      // Use random file name to avoid guessable URLs even if later exposed
      final rnd = _randString(8);
      final tryPaths = <String>[];
      // First try using profileId root (expected for Photos tab)
      tryPaths.add('$profileId/$rnd-$slotIndex.jpg');
      // Prepare auth uid fallback (for cases where profile mapping isn't set yet)
      final authUid = await sl.authService.currentUserId();
      if (authUid != null && authUid.isNotEmpty && authUid != profileId) {
        tryPaths.add('$authUid/$rnd-$slotIndex.jpg');
      }

      String? uploaded;
      for (final path in tryPaths) {
        _log('[Photo] upload target: bucket=profiles path=$path');
        try {
          uploaded = await _storage.upload(
            path,
            finalBytes,
            contentType: 'image/jpeg',
          );
          _log('[Photo] upload complete: returned=$uploaded');
          break;
        } catch (e) {
          final es = e.toString();
          _log('[Photo] upload failed for path=$path error=$es');
          final isRls403 =
              es.contains('StorageException') && es.contains('403');
          if (!isRls403) {
            // Non-RLS error: stop retrying
            rethrow;
          }
          // RLS 403: try next path (likely auth.uid root)
          continue;
        }
      }

      if (uploaded == null) {
        throw Exception('All upload attempts failed');
      }
      // Return storage path (Supabase) or permanent URL (HTTP)
      _log('[Photo] EXIT pickEditCompressAndUpload (success)');
      return uploaded;
    } catch (e) {
      _log('[Photo] ERROR pickEditCompressAndUpload: $e');
      _log('[Photo] EXIT pickEditCompressAndUpload (error)');
      return null;
    }
  }

  @override
  Future<void> maybeDeleteByUrl(String url) async {
    try {
      _log('[Photo] maybeDeleteByUrl ENTER: url=$url');
      // If it's a full URL, we cannot reliably map to storage path; try backend resolver
      if (url.startsWith('http://') || url.startsWith('https://')) {
        // Optional: backend path lookup could be added here. For now, skip.
        _log('[Photo] skip delete, full URL provided (no resolver)');
        return;
      }
      await sl.storageService.delete(url);
      _log('[Photo] delete OK: path=$url');
    } catch (e) {
      _log('[Photo] ERROR maybeDeleteByUrl: $e');
    }
  }

  String _randString(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<bool> _ensurePermissions({required bool fromCamera}) async {
    try {
      _log('[Photo] ensurePermissions ENTER: fromCamera=$fromCamera');
      if (fromCamera) {
        final cam = await Permission.camera.request();
        _log('[Photo] camera permission: $cam');
        if (!cam.isGranted) {
          _log('[Photo] camera permission DENIED');
          return false;
        }
      }
      if (Platform.isAndroid) {
        // NOTE: For Android 13+ the system photo picker doesn't require storage permission.
        // We won't block gallery on denied storage. We'll still request once for older devices.
        final st = await Permission.storage.request();
        _log(
          '[Photo] android storage/media permission: $st (non-blocking for gallery)',
        );
        // Do not return false here for gallery; proceed and let picker handle.
      } else if (Platform.isIOS) {
        // Ask for photos on iOS; camera was handled above if needed
        final ph = await Permission.photos.request();
        _log('[Photo] iOS photos permission: $ph');
        if (!ph.isGranted && !fromCamera) {
          _log('[Photo] photos permission DENIED');
          return false;
        }
      }
      _log('[Photo] ensurePermissions EXIT: granted=true');
      return true;
    } catch (e) {
      _log('[Photo] ERROR ensurePermissions: $e');
      return false;
    }
  }
}
