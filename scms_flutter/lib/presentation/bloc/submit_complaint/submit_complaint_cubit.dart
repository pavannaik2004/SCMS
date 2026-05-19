import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../data/repositories/complaint_repository.dart';
import 'submit_complaint_state.dart';

class SubmitComplaintCubit extends Cubit<SubmitComplaintState> {
  final ComplaintRepository _repository;
  Timer? _grammarDebounce;
  Timer? _categorizeDebounce;

  SubmitComplaintCubit({required ComplaintRepository repository})
      : _repository = repository,
        super(const SubmitComplaintState());

  // ─── Field Updates ────────────────────────────────────────

  void updateSubject(String value) {
    emit(state.copyWith(subject: value));
  }

  void updateDescription(String value) {
    emit(state.copyWith(description: value, grammarResult: null, aiPreview: null));

    // Trigger debounced AI checks
    if (value.length >= AppConstants.minCharsForGrammar) {
      _grammarDebounce?.cancel();
      _grammarDebounce = Timer(
        const Duration(milliseconds: AppConstants.grammarDebounceMsec),
        () => _checkGrammar(value),
      );
    }
  }

  void updateLocation(String value) {
    emit(state.copyWith(location: value));
  }

  void updateCategory(String categoryId) {
    emit(state.copyWith(categoryId: categoryId, aiPreviewAccepted: false));
  }

  void updateSeverity(String severity) {
    emit(state.copyWith(severity: severity));
  }

  void addPhoto(File photo) {
    if (state.photos.length >= AppConstants.maxPhotos) return;
    emit(state.copyWith(photos: [...state.photos, photo]));
  }

  void removePhoto(int index) {
    final photos = List<File>.from(state.photos)..removeAt(index);
    emit(state.copyWith(photos: photos));
  }

  void acceptAiPreview() {
    if (state.aiPreview == null) return;
    emit(state.copyWith(
      categoryId: state.aiPreview!['suggestedCategoryId'] as String?,
      severity: state.aiPreview!['suggestedSeverity'] as String?,
      aiPreviewAccepted: true,
    ));
  }

  // ─── AI Integration ───────────────────────────────────────

  Future<void> _checkGrammar(String text) async {
    emit(state.copyWith(isCheckingGrammar: true));
    final result = await _repository.grammarCheck(text);
    emit(state.copyWith(grammarResult: result, isCheckingGrammar: false));

    // After grammar, auto-categorize
    if (text.length >= AppConstants.minCharsForCategorize) {
      _categorizeDebounce?.cancel();
      _categorizeDebounce = Timer(
        const Duration(milliseconds: 300),
        () => _categorize(result.hasCorrections ? result.correctedText : text),
      );
    }
  }

  Future<void> _categorize(String text) async {
    emit(state.copyWith(isCategorizing: true));
    final preview = await _repository.getAiPreview(text);
    emit(state.copyWith(aiPreview: preview.isNotEmpty ? preview : null, isCategorizing: false));
  }

  void applyGrammarCorrection() {
    if (state.grammarResult?.hasCorrections == true) {
      emit(state.copyWith(
        description: state.grammarResult!.correctedText,
        grammarResult: null,
      ));
    }
  }

  // ─── Submit ───────────────────────────────────────────────

  Future<void> submit() async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Pre-submission duplicate check
    if (state.description != null && state.description!.isNotEmpty) {
      emit(state.copyWith(isCheckingDuplicate: true));
      final duplicateResult = await _repository.checkDuplicate(state.description!);
      emit(state.copyWith(duplicateResult: duplicateResult, isCheckingDuplicate: false));

      if (duplicateResult.isDuplicate) {
        emit(state.copyWith(isLoading: false));
        return; // UI will show duplicate warning — user must confirm
      }
    }

    await _submitToServer();
  }

  /// Submit after user confirms (even if duplicate detected)
  Future<void> submitAnyway() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await _submitToServer();
  }

  Future<void> _submitToServer() async {
    try {
      await _repository.submitComplaint(
        subject: state.subject ?? '',
        description: state.description ?? '',
        location: state.location ?? '',
        categoryId: state.categoryId ?? '',
        severity: state.severity ?? 'MEDIUM',
        photoPaths: state.photos.map((f) => f.path).toList(),
      );
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } on NetworkFailure catch (e) {
      emit(state.copyWith(isLoading: false, isDraft: true, errorMessage: e.message));
    } on Failure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Submission failed. Try again.'));
    }
  }

  /// Reset the form
  void reset() {
    _grammarDebounce?.cancel();
    _categorizeDebounce?.cancel();
    emit(const SubmitComplaintState());
  }

  @override
  Future<void> close() {
    _grammarDebounce?.cancel();
    _categorizeDebounce?.cancel();
    return super.close();
  }
}
