import '../../data/models/analytics_model.dart';
import '../../data/repositories/complaint_repository.dart';

class GetAnalyticsUseCase {
  final ComplaintRepository _repository;

  GetAnalyticsUseCase({required ComplaintRepository repository})
      : _repository = repository;

  Future<AnalyticsModel> call() {
    return _repository.getAnalyticsSummary();
  }
}
