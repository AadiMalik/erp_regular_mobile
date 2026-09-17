import 'dart:io';

import 'package:dio/dio.dart';

import '../config/env.dart';
import 'api_client.dart';

/// Customer identity/auth against the ERP's shared email+OTP API. Mirrors
/// services/auth.js 1:1 — same endpoints, same business_id-scoped body
/// (one signup per business, all branches; same email may Sign up at
/// another business).
class AuthService {
  static Future<ApiResult<dynamic>> _post(String url, Map<String, dynamic> body) async {
    try {
      final res = await ApiClient.instance.dio.post(url, data: body);
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<dynamic>> checkEmail(String email) =>
      _post('/mobile/auth/check-email', {'email': email, 'business_id': Env.businessId});

  static Future<ApiResult<dynamic>> sendOtp(String email, {String? name, String? phone, String? captchaToken}) => _post(
      '/mobile/auth/send-otp', {'email': email, 'business_id': Env.businessId, 'name': name, 'phone': phone, 'captcha_token': captchaToken});

  static Future<ApiResult<dynamic>> resendOtp(String email, {String? name, String? phone, String? captchaToken}) => _post(
      '/mobile/auth/resend-otp',
      {'email': email, 'business_id': Env.businessId, 'name': name, 'phone': phone, 'captcha_token': captchaToken});

  static Future<ApiResult<dynamic>> verifyOtp({required String email, required String code, String? name, String? phone}) =>
      _post('/mobile/auth/verify-otp', {'email': email, 'code': code, 'name': name, 'phone': phone, 'business_id': Env.businessId});

  static Future<ApiResult<dynamic>> loginWithPassword({required String email, required String password, String? captchaToken}) => _post(
      '/mobile/auth/login-password',
      {'email': email, 'password': password, 'business_id': Env.businessId, 'captcha_token': captchaToken});

  static Future<ApiResult<dynamic>> loginWithGoogle(String idToken, {bool createProfile = false}) =>
      _post('/mobile/auth/login-google', {'id_token': idToken, 'business_id': Env.businessId, 'create_profile': createProfile ? 1 : 0});

  static Future<ApiResult<dynamic>> loginWithFacebook(String accessToken, {bool createProfile = false}) =>
      _post('/mobile/auth/login-facebook', {'access_token': accessToken, 'business_id': Env.businessId, 'create_profile': createProfile ? 1 : 0});

  static Future<ApiResult<dynamic>> forgotPassword(String email) =>
      _post('/mobile/auth/forgot-password', {'email': email, 'business_id': Env.businessId});

  static Future<ApiResult<dynamic>> setPassword(String password) =>
      _post('/mobile/auth/set-password', {'password': password, 'password_confirmation': password});

  static Future<ApiResult<dynamic>> resetPassword({required String email, required String code, required String password}) =>
      _post('/mobile/auth/reset-password', {'email': email, 'code': code, 'password': password, 'password_confirmation': password});

  static Future<ApiResult<dynamic>> changePassword({required String currentPassword, required String password}) =>
      _post('/mobile/auth/change-password',
          {'current_password': currentPassword, 'password': password, 'password_confirmation': password});

  static Future<ApiResult<dynamic>> logout() => _post('/mobile/auth/logout', {});

  static Future<ApiResult<Map<String, dynamic>>> fetchProfile() async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/profile/${Env.businessId}');
      return ApiResult.fromResponse(res, (d) => d as Map<String, dynamic>);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<dynamic>> updateProfile({required String name, File? profileImage}) async {
    try {
      final form = FormData.fromMap({
        'name': name,
        if (profileImage != null)
          'profile_image': await MultipartFile.fromFile(
            profileImage.path,
            filename: profileImage.path.split(Platform.pathSeparator).last,
          ),
      });
      final res = await ApiClient.instance.dio.post('/mobile/profile/${Env.businessId}', data: form);
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
