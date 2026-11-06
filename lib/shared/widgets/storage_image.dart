import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/di/service_locator.dart';

/// StorageImage renders an image where `src` can be either:
/// - An absolute URL (http/https), rendered directly
/// - A storage path (e.g., Supabase private bucket object path), resolved via signed URL
/// - null/empty, in which case [emptyWidget] is shown
class StorageImage extends StatelessWidget {
  final String? src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const StorageImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.emptyWidget,
  });

  Future<String?> _resolve(String? input) async {
    if (input == null || input.isEmpty) return null;
    if (input.startsWith('http')) return input;
    try {
      return await sl.storageService.getSignedUrl(input);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (src == null || src!.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: emptyWidget ?? const SizedBox.shrink(),
      );
    }
    if (src!.startsWith('http')) {
      return SizedBox(
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: src!,
          fit: fit,
          placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
          errorWidget: (_, __, ___) =>
              errorWidget ?? const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    return FutureBuilder<String?>(
      future: _resolve(src),
      builder: (context, snap) {
        final resolved = snap.data;
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: placeholder ?? const SizedBox.shrink(),
          );
        }
        if (resolved == null || resolved.isEmpty) {
          return SizedBox(
            width: width,
            height: height,
            child: errorWidget ?? (emptyWidget ?? const SizedBox.shrink()),
          );
        }
        return SizedBox(
          width: width,
          height: height,
          child: CachedNetworkImage(
            imageUrl: resolved,
            fit: fit,
            placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
            errorWidget: (_, __, ___) =>
                errorWidget ?? const Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }
}
