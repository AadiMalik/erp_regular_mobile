import '../config/env.dart';
import '../models/wishlist_item.dart';
import 'api_client.dart';

class WishlistService {
  static Future<ApiResult<Map<String, dynamic>>> fetchWishlist() async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/wishlist/${Env.businessId}');
      return ApiResult.fromResponse(res, (d) => d as Map<String, dynamic>);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<List<WishlistItem>> fetchWishlistItems() async {
    final res = await fetchWishlist();
    final items = res.data?['items'] as List? ?? [];
    return items.map((e) => WishlistItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Product ids currently in the wishlist — used to show the right heart
  /// state on load instead of always starting unfilled. Each row's own `id`
  /// is the wishlist entry id, not the product id — the real product id is
  /// nested at `product_id`.
  static Future<Set<String>> fetchWishlistedProductIds() async {
    final res = await fetchWishlist();
    final items = res.data?['items'] as List? ?? [];
    return items.map((e) => '${(e as Map)['product_id']}').toSet();
  }

  static Future<ApiResult<dynamic>> toggleWishlist({required String productId, String? productVariationId}) async {
    try {
      final res = await ApiClient.instance.dio.post('/mobile/wishlist/${Env.businessId}/toggle', data: {
        'product_id': productId,
        if (productVariationId != null) 'product_variation_id': productVariationId,
      });
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
