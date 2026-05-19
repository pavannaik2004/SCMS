import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/complaint_model.dart';
import '../../models/category_model.dart';
import '../../models/department_model.dart';
import '../../models/grammar_correction_model.dart';
import '../../models/duplicate_check_model.dart';
import '../../models/analytics_model.dart';

/// Remote data source for all complaint-related API calls
class ComplaintRemoteDataSource {
  final DioClient _dioClient;

  ComplaintRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  // ─── Complaint CRUD ───────────────────────────────────────

  /// Get current user's complaints with optional status filter
  Future<List<ComplaintModel>> getMyComplaints({
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _dioClient.dio.get(
        ApiConstants.myComplaints,
        queryParameters: queryParams,
      );

      final list = response.data as List<dynamic>;
      return list
          .map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch complaints',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get a single complaint by ID
  Future<ComplaintModel> getComplaintById(String id) async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.complaintById(id));
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch complaint',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Submit a new complaint (multipart)
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
    try {
      final formData = FormData.fromMap({
        'subject': subject,
        'description': description,
        'location': location,
        'categoryId': categoryId,
        'severity': severity,
        if (tags != null) 'tags': tags,
        if (latitude != null) 'gpsLatitude': latitude,
        if (longitude != null) 'gpsLongitude': longitude,
        if (placeName != null) 'gpsPlaceName': placeName,
      });

      if (photoPaths != null) {
        for (final path in photoPaths) {
          formData.files.add(MapEntry(
            'photos',
            await MultipartFile.fromFile(path),
          ));
        }
      }

      final response = await _dioClient.dio.post(
        ApiConstants.complaints,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to submit complaint',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Update complaint status (Staff/Admin)
  Future<void> updateComplaintStatus(
    String id, {
    required String newStatus,
    String? notes,
  }) async {
    try {
      await _dioClient.dio.patch(
        ApiConstants.complaintStatus(id),
        data: {'newStatus': newStatus, 'notes': notes},
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to update status',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Submit rating for a resolved complaint
  Future<void> submitRating(String id, {required double rating, String? comment}) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.complaintRating(id),
        data: {'rating': rating, 'comment': comment},
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to submit rating',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get all complaints (Admin only) with filters
  Future<List<ComplaintModel>> getAllComplaints({
    String? status,
    String? departmentId,
    String? categoryId,
    String? severity,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        if (status != null) 'status': status,
        if (departmentId != null) 'departmentId': departmentId,
        if (categoryId != null) 'categoryId': categoryId,
        if (severity != null) 'severity': severity,
        if (search != null) 'search': search,
      };

      final response = await _dioClient.dio.get(
        ApiConstants.complaints,
        queryParameters: queryParams,
      );

      final list = response.data as List<dynamic>;
      return list
          .map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch complaints',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── AI Endpoints ─────────────────────────────────────────

  /// Get AI categorization preview
  Future<Map<String, dynamic>> getAiPreview(String text) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.aiCategorize,
        data: {'text': text},
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      // AI failure is non-blocking — return empty
      return {};
    }
  }

  /// Grammar check
  Future<GrammarCorrectionModel> grammarCheck(String text) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.aiGrammarCheck,
        data: {'text': text},
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return GrammarCorrectionModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return GrammarCorrectionModel.noCorrections(text);
    }
  }

  /// Duplicate check
  Future<DuplicateCheckModel> checkDuplicate(String text, {String? zoneId, List<String>? tags}) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.aiCheckDuplicate,
        data: {'text': text, 'zoneId': zoneId, 'tags': tags},
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return DuplicateCheckModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return DuplicateCheckModel.noDuplicates();
    }
  }

  // ─── Reference Data ───────────────────────────────────────

  Future<List<DepartmentModel>> getDepartments() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.departments);
      final list = response.data as List<dynamic>;
      return list.map((j) => DepartmentModel.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch departments',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.categories);
      final list = response.data as List<dynamic>;
      return list.map((j) => CategoryModel.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch categories',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── Analytics ────────────────────────────────────────────

  Future<AnalyticsModel> getAnalyticsSummary() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.analyticsSummary);
      return AnalyticsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to fetch analytics',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
