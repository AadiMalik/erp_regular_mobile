import '../models/product.dart';
import 'api_client.dart';

class ProductSections {
  final List<Product> featured, discounted, trending, newArrivals, bestSellers;
  const ProductSections({
    this.featured = const [],
    this.discounted = const [],
    this.trending = const [],
    this.newArrivals = const [],
    this.bestSellers = const [],
  });
}

class ProductsPage {
  final List<Product> items;
  final ProductSections? sections;
  const ProductsPage({required this.items, this.sections});
}

class ProductsService {
  static List<Product> _list(dynamic raw) =>
      (raw as List? ?? []).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();

  static Future<ApiResult<ProductsPage>> fetchProducts({Map<String, dynamic>? params}) async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/products', queryParameters: params);
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) {
        return ApiResult(success: false, message: body?['Message'] ?? 'Could not load products.', data: const ProductsPage(items: []));
      }

      final data = body['Data'] as Map<String, dynamic>;
      final items = _list(data['products']?['data']);
      final s = data['sections'] as Map<String, dynamic>?;
      final sections = s == null
          ? null
          : ProductSections(
              featured: _list(s['featured_products']),
              discounted: _list(s['discounted_products']),
              trending: _list(s['trending_products']),
              newArrivals: _list(s['new_arrivals']),
              bestSellers: _list(s['best_sellers']),
            );
      return ApiResult(success: true, data: ProductsPage(items: items, sections: sections));
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<Product>> fetchProductBySlug(String slug, {String? branchId}) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/mobile/products/$slug',
        queryParameters: branchId != null ? {'branch_id': branchId} : null,
      );
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) {
        return ApiResult(success: false, message: body?['Message'] ?? 'Product not found.');
      }
      return ApiResult(success: true, data: Product.fromJson(body['Data']));
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Per-warehouse (and, for batch-tracked variations, per-batch) stock
  /// detail for the current branch - loaded on demand only when the shopper
  /// opens it. Returns [] on any failure/missing branch so the UI can just
  /// render "no detail available" rather than throwing.
  static Future<List<StockBreakdownRow>> fetchStockBreakdown(String variationId, String? branchId) async {
    if (branchId == null || branchId.isEmpty) return const [];
    try {
      final res = await ApiClient.instance.dio.get(
        '/mobile/products/stock/$variationId',
        queryParameters: {'branch_id': branchId},
      );
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) return const [];
      return (body['Data'] as List)
          .map((e) => StockBreakdownRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Fire-and-forget share analytics - never blocks or breaks the share
  /// action itself if it fails (offline, expired token, etc.).
  static Future<void> recordShare(String productId, String platform) async {
    try {
      await ApiClient.instance.dio.post('/mobile/products/$productId/share', data: {'platform': platform});
    } catch (_) {
      // best-effort only
    }
  }
}
