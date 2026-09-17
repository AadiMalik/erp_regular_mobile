class ProductCategory {
  final String id, name, slug;
  final String? image;

  ProductCategory({required this.id, required this.name, required this.slug, this.image});

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        id: '${json['id']}',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        image: json['image'],
      );
}
