import 'dart:io';
import '../../../data/models/grammar_correction_model.dart';
import '../../../data/models/duplicate_check_model.dart';

/// Sentinel used by [SubmitComplaintState.copyWith] to distinguish "field not
/// passed" (keep current value) from "field explicitly passed as null" (the
/// plain `field ?? this.field` pattern can't tell these apart).
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class SubmitComplaintState {
  final bool isLoading;
  final String? subject;
  final String? description;
  final String? location;
  final String? categoryId;
  final String? severity;
  final List<File> photos;
  final GrammarCorrectionModel? grammarResult;
  final bool grammarDismissed;
  final Map<String, dynamic>? aiPreview;
  final bool aiPreviewAccepted;
  final DuplicateCheckModel? duplicateResult;
  final bool isSuccess;
  final String? errorMessage;
  final bool isDraft;
  final bool isCheckingGrammar;
  final bool isCheckingDuplicate;
  final bool isCategorizing;

  const SubmitComplaintState({
    this.isLoading = false,
    this.subject,
    this.description,
    this.location,
    this.categoryId,
    this.severity,
    this.photos = const [],
    this.grammarResult,
    this.grammarDismissed = false,
    this.aiPreview,
    this.aiPreviewAccepted = false,
    this.duplicateResult,
    this.isSuccess = false,
    this.errorMessage,
    this.isDraft = false,
    this.isCheckingGrammar = false,
    this.isCheckingDuplicate = false,
    this.isCategorizing = false,
  });

  SubmitComplaintState copyWith({
    bool? isLoading,
    String? subject,
    String? description,
    String? location,
    String? categoryId,
    String? severity,
    List<File>? photos,
    Object? grammarResult = _unset,
    bool? grammarDismissed,
    Object? aiPreview = _unset,
    bool? aiPreviewAccepted,
    DuplicateCheckModel? duplicateResult,
    bool? isSuccess,
    String? errorMessage,
    bool? isDraft,
    bool? isCheckingGrammar,
    bool? isCheckingDuplicate,
    bool? isCategorizing,
  }) {
    return SubmitComplaintState(
      isLoading: isLoading ?? this.isLoading,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      severity: severity ?? this.severity,
      photos: photos ?? this.photos,
      grammarResult: identical(grammarResult, _unset)
          ? this.grammarResult
          : grammarResult as GrammarCorrectionModel?,
      grammarDismissed: grammarDismissed ?? this.grammarDismissed,
      aiPreview: identical(aiPreview, _unset)
          ? this.aiPreview
          : aiPreview as Map<String, dynamic>?,
      aiPreviewAccepted: aiPreviewAccepted ?? this.aiPreviewAccepted,
      duplicateResult: duplicateResult ?? this.duplicateResult,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      isDraft: isDraft ?? this.isDraft,
      isCheckingGrammar: isCheckingGrammar ?? this.isCheckingGrammar,
      isCheckingDuplicate: isCheckingDuplicate ?? this.isCheckingDuplicate,
      isCategorizing: isCategorizing ?? this.isCategorizing,
    );
  }
}
