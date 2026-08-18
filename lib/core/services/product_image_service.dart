import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Owns product image files on disk.
///
/// `image_picker` hands back a path inside the app's **cache** directory, which
/// the OS is free to purge at any time. Storing that path in the database means
/// images silently disappear later — and for photo-only catalog templates that
/// makes the whole catalog render blank. Every picked image is therefore copied
/// into permanent app-documents storage (and downscaled, so a 20-product
/// catalog does not blow up memory while the PDF is built).
class ProductImageService {
  static const String _folderName = 'product_images';
  static const int _maxDimension = 1280;
  static const int _quality = 82;
  static const _uuid = Uuid();

  /// `<appDocuments>/product_images`, created on first use.
  static Future<Directory> _imagesDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// True when [path] already lives in our permanent folder.
  static bool isPersisted(String path) =>
      path.replaceAll('\\', '/').contains('/$_folderName/');

  /// True when the product has an image path recorded but the file is gone.
  static bool isMissing(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    return !File(path).existsSync();
  }

  /// Copies a freshly picked image into permanent storage, downscaling it on
  /// the way in. Returns the new permanent path, or the original path if the
  /// copy fails (never returns null for a file that exists, so picking an
  /// image never silently loses the user's selection).
  static Future<String> persist(String sourcePath) async {
    if (isPersisted(sourcePath)) return sourcePath;

    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    try {
      final dir = await _imagesDir();
      final target = File('${dir.path}/${_uuid.v4()}.jpg');

      Uint8List? compressed;
      try {
        compressed = await FlutterImageCompress.compressWithFile(
          sourcePath,
          minWidth: _maxDimension,
          minHeight: _maxDimension,
          quality: _quality,
        );
      } catch (e) {
        debugPrint('ProductImageService: compression failed, copying raw — $e');
      }

      if (compressed != null && compressed.isNotEmpty) {
        await target.writeAsBytes(compressed);
      } else {
        await source.copy(target.path);
      }
      return target.path;
    } catch (e) {
      debugPrint('ProductImageService: persist failed for $sourcePath — $e');
      return sourcePath;
    }
  }

  /// Rescues images still sitting in the cache directory from a build that
  /// stored temporary paths. Returns the new path when the file was moved into
  /// permanent storage, null when there is nothing to do (already persisted,
  /// no path, or the file is already gone — a purged cache file is
  /// unrecoverable).
  static Future<String?> repairIfNeeded(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    if (isPersisted(path)) return null;
    if (!File(path).existsSync()) return null;
    final persisted = await persist(path);
    return persisted == path ? null : persisted;
  }
}
