import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  /// Base URL loaded from .env
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

  /// API prefix
  static const String apiPrefix = '/api';

  // ─── Auth Endpoints ───────────────────────────────────────
  static const String authGoogle = '/auth/google';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';
  static const String authAllowedDomains = '/auth/allowed-domains';

  // ─── Complaint Endpoints ──────────────────────────────────
  static const String complaints = '/complaints';
  static const String myComplaints = '/complaints/my';
  static const String complaintAiPreview = '/complaints/ai-preview';

  static String complaintById(String id) => '/complaints/$id';
  static String complaintStatus(String id) => '/complaints/$id/status';
  static String complaintRating(String id) => '/complaints/$id/rating';
  static String complaintAssign(String id) => '/complaints/$id/assign';

  // ─── SR Endpoints ─────────────────────────────────────────
  static const String srPendingReviews = '/sr/pending';
  static String srApprove(String id) => '/sr/$id/approve';
  static String srReject(String id) => '/sr/$id/reject';

  // ─── AI Endpoints ─────────────────────────────────────────
  static const String aiGrammarCheck = '/ai/grammar-check';
  static const String aiCategorize = '/ai/categorize';
  static const String aiCheckDuplicate = '/ai/check-duplicate';

  // ─── Department & Category ────────────────────────────────
  static const String departments = '/departments';
  static const String categories = '/categories';
  static const String tags = '/tags';
  static const String zones = '/zones';

  // ─── Analytics ────────────────────────────────────────────
  static const String analyticsSummary = '/analytics/summary';
  static const String analyticsByDepartment = '/analytics/by-department';
  static const String analyticsByCategory = '/analytics/by-category';
  static const String analyticsSlaBreaches = '/analytics/sla-breaches';

  // ─── Users ────────────────────────────────────────────────
  static const String users = '/users';
  static const String userFcmToken = '/users/fcm-token';

  /// Build full URL for an endpoint
  static String fullUrl(String endpoint) => '$baseUrl$apiPrefix$endpoint';
}
