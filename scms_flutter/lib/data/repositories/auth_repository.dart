import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  /// Sign in with Google OAuth — full flow
  Future<UserModel> signInWithGoogle(String? fcmToken) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkFailure();
    }
    try {
      final idToken = await _remoteDataSource.getGoogleIdToken();
      final response = await _remoteDataSource.signInWithGoogle(idToken, fcmToken);
      await _localDataSource.saveTokens(response.accessToken, response.refreshToken);
      await _localDataSource.saveUser(response.user);
      return response.user;
    } on DomainNotAllowedException {
      throw const DomainNotAllowedFailure();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, errorCode: e.errorCode);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  /// Fetch the seeded demo accounts for the development-login picker.
  Future<List<DevUser>> getDevUsers() => _remoteDataSource.getDevUsers();

  /// Sign in as a specific seeded demo user (development bypass).
  /// The id-based mock token lets the backend resolve the real seeded account,
  /// so [getMe] returns that user's true name/role/department.
  Future<UserModel> signInWithMock(String userId) async {
    await _localDataSource.saveTokens(
      'mock_access_token_ID_$userId',
      'mock_refresh_token_ID_$userId',
    );
    final user = await _remoteDataSource.getMe();
    await _localDataSource.saveUser(user);
    return user;
  }

  /// Offline development bypass — signs in WITHOUT contacting the backend.
  /// Mints a role-based mock token and builds a local placeholder user so a
  /// tester can enter the app (e.g. to set the Server URL in Settings) before
  /// any server is reachable. Once the URL points at a running dev backend, the
  /// `mock_..._ROLE_<ROLE>` token is accepted and auto-provisions a demo user
  /// matching this placeholder's id/email (see backend authenticate.js).
  Future<UserModel> signInWithMockOffline(String role) async {
    final suffix = role.replaceFirst('ROLE_', '');
    await _localDataSource.saveTokens(
      'mock_access_token_ROLE_$suffix',
      'mock_refresh_token_ROLE_$suffix',
    );
    final user = UserModel(
      id: 'mock_${role.toLowerCase()}',
      name: 'Demo $suffix',
      email: 'demo.${suffix.toLowerCase()}@rvce.edu.in',
      role: role,
      createdAt: DateTime.now(),
    );
    await _localDataSource.saveUser(user);
    return user;
  }

  /// Check if user is already authenticated (app start)
  Future<UserModel?> checkAuthStatus() async {
    final hasToken = await _localDataSource.hasToken();
    if (!hasToken) return null;

    if (!await _networkInfo.isConnected) {
      // Offline — return cached user
      return await _localDataSource.getUser();
    }

    try {
      final user = await _remoteDataSource.getMe();
      await _localDataSource.saveUser(user);
      return user;
    } on TokenExpiredException {
      await _localDataSource.clearAll();
      return null;
    } catch (_) {
      // Network error — return cached user
      return await _localDataSource.getUser();
    }
  }

  /// Get cached user (no network call)
  Future<UserModel?> getCachedUser() => _localDataSource.getUser();

  /// Logout — clear local state and invalidate server token
  Future<void> logout() async {
    await _remoteDataSource.logout();
    await _localDataSource.clearAll();
  }

  /// Check if onboarding has been completed
  Future<bool> isOnboardingComplete() => _localDataSource.isOnboardingComplete();

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() => _localDataSource.setOnboardingComplete();
}
