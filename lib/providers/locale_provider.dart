import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prefs.dart';

/// Current language ('en' | 'es'), persisted to `bb-lang`. Provides the
/// translation lookup used across the app via `context.t(...)`.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'bb-lang';

  String _lang;

  LocaleProvider() : _lang = _initialLang();

  static String _initialLang() {
    final saved = Prefs.instance.getString(_key);
    if (saved != null && AppStrings.supported.contains(saved)) return saved;
    final system = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return AppStrings.supported.contains(system) ? system : 'en';
  }

  String get lang => _lang;
  Locale get locale => Locale(_lang);

  String t(String key, [Map<String, String>? vars]) => AppStrings.translate(_lang, key, vars);

  void setLang(String lang) {
    if (!AppStrings.supported.contains(lang) || lang == _lang) return;
    _lang = lang;
    Prefs.instance.setString(_key, lang);
    notifyListeners();
  }

  void toggle() => setLang(_lang == 'en' ? 'es' : 'en');
}

/// Convenience access to the active translator: `context.t('welcome')`.
///
/// Uses `listen: false` so it is safe to call from event handlers as well as
/// build methods. Language changes still propagate everywhere because the root
/// app widget watches [LocaleProvider] and rebuilds the whole tree.
extension AppStringsX on BuildContext {
  String t(String key, [Map<String, String>? vars]) =>
      Provider.of<LocaleProvider>(this, listen: false).t(key, vars);
}
