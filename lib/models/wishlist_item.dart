/// One saved wishlist entry — mirrors WishlistService::list on the ERP,
/// which nests product fields under `product` and has no price/stock (that
/// only exists on the catalog endpoints), unlike the flat Product shape.
class WishlistItem {
  final String id, productId;
  final String? productVariationId;
  final String name, slug;
  final String? brand, variationLabel;
  final List<String> images;

  const WishlistItem({
    required this.id,
    required this.productId,
    this.productVariationId,
    required this.name,
    required this.slug,
    this.brand,
    this.variationLabel,
    this.images = const [],
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    return WishlistItem(
      id: '${json['id']}',
      productId: '${json['product_id']}',
      productVariationId: json['product_variation_id']?.toString(),
      name: product['name'] ?? '',
      slug: product['slug'] ?? '',
      brand: product['brand'],
      variationLabel: product['variation_label'],
      images: (product['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String get image => images.isNotEmpty ? images.first : '';
}
