import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart' as failures;
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.checkAuthStatus();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        final showOnboarding = !await _authRepository.isOnboardingComplete();
        emit(AuthUnauthenticated(showOnboarding: showOnboarding));
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle(event.fcmToken);
      await _authRepository.setOnboardingComplete();
      emit(AuthAuthenticated(user: user));
    } on failures.DomainNotAllowedFailure {
      emit(AuthFailure(
        message: 'Only @rvce.edu.in accounts are permitted.',
        errorCode: 'DOMAIN_NOT_ALLOWED',
      ));
    } on failures.NetworkFailure {
      emit(AuthFailure(message: 'No internet connection. Please try again.'));
    } on failures.Failure catch (e) {
      emit(AuthFailure(message: e.message));
    } catch (e) {
      emit(AuthFailure(message: 'Sign-in failed. Please try again.'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
