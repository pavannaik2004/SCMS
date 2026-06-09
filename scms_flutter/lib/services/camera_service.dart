import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

/// Handles all camera and image gallery interactions for complaint media.
///
/// Uses [image_picker] for a unified cross-platform API.
/// Permission checks are done before every capture to give clear UX feedback.
class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  final _picker = ImagePicker();

  // ─── Permission Helpers ────────────────────────────────────────────────────

  /// Returns true if the camera permission is granted.
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Requests camera permission. Returns true if granted.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      AppLogger.warning('CameraService: Camera permission permanently denied.');
    }
    return status.isGranted;
  }

  /// Returns true if the photos permission is granted.
  Future<bool> hasGalleryPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Requests gallery/photos permission. Returns true if granted.
  Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // ─── Capture / Pick ────────────────────────────────────────────────────────

  /// Opens the camera to capture a single photo.
  ///
  /// Compresses to [AppConstants.maxPhotoSizeMB] MB and 1920×1080 max resolution.
  /// Returns the captured [File], or `null` if the user cancelled or permission denied.
  Future<File?> capturePhoto() async {
    final granted = await requestCameraPermission();
    if (!granted) {
      AppLogger.warning('CameraService: Camera permission not granted.');
      return null;
    }

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: _qualityForSizeMB(AppConstants.maxPhotoSizeMB),
        preferredCameraDevice: CameraDevice.rear,
      );

      if (xFile == null) return null;

      final file = File(xFile.path);
      AppLogger.info('CameraService: Photo captured → ${file.path}');
      return file;
    } catch (e) {
      AppLogger.error('CameraService: capturePhoto failed', error: e);
      return null;
    }
  }

  /// Opens the gallery to pick a single photo.
  ///
  /// Returns the selected [File], or `null` if cancelled or permission denied.
  Future<File?> pickFromGallery() async {
    final granted = await requestGalleryPermission();
    if (!granted) {
      AppLogger.warning('CameraService: Gallery permission not granted.');
      return null;
    }

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: _qualityForSizeMB(AppConstants.maxPhotoSizeMB),
      );

      if (xFile == null) return null;

      final file = File(xFile.path);
      AppLogger.info('CameraService: Photo picked from gallery → ${file.path}');
      return file;
    } catch (e) {
      AppLogger.error('CameraService: pickFromGallery failed', error: e);
      return null;
    }
  }

  /// Opens the gallery to pick up to [maxCount] photos at once.
  ///
  /// Returns a list of selected [File]s (may be empty if cancelled).
  Future<List<File>> pickMultipleFromGallery({
    int maxCount = AppConstants.maxPhotos,
  }) async {
    final granted = await requestGalleryPermission();
    if (!granted) {
      AppLogger.warning('CameraService: Gallery permission not granted.');
      return [];
    }

    try {
      final xFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: _qualityForSizeMB(AppConstants.maxPhotoSizeMB),
        limit: maxCount,
      );

      final files = xFiles.map((x) => File(x.path)).toList();
      AppLogger.info('CameraService: Picked ${files.length} photos from gallery.');
      return files;
    } catch (e) {
      AppLogger.error('CameraService: pickMultipleFromGallery failed', error: e);
      return [];
    }
  }

  /// Returns the size of a [File] in megabytes.
  Future<double> fileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Returns true if the [file] is within the allowed photo size limit.
  Future<bool> isWithinSizeLimit(File file) async {
    final sizeMB = await fileSizeMB(file);
    return sizeMB <= AppConstants.maxPhotoSizeMB;
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  /// Maps a max size in MB to an image quality percentage (0–100).
  int _qualityForSizeMB(int maxMB) {
    if (maxMB >= 10) return 90;
    if (maxMB >= 5) return 80;
    if (maxMB >= 2) return 65;
    return 50;
  }
}
