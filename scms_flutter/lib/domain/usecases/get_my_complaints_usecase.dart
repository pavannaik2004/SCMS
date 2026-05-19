import '../../data/models/complaint_model.dart';
import '../../data/repositories/complaint_repository.dart';

class GetMyComplaintsUseCase {
  final ComplaintRepository _repository;

  GetMyComplaintsUseCase({required ComplaintRepository repository})
      : _repository = repository;

  Future<List<ComplaintModel>> call({String? status, int page = 0}) {
    return _repository.getMyComplaints(status: status, page: page);
  }
}
