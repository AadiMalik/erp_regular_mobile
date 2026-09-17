import '../models/cart_item.dart';
import 'api_client.dart';

String formatTaxPercent(num percent) {
  final n = percent.toDouble();
  if (n == n.roundToDouble()) return n.round().toString();
  var s = n.toStringAsFixed(4);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s.isEmpty ? '0' : s;
}

String taxLineLabel(num percent, String taxType) {
  final mode = taxType == 'inclusive' ? 'Inclusive' : 'Exclusive';
  return 'Tax (${formatTaxPercent(percent)}%) ($mode)';
}

String taxDiscountLineLabel(num percent) =>
    'Tax Discount (${formatTaxPercent(percent)}%)';

class CartTotals {
  final num subtotal, discount, voucherDiscount, tax, shipping, total;
  final num taxPercent;
  final String taxType;
  final num taxDiscount;
  final num taxDiscountPercent;
  const CartTotals({
    this.subtotal = 0,
    this.discount = 0,
    this.voucherDiscount = 0,
    this.tax = 0,
    this.shipping = 0,
    this.total = 0,
    this.taxPercent = 0,
    this.taxType = 'exclusive',
    this.taxDiscount = 0,
    this.taxDiscountPercent = 0,
  });

  factory CartTotals.fromJson(Map<String, dynamic> json) => CartTotals(
        subtotal: json['subtotal'] ?? 0,
        discount: json['discount'] ?? 0,
        voucherDiscount: json['voucher_discount'] ?? 0,
        tax: json['tax'] ?? 0,
        shipping: json['shipping'] ?? 0,
        total: json['total'] ?? 0,
        taxPercent: json['tax_percent'] ?? 0,
        taxType: json['tax_type'] ?? 'exclusive',
        taxDiscount: json['tax_discount'] ?? 0,
        taxDiscountPercent: json['tax_discount_percent'] ?? 0,
      );
}

class CartData {
  final List<CartItem> items;
  final CartTotals totals;
  final Map<String, dynamic>? voucher;
  final String? voucherError;

  const CartData({this.items = const [], this.totals = const CartTotals(), this.voucher, this.voucherError});

  num get subtotal => totals.subtotal;

  factory CartData.fromJson(Map<String, dynamic> json) => CartData(
        items: (json['items'] as List? ?? []).map((e) => CartItem.fromJson(e)).toList(),
        totals: CartTotals.fromJson(json['totals'] as Map<String, dynamic>? ?? {}),
        voucher: json['voucher'] as Map<String, dynamic>?,
        voucherError: json['voucher_error'],
      );
}

/// Authenticated, server-priced cart. Mirrors services/cart.js.
class CartService {
  static Future<ApiResult<CartData>> fetchCart({String? branchId}) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/mobile/cart',
        queryParameters: {if (branchId != null) 'branch_id': branchId},
      );
      return ApiResult.fromResponse(res, (d) => CartData.fromJson(d));
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<dynamic>> addToCart({
    required String productId,
    required String productVariationId,
    int quantity = 1,
    String? branchId,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post('/mobile/cart', data: {
        'product_id': productId,
        'product_variation_id': productVariationId,
        'quantity': quantity,
        if (branchId != null) 'branch_id': branchId,
      });
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<dynamic>> updateCartItem(String cartItemId, num quantity, {String? branchId}) async {
    try {
      final res = await ApiClient.instance.dio.put('/mobile/cart/items/$cartItemId', data: {
        'quantity': quantity,
        if (branchId != null) 'branch_id': branchId,
      });
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }

  static Future<ApiResult<dynamic>> removeCartItem(String cartItemId) async {
    try {
      final res = await ApiClient.instance.dio.delete('/mobile/cart/items/$cartItemId');
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
