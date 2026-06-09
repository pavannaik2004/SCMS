import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/network/dio_client.dart';
import '../core/utils/logger.dart';
import '../data/models/grammar_correction_model.dart';

/// Thin service layer for on-demand grammar checks from the AI pipeline.
///
/// This is separate from [ComplaintRemoteDatasource] so that the BLoC layer
/// can call grammar checks independently (e.g. for debounced typing) without
/// depending on the full complaint repository.
///
/// The call chain is:
///   Flutter [GrammarService] → Node.js `/api/ai/grammar-check`
///                            → Python AI `/grammar-check` (Gemini)
///
/// Fails gracefully: if the AI service is unavailable, returns a
/// [GrammarCorrectionModel.noCorrections] so the user is not blocked.
class GrammarService {
  GrammarService._();
  static final GrammarService instance = GrammarService._();

  // Lazy DioClient — initialised on first call; avoids issues if the service
  // is constructed before flutter_dotenv has loaded.
  DioClient? _dioClient;

  DioClient get _client {
    _dioClient ??= DioClient();
    return _dioClient!;
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Sends [text] to the backend grammar-check endpoint and returns the result.
  ///
  /// - Returns [GrammarCorrectionModel.noCorrections] on any network / AI error.
  /// - Skips the call if [text] is shorter than [AppConstants.minCharsForGrammar].
  Future<GrammarCorrectionModel> checkGrammar(String text) async {
    if (text.trim().length < AppConstants.minCharsForGrammar) {
      AppLogger.info('GrammarService: Text too short — skipping check.');
      return GrammarCorrectionModel.noCorrections(text);
    }

    try {
      AppLogger.info(
        'GrammarService: Sending grammar check (${text.length} chars)...',
      );

      final response = await _client.dio.post(
        ApiConstants.aiGrammarCheck,
        data: {'text': text},
        options: Options(
          receiveTimeout: const Duration(seconds: AppConstants.aiTimeoutSec),
        ),
      );

      final model = GrammarCorrectionModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      AppLogger.info(
        'GrammarService: Result — hasCorrections=${model.hasCorrections}, '
        'diffs=${model.diffs.length}',
      );

      return model;
    } on DioException catch (e) {
      AppLogger.warning(
        'GrammarService: Network error (${e.type.name}) — returning safe default.',
      );
      return GrammarCorrectionModel.noCorrections(text);
    } catch (e) {
      AppLogger.error('GrammarService: Unexpected error', error: e);
      return GrammarCorrectionModel.noCorrections(text);
    }
  }

  /// Returns true if [text] is long enough to warrant a grammar check.
  bool shouldCheck(String text) =>
      text.trim().length >= AppConstants.minCharsForGrammar;
}
