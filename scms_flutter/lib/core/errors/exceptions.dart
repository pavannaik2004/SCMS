/// Base exception for server-related errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ServerException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Exception for network connectivity issues
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception for local cache/storage errors
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error occurred'});

  @override
  String toString() => 'CacheException: $message';
}

/// Exception for authentication errors
class AuthException implements Exception {
  final String message;
  final String? errorCode;

  const AuthException({
    required this.message,
    this.errorCode,
  });

  @override
  String toString() => 'AuthException($errorCode): $message';
}

/// Exception when the user's domain is not allowed
class DomainNotAllowedException extends AuthException {
  final List<String>? allowedDomains;

  const DomainNotAllowedException({
    super.message = 'Only @rvce.edu.in accounts are permitted to use this app.',
    super.errorCode = 'DOMAIN_NOT_ALLOWED',
    this.allowedDomains,
  });
}

/// Exception when token refresh fails
class TokenExpiredException extends AuthException {
  const TokenExpiredException({
    super.message = 'Session expired. Please log in again.',
    super.errorCode = 'TOKEN_EXPIRED',
  });
}

/// Exception when user doesn't have required role
class ForbiddenException extends AuthException {
  const ForbiddenException({
    super.message = 'You do not have permission to access this resource.',
    super.errorCode = 'FORBIDDEN',
  });
}
