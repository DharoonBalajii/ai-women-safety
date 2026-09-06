import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  AppUser? _user;
  String? _jwt;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get jwt => _jwt;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  Future<void> restoreSession() async {
    final result = await authService.restoreSession();
    if (result == null) {
      _status = AuthStatus.signedOut;
      ApiSession.clear();
    } else {
      _user = result.user;
      _jwt = result.jwt;
      _status = AuthStatus.signedIn;
      ApiSession.update(jwt: result.jwt, sessionId: result.sessionId);
    }
    notifyListeners();
  }

  Future<SendOtpResult> sendOtp({required String phoneNumber, required UserRole role}) {
    return authService.sendOtp(phoneNumber: phoneNumber, role: role);
  }

  Future<void> verifyOtp({required String phoneNumber, required UserRole role, required String code}) async {
    final result = await authService.verifyOtp(phoneNumber: phoneNumber, role: role, code: code);
    _user = result.user;
    _jwt = result.jwt;
    _status = AuthStatus.signedIn;
    ApiSession.update(jwt: result.jwt, sessionId: result.sessionId);
    notifyListeners();
  }

  /// Demo-only bypass: enters the app as a local, backend-less session so
  /// the app can be shown without depending on the auth backend being up.
  /// No ApiSession jwt/sessionId is set, so every authenticated backend
  /// call (guardian linking, incident sync) just fails silently/best-effort
  /// exactly as it already does when the server is unreachable — nothing
  /// else in the app assumes a real session exists.
  void skipSignIn(UserRole role) {
    _user = AppUser(id: 'demo-user', phoneNumber: 'Demo mode', role: role);
    _jwt = null;
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> signOut() async {
    await authService.signOut();
    _user = null;
    _jwt = null;
    _status = AuthStatus.signedOut;
    ApiSession.clear();
    notifyListeners();
  }
}
