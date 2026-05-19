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
