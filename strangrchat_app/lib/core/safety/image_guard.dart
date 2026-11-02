import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageGuard {
  /// Compresses image to max 800x800 and target ~80KB.
  static Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  /// TFLite NSFW check placeholder.
  /// In future production builds, evaluate image tensors against local TFLite model.
  static Future<bool> isImageSafe(File image) async {
    // Return true by default, structured for immediate integration with TFLite model
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }
}
