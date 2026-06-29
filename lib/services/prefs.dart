import 'package:shared_preferences/shared_preferences.dart';

/// Thin singleton around SharedPreferences so providers can read/write
/// synchronously after a one-time async init (mirrors browser localStorage).
class Prefs {
  Prefs._();
  static final Prefs instance = Prefs._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}
