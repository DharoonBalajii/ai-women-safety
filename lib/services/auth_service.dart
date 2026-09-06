import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

class SendOtpResult {
  final bool mock;
  const SendOtpResult({required this.mock});
}

class VerifyOtpResult {
  final String sessionId;
  final String jwt;
  final AppUser user;
  const VerifyOtpResult({required this.sessionId, required this.jwt, required this.user});
}

enum _RefreshOutcome { success, revoked, unreachable }

/// Distinguishes "this session no longer exists" (the server said so
/// definitively — sign the person out) from "couldn't tell right now" (a
/// timeout, a 5xx, no network — assume the session is still fine and let
/// the next real request surface anything genuinely wrong). Conflating
/// these left a revoked session looking permanently "signed in" while every
/// API call quietly 401'd forever.
class _RefreshResult {
  final _RefreshOutcome outcome;
  final String? jwt;
  const _RefreshResult._(this.outcome, this.jwt);
  const _RefreshResult.success(String jwt) : this._(_RefreshOutcome.success, jwt);
  const _RefreshResult.revoked() : this._(_RefreshOutcome.revoked, null);
  const _RefreshResult.unreachable() : this._(_RefreshOutcome.unreachable, null);
}

/// Thin client for this app's own backend `/auth/*` routes — the phone/OTP
/// sign-in flow backed by MSG91 + Clerk on the server. The session (a
/// Clerk sign-in-token-derived id, functioning like a refresh token) is
/// the only credential this app ever holds; it's kept in the platform
/// keystore/keychain via [FlutterSecureStorage], never SharedPreferences.
class AuthService {
  static const _sessionIdKey = 'auth_session_id';
  static const _jwtKey = 'auth_jwt';
  static const _userKey = 'auth_user';

  final _storage = const FlutterSecureStorage();

  Future<SendOtpResult> sendOtp({required String phoneNumber, required UserRole role}) async {
    final response = await http
        .post(
          Uri.parse('$backendBaseUrl/auth/send-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phoneNumber': phoneNumber, 'role': role.apiValue}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw AuthException(_extractError(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return SendOtpResult(mock: body['mock'] as bool? ?? false);
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phoneNumber,
    required UserRole role,
    required String code,
  }) async {
    final response = await http
        .post(
          Uri.parse('$backendBaseUrl/auth/verify-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phoneNumber': phoneNumber, 'role': role.apiValue, 'code': code}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw AuthException(_extractError(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = VerifyOtpResult(
      sessionId: body['sessionId'] as String,
      jwt: body['jwt'] as String,
      user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
    );
    await _persistSession(result);
    return result;
  }

  Future<void> signOut() async {
    final sessionId = await _storage.read(key: _sessionIdKey);
    if (sessionId != null) {
      try {
        await http
            .post(
              Uri.parse('$backendBaseUrl/auth/sign-out'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'sessionId': sessionId}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Best-effort revoke — clear the local session regardless so the
        // person is signed out of this device even if the request failed.
      }
    }
    await _clearStorage();
  }

  /// Loads a persisted session and confirms it's still valid by refreshing
  /// its JWT. Returns null if there's no stored session, or the server has
  /// definitively revoked/expired it — the caller (AuthProvider) treats
  /// that as signed-out. A merely unreachable server does NOT sign the
  /// person out; it keeps the stale session and lets the next real API
  /// call surface anything actually wrong.
  Future<VerifyOtpResult?> restoreSession() async {
    final sessionId = await _storage.read(key: _sessionIdKey);
    final userJson = await _storage.read(key: _userKey);
    if (sessionId == null || userJson == null) return null;

    final result = await _refresh(sessionId);
    final user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

    switch (result.outcome) {
      case _RefreshOutcome.success:
        return VerifyOtpResult(sessionId: sessionId, jwt: result.jwt!, user: user);
      case _RefreshOutcome.revoked:
        await _clearStorage();
        return null;
      case _RefreshOutcome.unreachable:
        final staleJwt = await _storage.read(key: _jwtKey) ?? '';
        return VerifyOtpResult(sessionId: sessionId, jwt: staleJwt, user: user);
    }
  }

  /// Mints a fresh JWT for an existing session — Clerk's session tokens are
  /// short-lived by design, so any long-running screen (e.g. the guardian
  /// dashboard's polling loop) must call this periodically rather than
  /// reusing the token from sign-in. Returns null on any failure (revoked
  /// or unreachable) so callers can fall back gracefully; callers that need
  /// to tell those apart (i.e. [restoreSession]) use [_refresh] directly.
  Future<String?> refreshJwt(String sessionId) async {
    final result = await _refresh(sessionId);
    return result.jwt;
  }

  Future<_RefreshResult> _refresh(String sessionId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$backendBaseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'sessionId': sessionId}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jwt = (jsonDecode(response.body) as Map<String, dynamic>)['jwt'] as String;
        await _storage.write(key: _jwtKey, value: jwt);
        return _RefreshResult.success(jwt);
      }
      if (response.statusCode == 401) {
        return const _RefreshResult.revoked();
      }
      // An unexpected server error (5xx, rate-limited, etc.) says nothing
      // definitive about the session itself.
      return const _RefreshResult.unreachable();
    } catch (_) {
      return const _RefreshResult.unreachable();
    }
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: _sessionIdKey);
    await _storage.delete(key: _jwtKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> _persistSession(VerifyOtpResult result) async {
    await _storage.write(key: _sessionIdKey, value: result.sessionId);
    await _storage.write(key: _jwtKey, value: result.jwt);
    await _storage.write(key: _userKey, value: jsonEncode(result.user.toJson()));
  }

  String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Something went wrong (${response.statusCode}).';
    } catch (_) {
      return 'Something went wrong (${response.statusCode}).';
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

final authService = AuthService();
