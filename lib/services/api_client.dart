import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import 'auth_service.dart';

/// Holds the current session's JWT/sessionId for services that aren't
/// widgets and so can't `context.watch<AuthProvider>()` — AuthProvider
/// pushes into this on every sign-in/refresh/sign-out. A Clerk session JWT
/// is short-lived by design, so [authorized] always retries once with a
/// freshly minted token on a 401 rather than assuming the caller has a
/// recent-enough one.
class ApiSession {
  ApiSession._();
  static String? jwt;
  static String? sessionId;

  static void update({required String? jwt, required String? sessionId}) {
    ApiSession.jwt = jwt;
    ApiSession.sessionId = sessionId;
  }

  static void clear() => update(jwt: null, sessionId: null);
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around `http` for this app's own authenticated backend
/// routes (guardian linking, incident reporting). Every call attaches the
/// current Bearer JWT and, on a 401, refreshes it once via [authService]
/// and retries — callers never have to think about token expiry.
class ApiClient {
  static Future<Map<String, dynamic>> get(String path) => _send('GET', path);
  static Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  static Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);

  // A screen that fires several authorized requests at once (the guardian
  // dashboard's alerts + invites poll) can have all of them 401 together on
  // an expired token — sharing one in-flight refresh keeps that a single
  // `/auth/refresh` call instead of one per request.
  static Future<String?>? _refreshInFlight;

  static Future<String?> _refreshSharedOnce() {
    final sessionId = ApiSession.sessionId;
    if (sessionId == null) return Future.value(null);
    return _refreshInFlight ??= authService.refreshJwt(sessionId).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    var response = await _attempt(method, path, body);
    if (response.statusCode == 401 && ApiSession.sessionId != null) {
      final refreshed = await _refreshSharedOnce();
      if (refreshed != null) {
        ApiSession.jwt = refreshed;
        response = await _attempt(method, path, body);
      }
    }

    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _extractError(response));
    }
    if (response.body.isEmpty) return const {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<http.Response> _attempt(String method, String path, Map<String, dynamic>? body) {
    final uri = Uri.parse('$backendBaseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (ApiSession.jwt != null) 'Authorization': 'Bearer ${ApiSession.jwt}',
    };
    final request = switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null),
      'PATCH' => http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null),
      _ => throw ArgumentError('Unsupported method: $method'),
    };
    return request.timeout(const Duration(seconds: 20));
  }

  static String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Something went wrong (${response.statusCode}).';
    } catch (_) {
      return 'Something went wrong (${response.statusCode}).';
    }
  }
}
