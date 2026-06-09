import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/user_model.dart';

/// Response from the Google OAuth sign-in flow
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      isNewUser: json['isNewUser'] as bool? ?? false,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Remote data source for authentication via Google OAuth 2.0
class AuthRemoteDataSource {
  final DioClient _dioClient;
  late final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? dotenv.env['GOOGLE_SERVER_CLIENT_ID'] : null,
      serverClientId: kIsWeb ? null : dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
      hostedDomain: 'rvce.edu.in',
      scopes: ['email', 'profile'],
    );
  }

  /// Trigger Google Sign-In and return the Google ID token
  Future<String> getGoogleIdToken() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthException(message: 'Sign-in cancelled by user');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException(message: 'Failed to obtain Google ID token');
      }
      return idToken;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(message: 'Google Sign-In failed: $e');
    }
  }

  /// Exchange Google ID token for SCMS JWT
  Future<AuthResponse> signInWithGoogle(String idToken, String? fcmToken) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.authGoogle,
        data: {
          'idToken': idToken,
          'fcmToken': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data as Map<String, dynamic>);
      }

      throw ServerException(
        message: response.data?['message'] ?? 'Authentication failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final errorCode = e.response?.data?['error'] as String?;
        if (errorCode == 'DOMAIN_NOT_ALLOWED') {
          throw DomainNotAllowedException(
            allowedDomains: (e.response?.data?['allowedDomains'] as List<dynamic>?)
                ?.cast<String>(),
          );
        }
        if (errorCode == 'EMAIL_NOT_VERIFIED') {
          throw const AuthException(
            message: 'Your Google account email is not verified.',
            errorCode: 'EMAIL_NOT_VERIFIED',
          );
        }
      }
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Authentication failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get current user profile
  Future<UserModel> getMe() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.authMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const TokenExpiredException();
      }
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Failed to fetch profile',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Refresh the access token
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      return response.data['accessToken'] as String;
    } on DioException catch (e) {
      throw ServerException(
        message: 'Token refresh failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Logout — invalidate refresh token on server
  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiConstants.authLogout);
    } catch (_) {
      // Ignore logout API errors — clear local state regardless
    }
    await _googleSignIn.signOut();
  }
}
