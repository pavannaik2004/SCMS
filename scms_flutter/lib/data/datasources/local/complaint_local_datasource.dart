import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// Hive-persisted offline complaint draft
class ComplaintDraft extends HiveObject {
  String subject;
  String description;
  String location;
  String? categoryId;
  String? severity;
  List<String> localPhotoPaths;
  DateTime savedAt;

  ComplaintDraft({
    required this.subject,
    required this.description,
    required this.location,
    this.categoryId,
    this.severity,
    this.localPhotoPaths = const [],
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();
}

/// Manual Hive TypeAdapter for ComplaintDraft
class ComplaintDraftAdapter extends TypeAdapter<ComplaintDraft> {
  @override
  final int typeId = 0;

  @override
  ComplaintDraft read(BinaryReader reader) {
    return ComplaintDraft(
      subject: reader.readString(),
      description: reader.readString(),
      location: reader.readString(),
      categoryId: reader.readString(),
      severity: reader.readString(),
      localPhotoPaths: reader.readStringList(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ComplaintDraft obj) {
    writer.writeString(obj.subject);
    writer.writeString(obj.description);
    writer.writeString(obj.location);
    writer.writeString(obj.categoryId ?? '');
    writer.writeString(obj.severity ?? '');
    writer.writeStringList(obj.localPhotoPaths);
    writer.writeInt(obj.savedAt.millisecondsSinceEpoch);
  }
}

/// Local data source for offline complaint drafts using Hive
class ComplaintLocalDataSource {
  Box<ComplaintDraft>? _draftsBox;

  Future<Box<ComplaintDraft>> get _box async {
    if (_draftsBox != null && _draftsBox!.isOpen) return _draftsBox!;
    _draftsBox = await Hive.openBox<ComplaintDraft>(AppConstants.draftBoxName);
    return _draftsBox!;
  }

  /// Save a complaint draft
  Future<int> saveDraft(ComplaintDraft draft) async {
    final box = await _box;
    return await box.add(draft);
  }

  /// Get all saved drafts
  Future<List<ComplaintDraft>> getDrafts() async {
    final box = await _box;
    return box.values.toList();
  }

  /// Get draft count
  Future<int> getDraftCount() async {
    final box = await _box;
    return box.length;
  }

  /// Delete a draft by key
  Future<void> deleteDraft(int key) async {
    final box = await _box;
    await box.delete(key);
  }

  /// Delete all drafts
  Future<void> clearDrafts() async {
    final box = await _box;
    await box.clear();
  }
}
