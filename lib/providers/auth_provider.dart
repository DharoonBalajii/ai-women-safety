import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
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
    } else {
      _user = result.user;
      _jwt = result.jwt;
      _status = AuthStatus.signedIn;
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
    notifyListeners();
  }

  Future<void> signOut() async {
    await authService.signOut();
    _user = null;
    _jwt = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
