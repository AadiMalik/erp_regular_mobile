import '../config/env.dart';
import '../models/category.dart';
import 'api_client.dart';

class CategoriesService {
  static Future<ApiResult<List<ProductCategory>>> fetchCategories() async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/categories/${Env.businessId}');
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] is! List) {
        return ApiResult(success: false, message: body?['Message'] ?? 'Could not load categories.', data: const []);
      }
      final list = (body['Data'] as List).map((e) => ProductCategory.fromJson(e)).toList();
      return ApiResult(success: true, data: list);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
