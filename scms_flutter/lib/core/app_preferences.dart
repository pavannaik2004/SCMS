import 'package:flutter/material.dart';

/// App-wide user preferences that affect runtime behaviour (theme + whether
/// notifications are surfaced). A lightweight [ChangeNotifier] singleton so the
/// root [MaterialApp] can rebuild on theme changes and services can consult the
/// current values without a heavier DI setup.
///
/// In-memory only — preferences reset on a cold start. Persisting them is a
/// future enhancement (would need a prefs store; none is wired today).
class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final AppPreferences instance = AppPreferences._();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
  }
}
