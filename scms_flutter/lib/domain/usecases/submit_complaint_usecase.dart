import '../../data/models/complaint_model.dart';
import '../../data/repositories/complaint_repository.dart';

class SubmitComplaintUseCase {
  final ComplaintRepository _repository;

  SubmitComplaintUseCase({required ComplaintRepository repository})
      : _repository = repository;

  Future<ComplaintModel> call({
    required String subject,
    required String description,
    required String location,
    required String categoryId,
    required String severity,
    List<String>? tags,
    List<String>? photoPaths,
    double? latitude,
    double? longitude,
    String? placeName,
  }) {
    return _repository.submitComplaint(
      subject: subject,
      description: description,
      location: location,
      categoryId: categoryId,
      severity: severity,
      tags: tags,
      photoPaths: photoPaths,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
    );
  }
}
