import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool get isLoggedIn => _user != null;
  Map<String, dynamic>? get user => _user;

  Future<void> restore() async {
    final token = await TokenStorage.instance.read();
    if (token == null) return;
    final res = await AuthService.fetchProfile();
    if (res.success) {
      _user = res.data;
      notifyListeners();
    }
  }

  /// Returns `requiresPassword` too — true right after a fresh signup OTP
  /// verify, so the caller knows to follow up with AuthService.setPassword.
  Future<VerifyOtpOutcome> verifyOtp({required String email, required String code, String? name, String? phone}) async {
    final res = await AuthService.verifyOtp(email: email, code: code, name: name, phone: phone);
    if (res.success && res.data != null) {
      await _persistSession(res.data);
    }
    final requiresPassword = res.data is Map ? res.data['requires_password'] == true : false;
    return VerifyOtpOutcome(res.success, res.message, requiresPassword);
  }

  Future<ApiOutcome> loginWithPassword({required String email, required String password, String? captchaToken}) async {
    final res = await AuthService.loginWithPassword(email: email, password: password, captchaToken: captchaToken);
    if (res.success && res.data != null) {
      await _persistSession(res.data);
    }
    return ApiOutcome(res.success, res.message);
  }

  Future<ApiOutcome> loginWithGoogle(String idToken, {bool createProfile = false}) async {
    final res = await AuthService.loginWithGoogle(idToken, createProfile: createProfile);
    if (res.success && res.data != null) {
      await _persistSession(res.data);
    }
    return ApiOutcome(res.success, res.message);
  }

  Future<ApiOutcome> loginWithFacebook(String accessToken, {bool createProfile = false}) async {
    final res = await AuthService.loginWithFacebook(accessToken, createProfile: createProfile);
    if (res.success && res.data != null) {
      await _persistSession(res.data);
    }
    return ApiOutcome(res.success, res.message);
  }

  Future<void> _persistSession(dynamic data) async {
    final token = data is Map ? data['token'] as String? : null;
    final user = data is Map ? data['user'] as Map<String, dynamic>? : null;
    if (token != null) {
      await TokenStorage.instance.write(token);
    }
    _user = user;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final res = await AuthService.fetchProfile();
    if (res.success) {
      _user = res.data;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    await TokenStorage.instance.clear();
    _user = null;
    notifyListeners();
  }

  /// Called from ApiClient's 401 interceptor after the token is cleared.
  /// Drops in-memory session so the UI stops rendering as logged-in.
  void handleSessionExpired() {
    if (_user == null) return;
    _user = null;
    notifyListeners();
  }
}

class ApiOutcome {
  final bool success;
  final String? message;
  ApiOutcome(this.success, this.message);
}

class VerifyOtpOutcome extends ApiOutcome {
  final bool requiresPassword;
  VerifyOtpOutcome(super.success, super.message, this.requiresPassword);
}
