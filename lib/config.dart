/// App-wide configuration, supplied at build time via --dart-define.
///
/// Example:
///   flutter run \
///     --dart-define=API_URL=https://api.budgetbuddy.app \
///     --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
///
/// Mirrors the React app's VITE_* environment variables so the Flutter
/// frontend stays compatible with the existing Express/Lambda backend.
class AppConfig {
  const AppConfig._();

  /// Base URL of the backend API. Empty string means same-origin (web).
  static const String apiBase = String.fromEnvironment('API_URL', defaultValue: '');

  /// Google OAuth client ID (web/iOS/Android configured separately in native).
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

  /// Facebook App ID (configured natively as well).
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID', defaultValue: '');
}
