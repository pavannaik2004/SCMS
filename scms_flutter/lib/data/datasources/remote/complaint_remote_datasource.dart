import 'dart:convert';

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
import '../../models/user_model.dart';

/// Remote data source for all complaint-related API calls
class ComplaintRemoteDataSource {
  final DioClient _dioClient;

  ComplaintRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  /// Parses a complaint list response. After the Dio unwrap interceptor strips
  /// the `{success, data}` envelope, list endpoints return either a raw list or
  /// a paginated object `{ complaints: [...], pagination: {...} }`.
  List<ComplaintModel> _parseComplaintList(dynamic data) {
    final List<dynamic> list = data is Map<String, dynamic>
        ? (data['complaints'] as List<dynamic>? ?? [])
        : (data as List<dynamic>? ?? []);
    return list
        .map((json) => ComplaintModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

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

      return _parseComplaintList(response.data);
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
        // Backend expects `title`; keep `subject` for backward-compat.
        'title': subject,
        'description': description,
        'location': location,
        'categoryId': categoryId,
        'severity': severity,
        // Backend parses tags via JSON.parse first, falling back to CSV.
        if (tags != null && tags.isNotEmpty) 'tags': jsonEncode(tags),
        if (latitude != null) 'gpsLatitude': latitude,
        if (longitude != null) 'gpsLongitude': longitude,
        if (placeName != null) 'gpsPlaceName': placeName,
      });

      if (photoPaths != null) {
        for (final path in photoPaths) {
          formData.files.add(MapEntry(
            // Multer is configured as upload.array('media', 5).
            'media',
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

  /// Edit an existing complaint (submitter-only, enforced server-side).
  /// Only non-null fields are sent, so a partial update is supported.
  Future<ComplaintModel> updateComplaint(
    String id, {
    String? subject,
    String? description,
    String? location,
    String? categoryId,
    String? severity,
    List<String>? tags,
  }) async {
    try {
      final body = <String, dynamic>{
        // Backend expects `title`, not `subject`.
        if (subject != null) 'title': subject,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (categoryId != null) 'categoryId': categoryId,
        if (severity != null) 'severity': severity,
        if (tags != null) 'tags': tags,
      };
      final response = await _dioClient.dio.patch(
        ApiConstants.complaintById(id),
        data: body,
      );
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to update complaint',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Delete a complaint (submitter-only, enforced server-side).
  Future<void> deleteComplaint(String id) async {
    try {
      await _dioClient.dio.delete(ApiConstants.complaintById(id));
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to delete complaint',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// List staff members (Admin/Dept Head) for the assignment picker.
  Future<List<UserModel>> getStaff() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.users,
        queryParameters: {'role': 'ROLE_STAFF'},
      );
      final data = response.data;
      final list = data is Map<String, dynamic>
          ? (data['users'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);
      return list
          .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch staff',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Assign a complaint to a staff member (Admin/Dept Head).
  Future<void> assignComplaint(String id, String assignedToId) async {
    try {
      await _dioClient.dio.patch(
        ApiConstants.complaintAssign(id),
        data: {'assignedToId': assignedToId},
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to assign complaint',
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
        data: {'status': newStatus, if (notes != null) 'notes': notes},
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
        data: {'rating': rating, if (comment != null) 'ratingComment': comment},
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to submit rating',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get the system-wide complaint feed (read-only) with filters + search.
  /// `scope=all` tells the backend to bypass role-scoping so every role sees
  /// every complaint. Write actions remain guarded server-side.
  Future<List<ComplaintModel>> getAllComplaints({
    String? status,
    String? departmentId,
    String? categoryId,
    String? severity,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'scope': 'all',
        'page': page,
        'size': size,
        if (status != null) 'status': status,
        if (departmentId != null) 'departmentId': departmentId,
        if (categoryId != null) 'categoryId': categoryId,
        if (severity != null) 'severity': severity,
        // Backend text search param is `q` (title/description/complaintNumber).
        if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
      };

      final response = await _dioClient.dio.get(
        ApiConstants.complaints,
        queryParameters: queryParams,
      );

      return _parseComplaintList(response.data);
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
