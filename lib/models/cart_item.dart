/// Server-priced cart line, mirrors WebsiteCartService::getCart's item shape.
class CartItem {
  final String id, productId, productVariationId;
  final String name;
  final String? image, variation;
  final num unitPrice;
  final num? unitOldPrice;
  final num lineTotal;
  final num quantity;
  final num? availableStock;
  final bool inStock;

  CartItem({
    required this.id,
    required this.productId,
    required this.productVariationId,
    required this.name,
    this.image,
    this.variation,
    required this.unitPrice,
    this.unitOldPrice,
    required this.lineTotal,
    required this.quantity,
    this.availableStock,
    this.inStock = true,
  });

  num get price => unitPrice;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: '${json['cart_item_id']}',
        productId: '${json['product_id']}',
        productVariationId: '${json['product_variation_id']}',
        name: json['name'] ?? '',
        image: json['image'],
        variation: json['variation'],
        unitPrice: json['unit_price'] ?? 0,
        unitOldPrice: json['unit_old_price'] as num?,
        lineTotal: json['line_total'] ?? 0,
        quantity: json['quantity'] ?? 1,
        availableStock: json['available_stock'] as num?,
        inStock: json['in_stock'] ?? true,
      );
}
