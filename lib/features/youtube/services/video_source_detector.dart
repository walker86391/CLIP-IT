import 'package:flutter/material.dart';

/// Supported video platforms detected by the application.
enum VideoSourcePlatform {
  youtube,
  instagram,
  generic,
  unknown,
}

/// Script and detector utility to identify whether a URL belongs to
/// YouTube, Instagram Reels, or generic video source.
class VideoSourceDetector {
  VideoSourceDetector._();

  static final RegExp _youtubePattern = RegExp(
    r'^(https?:\/\/)?((www|m)\.)?(youtube\.com|youtu\.be)\/.+$',
    caseSensitive: false,
  );

  static final RegExp _instagramPattern = RegExp(
    r'^(https?:\/\/)?((www)\.)?(instagram\.com|instagr\.am)\/(reel|reels|p|tv|share)\/.+$',
    caseSensitive: false,
  );

  /// Detects the platform of the given video URL.
  static VideoSourcePlatform detect(String? rawUrl) {
    if (rawUrl == null) return VideoSourcePlatform.unknown;
    final url = rawUrl.trim();
    if (url.isEmpty) return VideoSourcePlatform.unknown;

    if (_instagramPattern.hasMatch(url) ||
        url.toLowerCase().contains('instagram.com') ||
        url.toLowerCase().contains('instagr.am')) {
      return VideoSourcePlatform.instagram;
    }

    if (_youtubePattern.hasMatch(url) ||
        url.toLowerCase().contains('youtube.com') ||
        url.toLowerCase().contains('youtu.be')) {
      return VideoSourcePlatform.youtube;
    }

    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return VideoSourcePlatform.generic;
    }

    return VideoSourcePlatform.unknown;
  }

  static bool isInstagram(String? url) =>
      detect(url) == VideoSourcePlatform.instagram;

  static bool isYouTube(String? url) =>
      detect(url) == VideoSourcePlatform.youtube;

  static String platformDisplayName(VideoSourcePlatform platform) {
    switch (platform) {
      case VideoSourcePlatform.instagram:
        return 'Instagram Reel';
      case VideoSourcePlatform.youtube:
        return 'YouTube Video';
      case VideoSourcePlatform.generic:
        return 'Web Video';
      case VideoSourcePlatform.unknown:
        return 'Video URL';
    }
  }

  static IconData platformIcon(VideoSourcePlatform platform) {
    switch (platform) {
      case VideoSourcePlatform.instagram:
        return Icons.camera_alt_rounded;
      case VideoSourcePlatform.youtube:
        return Icons.play_circle_fill_rounded;
      case VideoSourcePlatform.generic:
        return Icons.link_rounded;
      case VideoSourcePlatform.unknown:
        return Icons.video_collection_rounded;
    }
  }

  static Color platformColor(VideoSourcePlatform platform) {
    switch (platform) {
      case VideoSourcePlatform.instagram:
        return const Color(0xFFE1306C);
      case VideoSourcePlatform.youtube:
        return const Color(0xFFFF0033);
      case VideoSourcePlatform.generic:
        return const Color(0xFF38BDF8);
      case VideoSourcePlatform.unknown:
        return const Color(0xFF8B5CF6);
    }
  }
}
