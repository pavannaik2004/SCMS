/// Base failure class for repository-level error handling
abstract class Failure {
  final String message;
  const Failure({required this.message});

  @override
  String toString() => '$runtimeType: $message';
}

/// Failure from server/API errors
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure({required super.message, this.statusCode});
}

/// Failure from network/connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection. Please check your network.'});
}

/// Failure from local cache operations
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Failed to access local storage.'});
}

/// Failure from authentication errors
class AuthFailure extends Failure {
  final String? errorCode;
  const AuthFailure({required super.message, this.errorCode});
}

/// Failure when domain is not allowed
class DomainNotAllowedFailure extends AuthFailure {
  const DomainNotAllowedFailure({
    super.message = 'Only @rvce.edu.in accounts are permitted.',
    super.errorCode = 'DOMAIN_NOT_ALLOWED',
  });
}

/// Generic unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'Something went wrong. Please try again.'});
}
