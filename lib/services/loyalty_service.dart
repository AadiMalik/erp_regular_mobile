import '../config/env.dart';
import 'api_client.dart';

/// Customer's Loyalty Points balance for this business.
/// enabled=false means the program isn't active for this business —
/// available/reserved/redemptionValue are null and the UI must hide loyalty
/// elements entirely rather than show empty/zero balances.
class LoyaltyBalance {
  final bool enabled;
  final num? available, reserved, redemptionValue;

  const LoyaltyBalance({required this.enabled, this.available, this.reserved, this.redemptionValue});

  factory LoyaltyBalance.fromJson(Map<String, dynamic> json) => LoyaltyBalance(
        enabled: json['enabled'] == true,
        available: json['available'] as num?,
        reserved: json['reserved'] as num?,
        redemptionValue: json['redemptionValue'] as num?,
      );

  static const disabled = LoyaltyBalance(enabled: false);
}

class LoyaltyService {
  static Future<ApiResult<LoyaltyBalance>> fetchBalance() async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/loyalty/${Env.businessId}');
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) {
        return ApiResult(success: false, message: body?['Message'] ?? 'Could not load loyalty points.');
      }
      return ApiResult(success: true, data: LoyaltyBalance.fromJson(body['Data']));
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
