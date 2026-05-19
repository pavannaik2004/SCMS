import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';

import '../../models/user_model.dart';

/// Local data source for securely storing auth tokens and user data
class AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  AuthLocalDataSource({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ─── Tokens ───────────────────────────────────────────────

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ─── User Data ────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _secureStorage.write(key: AppConstants.userDataKey, value: jsonStr);
  }

  Future<UserModel?> getUser() async {
    try {
      final jsonStr = await _secureStorage.read(key: AppConstants.userDataKey);
      if (jsonStr == null) return null;
      return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─── Onboarding ───────────────────────────────────────────

  Future<void> setOnboardingComplete() async {
    await _secureStorage.write(key: AppConstants.onboardingCompleteKey, value: 'true');
  }

  Future<bool> isOnboardingComplete() async {
    final value = await _secureStorage.read(key: AppConstants.onboardingCompleteKey);
    return value == 'true';
  }

  // ─── Clear All ────────────────────────────────────────────

  Future<void> clearAll() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }
}
