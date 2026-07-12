abstract class AuthEvent {}

/// Fired on app startup to check existing auth status
class AppStarted extends AuthEvent {}

/// Fired when user taps "Sign in with Google"
class GoogleSignInRequested extends AuthEvent {
  final String? fcmToken;
  GoogleSignInRequested({this.fcmToken});
}

/// Fired when user requests logout
class LogoutRequested extends AuthEvent {}

/// Fired when token refresh is needed
class TokenRefreshRequested extends AuthEvent {}

/// Fired when developer requests a mock sign-in (bypass mode) as a specific
/// seeded demo user.
class MockSignInRequested extends AuthEvent {
  final String userId;
  MockSignInRequested({required this.userId});
}

/// Fired for the offline development bypass: enters the app as a generic user
/// of [role] WITHOUT contacting the backend (no picker, no token exchange), so
/// a tester can reach Settings to set the server URL before any server is up.
class OfflineMockSignInRequested extends AuthEvent {
  final String role; // ROLE_USER | ROLE_SR | ROLE_STAFF | ROLE_ADMIN
  OfflineMockSignInRequested({required this.role});
}
