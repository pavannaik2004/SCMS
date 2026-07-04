class AppConstants {
  AppConstants._();

  // ─── SLA Configuration ────────────────────────────────────
  /// Default SLA window in hours for each severity
  static const int slaHighHours = 4;
  static const int slaMediumHours = 24;
  static const int slaLowHours = 72;

  /// SLA progress thresholds (percentage of time remaining)
  static const double slaGreenThreshold = 0.5;   // > 50% time left
  static const double slaOrangeThreshold = 0.2;   // 20-50% time left
  // < 20% → red

  // ─── Complaint Form ───────────────────────────────────────
  static const int maxPhotos = 3;
  static const int maxPhotoSizeMB = 5;
  static const int maxVideoSizeMB = 30;
  static const int minDescriptionLength = 20;
  static const int maxDescriptionLength = 500;
  static const int minSubjectLength = 5;
  static const int maxSubjectLength = 100;

  // ─── AI Debounce ──────────────────────────────────────────
  static const int grammarDebounceMsec = 800;
  static const int searchDebounceMsec = 500;
  static const int minCharsForGrammar = 30;
  static const int minCharsForCategorize = 20;

  // ─── AI Confidence ────────────────────────────────────────
  static const double highConfidence = 0.80;
  static const double mediumConfidence = 0.60;

  // ─── Pagination ───────────────────────────────────────────
  static const int defaultPageSize = 10;
  static const int maxPageSize = 50;

  // ─── App Info ─────────────────────────────────────────────
  static const String appName = 'SCMS';
  static const String appTagline = 'Smart Campus. Faster Resolutions.';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // ─── Auth ─────────────────────────────────────────────────
  static const String allowedDomain = 'rvce.edu.in';
  static const String domainRestrictionMessage =
      'Only @rvce.edu.in accounts are permitted to use this app.';

  // ─── Timeouts ─────────────────────────────────────────────
  static const int connectTimeoutSec = 10;
  static const int receiveTimeoutSec = 30;
  static const int aiTimeoutSec = 5;

  // ─── Splash ───────────────────────────────────────────────
  static const int splashMinDurationMsec = 2000;

  // ─── Notification ─────────────────────────────────────────
  static const int notificationBannerDurationSec = 4;

  // ─── Hive Boxes ───────────────────────────────────────────
  static const String draftBoxName = 'drafts';

  // ─── Secure Storage Keys ──────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String serverUrlOverrideKey = 'server_url_override';
}
