import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

/// Configured Dio HTTP client with auth and logging interceptors
class DioClient {
  late final Dio dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: '${ApiConstants.baseUrl}${ApiConstants.apiPrefix}',
        connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSec),
        receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSec),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage, dio),
      _LoggingInterceptor(),
    ]);
  }
}

/// Interceptor that adds Bearer token and handles 401 refresh
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._secureStorage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for google sign-in endpoint
    if (options.path.contains(ApiConstants.authGoogle)) {
      handler.next(options);
      return;
    }

    final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _secureStorage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken == null) {
          _isRefreshing = false;
          throw const TokenExpiredException();
        }

        // Attempt token refresh
        final response = await _dio.post(
          ApiConstants.authRefresh,
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200) {
          final newAccessToken = response.data['accessToken'] as String;
          await _secureStorage.write(key: AppConstants.accessTokenKey, value: newAccessToken);

          // Retry original request with new token
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(retryOptions);
          _isRefreshing = false;
          handler.resolve(retryResponse);
          return;
        }
      } catch (e) {
        _isRefreshing = false;
        // Clear tokens on refresh failure
        await _secureStorage.delete(key: AppConstants.accessTokenKey);
        await _secureStorage.delete(key: AppConstants.refreshTokenKey);
        await _secureStorage.delete(key: AppConstants.userDataKey);
        handler.reject(err);
        return;
      }
    }
    handler.next(err);
  }
}

/// Interceptor for debug-only request/response logging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.network(options.method, options.path);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.network(
      response.requestOptions.method,
      response.requestOptions.path,
      statusCode: response.statusCode,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '${err.requestOptions.method} ${err.requestOptions.path}',
      tag: 'HTTP',
      error: '${err.response?.statusCode} — ${err.message}',
    );
    handler.next(err);
  }
}
