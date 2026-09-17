import 'api_client.dart';

/// Cart-scoped voucher/coupon apply — mirrors services/vouchers.js.
class VoucherService {
  static Future<ApiResult<dynamic>> applyVoucher(String code, {String? branchId}) async {
    try {
      final res = await ApiClient.instance.dio.post('/mobile/vouchers/apply', data: {
        'voucher_code': code,
        if (branchId != null) 'branch_id': branchId,
      });
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<dynamic>> removeVoucher() async {
    try {
      final res = await ApiClient.instance.dio.delete('/mobile/vouchers');
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
