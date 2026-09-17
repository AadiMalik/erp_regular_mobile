/// Flat shape returned by /mobile/products/{business} listing/sections and
/// detail endpoints (ProductService::mapProductSummary /
/// getWebsiteDetail on the ERP) — same shape everywhere, listing vs detail
/// only adds a few extra fields.
class ProductFeature {
  final String name;
  final String? description;
  const ProductFeature({required this.name, this.description});

  factory ProductFeature.fromJson(Map<String, dynamic> json) =>
      ProductFeature(name: json['name'] ?? '', description: json['description']);
}

class VariationOption {
  final String id, label;
  final num price;
  final num? oldPrice;
  final num discount;
  final num? stock;
  final List<Map<String, String>> attributes;
  final bool loyaltyEligible;

  const VariationOption({
    required this.id,
    required this.label,
    required this.price,
    this.oldPrice,
    this.discount = 0,
    this.stock,
    this.attributes = const [],
    this.loyaltyEligible = false,
  });

  factory VariationOption.fromJson(Map<String, dynamic> json) => VariationOption(
        id: '${json['id']}',
        label: json['label'] ?? '',
        price: json['price'] ?? 0,
        oldPrice: json['oldPrice'],
        discount: json['discount'] ?? 0,
        stock: json['stock'] as num?,
        attributes: (json['attributes'] as List? ?? [])
            .map((a) => {'name': '${a['name'] ?? ''}', 'value': '${a['value'] ?? ''}'})
            .toList(),
        loyaltyEligible: json['loyaltyEligible'] == true,
      );

  bool get isOutOfStock => stock != null && stock! <= 0;
}

class Product {
  final String id, name, slug;
  final String? brand, shortDescription, description, defaultVariationId;
  final num price;
  final num? oldPrice, stock;
  final List<String> images;
  final List<ProductFeature> features;
  final List<VariationOption> variations;
  final bool isSingleVariation;
  final bool loyaltyEligible;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.brand,
    this.shortDescription,
    this.description,
    this.defaultVariationId,
    required this.price,
    this.oldPrice,
    this.stock,
    required this.images,
    this.features = const [],
    this.variations = const [],
    this.isSingleVariation = true,
    this.loyaltyEligible = false,
  });

  // stock is nullable when the product doesn't track stock at all (always
  // orderable); only a non-null, non-positive value means out of stock.
  bool get isOutOfStock => stock != null && stock! <= 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    final variationsBlock = json['variations'] as Map<String, dynamic>?;
    return Product(
      id: '${json['id']}',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      brand: json['brand']?.toString(),
      shortDescription: json['short_description'],
      description: json['description'],
      defaultVariationId: json['default_variation_id']?.toString(),
      price: json['price'] ?? 0,
      oldPrice: json['oldPrice'] as num?,
      stock: json['stock'] as num?,
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      features: (json['features'] as List? ?? []).map((e) => ProductFeature.fromJson(e as Map<String, dynamic>)).toList(),
      variations: (variationsBlock?['options'] as List? ?? []).map((e) => VariationOption.fromJson(e as Map<String, dynamic>)).toList(),
      isSingleVariation: json['is_single_variation'] ?? true,
      loyaltyEligible: json['loyaltyEligible'] == true,
    );
  }

  String get image => images.isNotEmpty ? images.first : '';
}

/// One warehouse's contribution to a variation's combined branch stock -
/// mirrors ProductVariationStockService::getStockBreakdownForBranch() on the
/// ERP. `batches` is only non-empty for a batch/expiry-tracked variation.
class StockBatch {
  final String? batchNo;
  final num quantity;
  final String? expiryDate;
  const StockBatch({this.batchNo, required this.quantity, this.expiryDate});

  factory StockBatch.fromJson(Map<String, dynamic> json) => StockBatch(
        batchNo: json['batch_no']?.toString(),
        quantity: json['quantity'] ?? 0,
        expiryDate: json['expiry_date']?.toString(),
      );
}

class StockBreakdownRow {
  final String warehouseId, warehouseName;
  final num quantity;
  final List<StockBatch> batches;
  const StockBreakdownRow({
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
    this.batches = const [],
  });

  factory StockBreakdownRow.fromJson(Map<String, dynamic> json) => StockBreakdownRow(
        warehouseId: '${json['warehouse_id']}',
        warehouseName: json['warehouse_name'] ?? '',
        quantity: json['quantity'] ?? 0,
        batches: (json['batches'] as List? ?? [])
            .map((e) => StockBatch.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
