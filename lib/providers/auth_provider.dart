import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/prefs.dart';

/// Result of a sign-in attempt. When [mfaRequired] is true the UI should route
/// to the 2FA screen; the Cognito challenge session is stashed for confirmMFA.
class SignInResult {
  final bool mfaRequired;
  const SignInResult({required this.mfaRequired});
}

/// Authentication state + flows, ported from AuthContext.jsx. Talks to the same
/// `/auth/*` endpoints and persists the session to `bb-session`.
class AuthProvider extends ChangeNotifier {
  static const _sessionKey = 'bb-session';
  static const _mfaSessionKey = 'bb-mfa-session';
  static const _mfaEmailKey = 'bb-mfa-email';

  final ApiClient _api;

  UserModel? _user;
  bool _loading = true;

  AuthProvider({required ApiClient api}) : _api = api {
    _restore();
  }

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  String? get token => _user?.accessToken;

  void _restore() {
    final raw = Prefs.instance.getString(_sessionKey);
    if (raw != null) {
      try {
        final parsed = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        final at = parsed.accessToken;
        if (at != null && at.isNotEmpty) {
          final exp = decodeJwt(at)['exp'];
          if (exp is num && DateTime.now().millisecondsSinceEpoch / 1000 > exp) {
            Prefs.instance.remove(_sessionKey);
          } else {
            _user = parsed;
          }
        } else {
          _user = parsed;
        }
      } catch (_) {
        // Corrupt session — ignore and start logged out.
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _persist(UserModel u) async {
    _user = u;
    await Prefs.instance.setString(_sessionKey, jsonEncode(u.toJson()));
    notifyListeners();
  }

  // ── Email / password ───────────────────────────────────────────────────────
  Future<SignInResult> signIn(String email, String password) async {
    final data = await _api.post('/auth/login', body: {'email': email, 'password': password});

    if (data is Map && data['challenge'] != null) {
      await Prefs.instance.setString(_mfaSessionKey, data['session'].toString());
      await Prefs.instance.setString(_mfaEmailKey, email);
      return const SignInResult(mfaRequired: true);
    }

    final map = (data as Map).cast<String, dynamic>();
    final payload = decodeJwt((map['idToken'] ?? map['accessToken']).toString());
    await _persist(UserModel(
      userId: (payload['sub'] ?? email).toString(),
      email: (payload['email'] ?? email).toString(),
      name: (payload['name'] ?? email.split('@').first).toString(),
      accessToken: map['accessToken'] as String?,
      refreshToken: map['refreshToken'] as String?,
      providers: _user?.providers ?? const {},
    ));
    return const SignInResult(mfaRequired: false);
  }

  // ── Social ─────────────────────────────────────────────────────────────────
  Future<void> signInWithGoogle(String token, Map<String, dynamic> profile) async {
    final data = (await _api.post('/auth/social', body: {'provider': 'google', 'token': token})) as Map;
    final map = data.cast<String, dynamic>();
    await _persist(UserModel(
      userId: (map['userId'] ?? profile['sub'] ?? profile['id'] ?? '').toString(),
      email: (profile['email'] ?? '').toString(),
      name: (profile['name'] ?? '').toString(),
      avatar: profile['picture'] as String?,
      accessToken: map['accessToken'] as String?,
      refreshToken: map['refreshToken'] as String?,
      providers: {
        ...(_user?.providers ?? const {}),
        'google': {'email': profile['email'], 'name': profile['name'], 'picture': profile['picture']},
      },
    ));
  }

  Future<void> signInWithFacebook(String accessToken, Map<String, dynamic> profile) async {
    final data = (await _api.post('/auth/social', body: {'provider': 'facebook', 'token': accessToken})) as Map;
    final map = data.cast<String, dynamic>();
    await _persist(UserModel(
      userId: (map['userId'] ?? 'fb-${profile['id']}').toString(),
      email: (profile['email'] ?? '').toString(),
      name: (profile['name'] ?? '').toString(),
      avatar: profile['picture'] as String?,
      accessToken: map['accessToken'] as String?,
      refreshToken: map['refreshToken'] as String?,
      providers: {
        ...(_user?.providers ?? const {}),
        'facebook': {'id': profile['id'], 'email': profile['email'], 'picture': profile['picture']},
      },
    ));
  }

  // ── Link / unlink social to an existing account ────────────────────────────
  Future<void> linkGoogle(Map<String, dynamic> p) async {
    if (_user == null) return;
    await _persist(_user!.copyWith(providers: {
      ...(_user!.providers),
      'google': {'sub': p['sub'], 'email': p['email'], 'name': p['name'], 'picture': p['picture']},
    }));
  }

  Future<void> linkFacebook(Map<String, dynamic> p) async {
    if (_user == null) return;
    await _persist(_user!.copyWith(providers: {
      ...(_user!.providers),
      'facebook': {'id': p['id'], 'email': p['email'] ?? '', 'name': p['name'], 'picture': p['picture']},
    }));
  }

  Future<void> unlinkProvider(String provider) async {
    if (_user == null) return;
    final providers = Map<String, dynamic>.from(_user!.providers)..remove(provider);
    await _persist(_user!.copyWith(providers: providers));
  }

  Future<void> updateProfile({String? name, String? email, String? avatar}) async {
    if (_user == null) return;
    await _persist(_user!.copyWith(name: name, email: email, avatar: avatar));
  }

  // ── MFA (Cognito TOTP) ─────────────────────────────────────────────────────
  Future<bool> confirmMFA(String code) async {
    final email = Prefs.instance.getString(_mfaEmailKey);
    final session = Prefs.instance.getString(_mfaSessionKey);
    if (session != null && email != null) {
      final data = (await _api.post('/auth/login/mfa',
          body: {'email': email, 'totpCode': code, 'session': session})) as Map;
      final map = data.cast<String, dynamic>();
      final payload = decodeJwt((map['idToken'] ?? map['accessToken']).toString());
      await _persist(UserModel(
        userId: (payload['sub'] ?? _user?.userId ?? '').toString(),
        email: (payload['email'] ?? _user?.email ?? email).toString(),
        name: _user?.name ?? (payload['email']?.toString().split('@').first ?? ''),
        avatar: _user?.avatar,
        accessToken: map['accessToken'] as String?,
        refreshToken: map['refreshToken'] as String?,
        providers: _user?.providers ?? const {},
      ));
      await Prefs.instance.remove(_mfaSessionKey);
      await Prefs.instance.remove(_mfaEmailKey);
      return true;
    }
    // Fallback: email OTP flow already verified server-side.
    if (code.length == 6 && _user != null) {
      await _persist(_user!);
      return true;
    }
    throw const ApiException('Invalid code');
  }

  Future<void> signUp(String email, String password) async {
    await _api.post('/auth/register', body: {'email': email, 'password': password});
  }

  Future<void> signOut() async {
    final at = _user?.accessToken;
    if (at != null) {
      try {
        await _api.post('/auth/logout', token: at);
      } catch (_) {
        // Clear local session regardless of network outcome.
      }
    }
    _user = null;
    await Prefs.instance.remove(_sessionKey);
    notifyListeners();
  }
}
