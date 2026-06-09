import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils/logger.dart';
import '../core/utils/watermark_painter.dart';

/// Stamps GPS and datetime watermarks onto complaint photos.
///
/// Uses Flutter's Canvas/CustomPaint pipeline to paint the [WatermarkPainter]
/// overlay onto an in-memory image, then saves it as a new PNG next to the
/// original. The original file is NOT modified.
class WatermarkService {
  WatermarkService._();
  static final WatermarkService instance = WatermarkService._();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Stamps a location + datetime watermark onto [sourceFile].
  ///
  /// - [locationText]   : Human-readable place name (e.g. "Block A, RVCE").
  /// - [dateTimeText]   : Formatted capture timestamp (e.g. "09 Jun 2026, 10:15 AM").
  /// - [additionalInfo] : Optional extra line (e.g. enrollment number).
  ///
  /// Returns a new [File] with the watermark applied, saved in the app's
  /// temp directory. Returns [sourceFile] unchanged if anything fails.
  Future<File> applyWatermark({
    required File sourceFile,
    required String locationText,
    required String dateTimeText,
    String? additionalInfo,
  }) async {
    try {
      // 1. Decode the source image bytes
      final imageBytes = await sourceFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final sourceImage = frame.image;

      final width = sourceImage.width.toDouble();
      final height = sourceImage.height.toDouble();

      // 2. Create a PictureRecorder and draw the source image first
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, width, height),
      );

      // Draw the original image
      canvas.drawImage(sourceImage, Offset.zero, Paint());

      // 3. Paint the watermark strip on top using WatermarkPainter
      final painter = WatermarkPainter(
        locationText: locationText,
        dateTimeText: dateTimeText,
        additionalInfo: additionalInfo,
      );
      painter.paint(canvas, Size(width, height));

      // 4. Rasterise to PNG bytes
      final picture = recorder.endRecording();
      final resultImage = await picture.toImage(
        sourceImage.width,
        sourceImage.height,
      );
      final byteData = await resultImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        AppLogger.warning(
          'WatermarkService: toByteData returned null — returning original.',
        );
        return sourceFile;
      }

      final pngBytes = byteData.buffer.asUint8List();

      // 5. Save watermarked image to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'wm_${DateTime.now().millisecondsSinceEpoch}_${_baseName(sourceFile)}';
      final outputFile = File('${tempDir.path}/$fileName');
      await outputFile.writeAsBytes(pngBytes, flush: true);

      AppLogger.info('WatermarkService: Stamped → ${outputFile.path}');
      return outputFile;
    } catch (e) {
      AppLogger.error('WatermarkService: applyWatermark failed', error: e);
      // Fail-safe: return original so upload is not blocked
      return sourceFile;
    }
  }

  /// Convenience: applies watermark to multiple files in parallel.
  Future<List<File>> applyToAll({
    required List<File> files,
    required String locationText,
    required String dateTimeText,
    String? additionalInfo,
  }) async {
    final futures = files.map(
      (f) => applyWatermark(
        sourceFile: f,
        locationText: locationText,
        dateTimeText: dateTimeText,
        additionalInfo: additionalInfo,
      ),
    );
    return Future.wait(futures);
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  String _baseName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }
}
