import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Thrown for non-2xx API responses. `message` carries the backend `error`
/// string so the UI can surface it (matching the React `throw new Error(...)`).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Thin HTTP wrapper around the existing Express/Lambda backend. Endpoint paths
/// and payloads match the React contexts exactly so the backend is unchanged.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String get _base => AppConfig.apiBase;

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('$_base$path');

  dynamic _decode(http.Response res) {
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(res.body);
      } catch (_) {
        if (res.statusCode >= 400) {
          throw ApiException(res.body.isEmpty ? 'Error ${res.statusCode}' : res.body, res.statusCode);
        }
        return res.body;
      }
    }
    if (res.statusCode >= 400) {
      final msg = (data is Map && data['error'] != null) ? data['error'].toString() : 'Error ${res.statusCode}';
      throw ApiException(msg, res.statusCode);
    }
    return data;
  }

  Future<dynamic> get(String path, {String? token}) async {
    final res = await _client.get(_uri(path), headers: _headers(token));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, String? token}) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body ?? const {}),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path, {String? token}) async {
    final res = await _client.delete(_uri(path), headers: _headers(token));
    return _decode(res);
  }

  void dispose() => _client.close();
}

/// Decodes a JWT payload without verifying the signature (client-side only,
/// used to read `exp`/`sub`/`email`, mirroring AuthContext.decodeJwt).
Map<String, dynamic> decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return {};
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }
    final decoded = utf8.decode(base64.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}
