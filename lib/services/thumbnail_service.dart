import 'dart:io';

import 'package:heif_converter/heif_converter.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import '../models/media_item.dart';
import '../utils/constants.dart';
import '../utils/file_utils.dart';
import '../utils/format_utils.dart';
import '../utils/isolate_utils.dart';

class ImageDimensions {
  const ImageDimensions(this.width, this.height);

  final int width;
  final int height;
}

class ThumbnailService {
  ThumbnailService(this._logger);

  final Logger _logger;

  Future<String?> ensureThumbnail(
    MediaItem item, {
    int longestSide = AppLimits.thumbLongestSide,
  }) async {
    if (!item.isSupported) {
      return null;
    }

    final thumbDir = await ensureThumbDirectory();
    final thumbPath = p.join(thumbDir.path, '${item.id}.jpg');

    final thumbFile = File(thumbPath);
    if (thumbFile.existsSync()) {
      return thumbPath;
    }

    String source = item.originalPath;
    String? temporaryConverted;

    try {
      if (item.ext == 'heic' || item.ext == 'heif') {
        temporaryConverted = p.join(thumbDir.path, '${item.id}_source.jpg');
        final converted = await HeifConverter.convert(
          item.originalPath,
          output: temporaryConverted,
          format: 'jpg',
        );
        if (converted == null || !File(converted).existsSync()) {
          return null;
        }
        source = converted;
      }

      await runInBackground(() {
        _createThumbnailSync(
          sourcePath: source,
          outputPath: thumbPath,
          longestSide: longestSide,
        );
      });

      return thumbPath;
    } catch (error, stackTrace) {
      _logger.w(
        'Thumbnail creation failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      if (temporaryConverted != null) {
        await safeDeleteFile(temporaryConverted);
      }
    }
  }

  Future<ImageDimensions?> probeDimensions(String filePath) async {
    final ext = extensionFromPath(filePath);
    if (!(ext == 'jpg' || ext == 'jpeg' || ext == 'png')) {
      return null;
    }

    try {
      return await runInBackground(() {
        final bytes = File(filePath).readAsBytesSync();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          return null;
        }
        return ImageDimensions(decoded.width, decoded.height);
      });
    } catch (error, stackTrace) {
      _logger.w('Dimension probe failed', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> deleteThumbnail(String? thumbPath) async {
    if (thumbPath == null) {
      return;
    }
    await safeDeleteFile(thumbPath);
  }
}

void _createThumbnailSync({
  required String sourcePath,
  required String outputPath,
  required int longestSide,
}) {
  final bytes = File(sourcePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Could not decode image for thumbnail.');
  }

  final shouldResize =
      decoded.width > longestSide || decoded.height > longestSide;

  final resized = shouldResize
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? longestSide : null,
          height: decoded.height > decoded.width ? longestSide : null,
        )
      : decoded;

  final encoded = img.encodeJpg(resized, quality: 84);

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(encoded, flush: true);
}
