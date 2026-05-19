import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase({required AuthRepository authRepository})
      : _authRepository = authRepository;

  /// Execute Google sign-in flow
  Future<UserModel> call({String? fcmToken}) {
    return _authRepository.signInWithGoogle(fcmToken);
  }

  /// Check existing auth status on app start
  Future<UserModel?> checkAuth() {
    return _authRepository.checkAuthStatus();
  }
}
