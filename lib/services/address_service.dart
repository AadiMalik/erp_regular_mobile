import '../config/env.dart';
import 'api_client.dart';

/// Address book, part of the profile domain (ProfileController::storeAddress
/// / destroyAddress on the ERP).
class AddressService {
  static Future<ApiResult<dynamic>> saveAddress({
    String? id,
    String? label,
    required String fullName,
    String? phone,
    String? email,
    required String address,
    String? city,
    String? state,
    String? zip,
    String? country,
    bool isDefault = false,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post('/mobile/profile/${Env.businessId}/addresses', data: {
        if (id != null) 'id': id,
        'label': label,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
        'isDefault': isDefault,
      });
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<dynamic>> deleteAddress(String addressId) async {
    try {
      final res = await ApiClient.instance.dio.delete('/mobile/profile/${Env.businessId}/addresses/$addressId');
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
