import 'package:flutter/material.dart';

import '../services/prefs.dart';

/// Light/dark theme state, persisted to `bb-theme` (matches ThemeContext).
class ThemeProvider extends ChangeNotifier {
  static const _key = 'bb-theme';

  ThemeMode _mode;

  ThemeProvider({required Brightness platformBrightness})
      : _mode = _initialMode(platformBrightness);

  static ThemeMode _initialMode(Brightness platformBrightness) {
    final saved = Prefs.instance.getString(_key);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    Prefs.instance.setString(_key, isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
