import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

/// A normalized social profile + token, used by both login and account-linking.
class SocialResult {
  final String provider; // 'google' | 'facebook'
  final String token; // Google idToken or Facebook access token
  final String name;
  final String email;
  final String? avatar;
  final Map<String, dynamic> raw;

  const SocialResult({
    required this.provider,
    required this.token,
    required this.name,
    required this.email,
    this.avatar,
    required this.raw,
  });
}

/// Thrown when the user cancels a social flow.
class SocialCancelled implements Exception {
  const SocialCancelled();
}

/// Wraps Google + Facebook native sign-in so the UI stays simple. The tokens
/// produced here are accepted by the backend `/auth/social` endpoint.
class SocialAuth {
  SocialAuth._();

  static final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: AppConfig.googleClientId.isEmpty ? null : AppConfig.googleClientId,
  );

  static Future<SocialResult> google() async {
    final account = await _google.signIn();
    if (account == null) throw const SocialCancelled();
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token. Check your OAuth client configuration.');
    }
    return SocialResult(
      provider: 'google',
      token: idToken,
      name: account.displayName ?? '',
      email: account.email,
      avatar: account.photoUrl,
      raw: {
        'sub': account.id,
        'name': account.displayName,
        'email': account.email,
        'picture': account.photoUrl,
      },
    );
  }

  static Future<SocialResult> facebook() async {
    final result = await FacebookAuth.instance.login(permissions: const ['public_profile', 'email']);
    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw const SocialCancelled();
    }
    final data = await FacebookAuth.instance.getUserData(
      fields: 'id,name,email,picture.type(large)',
    );
    final picture = (data['picture']?['data']?['url']) as String?;
    return SocialResult(
      provider: 'facebook',
      token: result.accessToken!.tokenString,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      avatar: picture,
      raw: {
        'id': data['id'],
        'name': data['name'],
        'email': data['email'] ?? '',
        'picture': picture,
      },
    );
  }

  static Future<void> signOutGoogle() => _google.signOut();
}
