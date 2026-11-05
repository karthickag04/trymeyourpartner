class VideoUrlHelper {
  // List of known working video URLs for fallback
  static const List<String> fallbackVideos = [
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
  ];

  /// Validates if a video URL is likely to work on web
  static bool isWebCompatibleUrl(String url) {
    // Check if URL is HTTPS (required for modern browsers)
    if (!url.startsWith('https://')) {
      return false;
    }

    // Check for common video file extensions
    const videoExtensions = ['.mp4', '.webm', '.ogg'];
    return videoExtensions.any((ext) => url.toLowerCase().contains(ext));
  }

  /// Gets a web-compatible video URL, with fallback if needed
  static String getWebCompatibleUrl(String originalUrl) {
    // If the original URL is web-compatible, use it
    if (isWebCompatibleUrl(originalUrl)) {
      return originalUrl;
    }

    // Convert HTTP to HTTPS if possible
    if (originalUrl.startsWith('http://')) {
      String httpsUrl = originalUrl.replaceFirst('http://', 'https://');
      if (isWebCompatibleUrl(httpsUrl)) {
        return httpsUrl;
      }
    }

    // Return a fallback video URL
    return fallbackVideos[originalUrl.hashCode.abs() % fallbackVideos.length];
  }

  /// Gets a random fallback video URL
  static String getRandomFallbackUrl() {
    return fallbackVideos[DateTime.now().millisecondsSinceEpoch %
        fallbackVideos.length];
  }

  /// Checks if URL points to a demo/sample video service
  static bool isDemoUrl(String url) {
    const demoHosts = [
      'sample-videos.com',
      'commondatastorage.googleapis.com',
      'test-videos.co.uk',
    ];

    return demoHosts.any((host) => url.contains(host));
  }
}
