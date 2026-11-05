import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageGuard {
  /// Resizes and compresses the image in memory before it is sent.
  static Future<Uint8List?> compressImage(Uint8List imageBytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );

      if (result.isEmpty) return null;
      return result;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  /// Placeholder for a local TFLite image check; it currently does not screen.
  static Future<bool> isImageSafe(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }
}
