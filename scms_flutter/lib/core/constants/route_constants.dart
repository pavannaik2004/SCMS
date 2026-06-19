class Routes {
  Routes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String userHome = '/home/user';
  static const String staffHome = '/home/staff';
  static const String srHome = '/home/sr';
  static const String adminHome = '/home/admin';
  static const String submitComplaint = '/complaint/submit';
  static const String complaintDetail = '/complaint/:id';
  static const String duplicateComplaints = '/complaint/:id/duplicates';
  static const String ratingPage = '/complaint/:id/rate';
  static const String srReviewDetail = '/sr/review/:id';
  static const String staffComplaintDetail = '/staff/complaint/:id';
  static const String settings = '/settings';

  // Shared cross-role screens (read-only feed, analytics, personal list).
  static const String allComplaints = '/complaints/all';
  static const String stats = '/stats';
  static const String myComplaints = '/complaints/mine';
}
