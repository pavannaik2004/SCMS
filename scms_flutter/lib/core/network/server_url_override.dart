import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Optional runtime override for the backend base URL (e.g.
/// `http://192.168.1.104:3000`), so testers can point the app at a different
/// server without rebuilding — `.env`'s `API_BASE_URL` is baked into the APK
/// at build time and can't otherwise be changed after install.
///
/// Persisted in secure storage; `null` means "use [ApiConstants.baseUrl]".
class ServerUrlOverride {
  ServerUrlOverride._();

  static const _storage = FlutterSecureStorage();

  static Future<String?> get() =>
      _storage.read(key: AppConstants.serverUrlOverrideKey);

  /// Saves [url] as the override, or clears it if [url] is null/blank.
  /// Adds an `http://` scheme if the user typed a bare host:port.
  static Future<void> set(String? url) async {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _storage.delete(key: AppConstants.serverUrlOverrideKey);
      return;
    }
    final normalized =
        trimmed.contains('://') ? trimmed : 'http://$trimmed';
    await _storage.write(
      key: AppConstants.serverUrlOverrideKey,
      value: normalized,
    );
  }
}
