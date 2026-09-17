import '../config/env.dart';
import '../models/home_data.dart';
import 'api_client.dart';

/// Single aggregated homepage payload — mirrors the site's own bootstrap
/// call (main.js) instead of stitching categories + products together.
class HomeService {
  static Future<ApiResult<HomeData>> fetch({String? branchId}) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/mobile/website-home/${Env.businessId}',
        queryParameters: branchId != null ? {'branch_id': branchId} : null,
      );
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) {
        return ApiResult(success: false, message: body?['Message'] ?? 'Could not load homepage.');
      }
      return ApiResult(success: true, data: HomeData.fromJson(body['Data'] as Map<String, dynamic>));
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
