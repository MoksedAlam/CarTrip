import 'dart:convert';
import 'package:flutter/material.dart';

class AvatarHelper {
  /// Returns an ImageProvider suitable for CircleAvatar or Image widgets.
  /// Seamlessly supports base64 data URIs (from Camera/Gallery) and web URLs.
  static ImageProvider? getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) return null;
    final trimmed = photoUrl.trim();

    if (trimmed.startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64String = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('[AvatarHelper] Error decoding base64 avatar: $e');
        return null;
      }
    }

    try {
      return NetworkImage(trimmed);
    } catch (e) {
      debugPrint('[AvatarHelper] Invalid image URL: $e');
      return null;
    }
  }
}
