import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'token_storage.dart';

/// Shared HTTP client for every service, mirrors the Vue site's
/// services/http.js: same base URL, attaches the customer's bearer
/// token on every request, clears it on a 401 and notifies listeners so
/// AuthProvider can drop in-memory session state and route to login.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Fired after the persisted token is cleared on a 401. Wired once from
  /// app startup (see main.dart) to AuthProvider + WishlistProvider + nav.
  VoidCallback? onSessionExpired;

  late final Dio dio = Dio(
    BaseOptions(baseUrl: Env.apiBaseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 15)),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.read();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/mobile/auth/logout')) {
            final hadToken = await TokenStorage.instance.read() != null;
            await TokenStorage.instance.clear();
            if (hadToken) {
              onSessionExpired?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
}

/// Envelope every ERP endpoint returns: {Success, Message, Data}.
class ApiResult<T> {
  final bool success;
  final String? message;
  final T? data;
  const ApiResult({required this.success, this.message, this.data});

  factory ApiResult.fromResponse(Response res, T Function(dynamic) mapData) {
    final body = res.data;
    return ApiResult(
      success: body?['Success'] == true,
      message: body?['Message'],
      data: body?['Data'] != null ? mapData(body['Data']) : null,
    );
  }

  factory ApiResult.failure(Object err) {
    String? msg;
    if (err is DioException) {
      msg = err.response?.data is Map ? err.response?.data['Message'] : null;
    }
    return ApiResult(success: false, message: msg ?? 'Something went wrong. Please try again.');
  }
}
