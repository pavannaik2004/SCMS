import '../../../data/models/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {
  final bool showOnboarding;
  AuthUnauthenticated({this.showOnboarding = false});
}

class AuthFailure extends AuthState {
  final String message;
  final String? errorCode;
  AuthFailure({required this.message, this.errorCode});
}
