import 'package:dio/dio.dart';

import 'api_client.dart';

class OrdersService {
  static Future<ApiResult<Map<String, dynamic>>> fetchOrders({Map<String, dynamic>? params}) async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/orders', queryParameters: params);
      return ApiResult.fromResponse(res, (d) => d as Map<String, dynamic>);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> fetchOrder(String orderId) async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/orders/$orderId');
      return ApiResult.fromResponse(res, (d) => d as Map<String, dynamic>);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> fetchPaymentMethods() async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/payment-methods');
      return ApiResult.fromResponse(res, (d) => d as Map<String, dynamic>);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> placeOrder(Map<String, dynamic> formData) async {
    try {
      final res = await ApiClient.instance.dio.post('/mobile/checkout', data: FormData.fromMap(formData));
      return ApiResult.fromResponse(res, (d) => d as Map<String, dynamic>);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> verifyDeliveryAddress({
    required double latitude,
    required double longitude,
    String? branchId,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post(
        '/mobile/checkout/verify-delivery-address',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (branchId != null) 'branch_id': branchId,
        },
      );
      return ApiResult.fromResponse(res, (d) => d as Map<String, dynamic>);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
