import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/utils/logger.dart';

/// Manages local file-system storage for complaint media drafts.
///
/// Responsibilities:
///  - Saving watermarked/captured photos to a persistent drafts folder
///    so they survive app restarts before the complaint is submitted.
///  - Cleaning up draft media once a complaint is submitted or discarded.
///  - Providing a single, consistent directory path for all complaint media.
///
/// The actual *upload* to the backend is handled via multipart form-data
/// inside [ComplaintRemoteDatasource.submitComplaint] — this service only
/// manages the *local* side.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _draftsFolderName = 'complaint_drafts';

  // ─── Directory Access ─────────────────────────────────────────────────────

  /// Returns (and creates if missing) the local drafts directory.
  Future<Directory> get draftsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final draftsDir = Directory('${appDir.path}/$_draftsFolderName');
    if (!draftsDir.existsSync()) {
      await draftsDir.create(recursive: true);
      AppLogger.info(
        'StorageService: Created drafts directory → ${draftsDir.path}',
      );
    }
    return draftsDir;
  }

  // ─── Save / Copy ──────────────────────────────────────────────────────────

  /// Copies [sourceFile] into the drafts folder with a unique timestamped name.
  ///
  /// Returns the new [File] in the drafts folder.
  /// Useful to persist a watermarked photo (which lives in /tmp) to a
  /// longer-lived location before the user submits the complaint.
  Future<File> saveToDrafts(File sourceFile) async {
    try {
      final dir = await draftsDirectory;
      final ext = _extension(sourceFile);
      final name = 'draft_${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = File('${dir.path}/$name');
      final saved = await sourceFile.copy(dest.path);
      AppLogger.info('StorageService: Saved → ${saved.path}');
      return saved;
    } catch (e) {
      AppLogger.error('StorageService: saveToDrafts failed', error: e);
      rethrow;
    }
  }

  /// Saves multiple files to the drafts folder. Returns the list of new files.
  Future<List<File>> saveAllToDrafts(List<File> files) async {
    final futures = files.map(saveToDrafts);
    return Future.wait(futures);
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  /// Deletes [file] if it exists. Silent no-op if already deleted.
  Future<void> deleteFile(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
        AppLogger.info('StorageService: Deleted → ${file.path}');
      }
    } catch (e) {
      AppLogger.warning(
        'StorageService: deleteFile failed for ${file.path} — ${e.toString()}',
      );
    }
  }

  /// Deletes all files in [files]. Errors are logged but do not throw.
  Future<void> deleteAll(List<File> files) async {
    await Future.wait(files.map(deleteFile));
  }

  /// Clears **all** files in the drafts folder.
  ///
  /// Call this after a complaint is successfully submitted to reclaim space.
  Future<void> clearAllDrafts() async {
    try {
      final dir = await draftsDirectory;
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          await entity.delete();
        }
      }
      AppLogger.info(
        'StorageService: Cleared ${entities.length} draft file(s).',
      );
    } catch (e) {
      AppLogger.error('StorageService: clearAllDrafts failed', error: e);
    }
  }

  // ─── Inspect ──────────────────────────────────────────────────────────────

  /// Returns all files currently saved in the drafts folder.
  Future<List<File>> listDrafts() async {
    try {
      final dir = await draftsDirectory;
      final entities = dir.listSync();
      return entities.whereType<File>().toList();
    } catch (e) {
      AppLogger.warning(
        'StorageService: listDrafts failed — ${e.toString()}',
      );
      return [];
    }
  }

  /// Returns the total size of the drafts folder in bytes.
  Future<int> draftsFolderSizeBytes() async {
    final files = await listDrafts();
    int total = 0;
    for (final f in files) {
      try {
        total += await f.length();
      } catch (_) {}
    }
    return total;
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  String _extension(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot) : '';
  }
}
