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
