import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../datasources/local/complaint_local_datasource.dart';
import '../datasources/remote/complaint_remote_datasource.dart';
import '../models/complaint_model.dart';
import '../models/category_model.dart';
import '../models/department_model.dart';
import '../models/grammar_correction_model.dart';
import '../models/duplicate_check_model.dart';
import '../models/analytics_model.dart';
import '../models/user_model.dart';

class ComplaintRepository {
  final ComplaintRemoteDataSource _remoteDataSource;
  final ComplaintLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ComplaintRepository({
    required ComplaintRemoteDataSource remoteDataSource,
    required ComplaintLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  // ─── Complaints ───────────────────────────────────────────

  Future<List<ComplaintModel>> getMyComplaints({String? status, int page = 0}) async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      return await _remoteDataSource.getMyComplaints(status: status, page: page);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  Future<ComplaintModel> getComplaintById(String id) async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      return await _remoteDataSource.getComplaintById(id);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  Future<ComplaintModel> submitComplaint({
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
  }) async {
    if (!await _networkInfo.isConnected) {
      // Save as offline draft
      final draft = ComplaintDraft(
        subject: subject,
        description: description,
        location: location,
        categoryId: categoryId,
        severity: severity,
        localPhotoPaths: photoPaths ?? [],
      );
      await _localDataSource.saveDraft(draft);
      throw const NetworkFailure(message: 'You are offline. Complaint saved as draft.');
    }

    try {
      return await _remoteDataSource.submitComplaint(
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
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  Future<List<UserModel>> getStaff() async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      return await _remoteDataSource.getStaff();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  Future<void> assignComplaint(String id, String assignedToId) async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      await _remoteDataSource.assignComplaint(id, assignedToId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  Future<void> updateComplaintStatus(String id, {required String newStatus, String? notes}) async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      await _remoteDataSource.updateComplaintStatus(id, newStatus: newStatus, notes: notes);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  Future<void> submitRating(String id, {required double rating, String? comment}) async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      await _remoteDataSource.submitRating(id, rating: rating, comment: comment);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  Future<List<ComplaintModel>> getAllComplaints({
    String? status, String? departmentId, String? categoryId,
    String? severity, String? search, int page = 0,
  }) async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      return await _remoteDataSource.getAllComplaints(
        status: status, departmentId: departmentId, categoryId: categoryId,
        severity: severity, search: search, page: page,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  // ─── AI ───────────────────────────────────────────────────

  Future<GrammarCorrectionModel> grammarCheck(String text) =>
      _remoteDataSource.grammarCheck(text);

  Future<Map<String, dynamic>> getAiPreview(String text) =>
      _remoteDataSource.getAiPreview(text);

  Future<DuplicateCheckModel> checkDuplicate(String text, {String? zoneId, List<String>? tags}) =>
      _remoteDataSource.checkDuplicate(text, zoneId: zoneId, tags: tags);

  /// Fetches similar complaints for an already-submitted complaint.
  ///
  /// Retrieves the complaint by [id], then runs the AI duplicate check
  /// against its description. Used by [DuplicateComplaintsPage].
  Future<DuplicateCheckModel> getDuplicatesForComplaint(String id) async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try {
      final complaint = await _remoteDataSource.getComplaintById(id);
      return await _remoteDataSource.checkDuplicate(
        complaint.description,
        tags: complaint.tags,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    }
  }

  // ─── Reference Data ───────────────────────────────────────

  Future<List<DepartmentModel>> getDepartments() async {
    try { return await _remoteDataSource.getDepartments(); }
    on ServerException catch (e) { throw ServerFailure(message: e.message); }
  }

  Future<List<CategoryModel>> getCategories() async {
    try { return await _remoteDataSource.getCategories(); }
    on ServerException catch (e) { throw ServerFailure(message: e.message); }
  }

  // ─── Analytics ────────────────────────────────────────────

  Future<AnalyticsModel> getAnalyticsSummary() async {
    if (!await _networkInfo.isConnected) throw const NetworkFailure();
    try { return await _remoteDataSource.getAnalyticsSummary(); }
    on ServerException catch (e) { throw ServerFailure(message: e.message); }
  }

  // ─── Drafts ───────────────────────────────────────────────

  Future<List<ComplaintDraft>> getDrafts() => _localDataSource.getDrafts();
  Future<int> getDraftCount() => _localDataSource.getDraftCount();
  Future<void> deleteDraft(int key) => _localDataSource.deleteDraft(key);
  Future<void> clearDrafts() => _localDataSource.clearDrafts();
}
