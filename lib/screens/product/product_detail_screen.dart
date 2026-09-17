import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/branch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/products_service.dart';
import '../../services/reviews_service.dart';
import '../../theme/theme_x.dart';
import '../../widgets/reviews_section.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/wishlist_toggle.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/share_sheet.dart';

class ProductDetailScreen extends StatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  VariationOption? _selectedVariation;
  int _quantity = 1;
  int _imageIndex = 0;
  double _avgRating = 0;
  int _reviewCount = 0;
  bool _addingToCart = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final branchId = context.read<BranchProvider>().selectedId;
    final res = await ProductsService.fetchProductBySlug(widget.slug, branchId: branchId);
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Product not found.';
        _product = null;
      });
      return;
    }
    final p = res.data!;
    setState(() {
      _loading = false;
      _product = p;
      _selectedVariation = p.variations.isEmpty
          ? null
          : p.variations.firstWhere((v) => v.id == p.defaultVariationId, orElse: () => p.variations.first);
    });
    ReviewsService.fetchReviews(p.id).then((s) {
      if (!mounted) return;
      setState(() {
        _avgRating = s.average;
        _reviewCount = s.count;
      });
    });
  }

  void _selectVariation(VariationOption v) {
    setState(() {
      _selectedVariation = v;
    });
  }

  num get _price => _selectedVariation?.price ?? _product?.price ?? 0;
  num? get _oldPrice => _selectedVariation?.oldPrice ?? _product?.oldPrice;
  num? get _currentStock => _selectedVariation?.stock ?? _product?.stock;
  bool get _outOfStock => _selectedVariation?.isOutOfStock ?? _product?.isOutOfStock ?? false;
  String? get _variationId => _selectedVariation?.id ?? _product?.defaultVariationId;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = t.colors;
    final money = context.watch<SettingsProvider>().money;
    final product = _product;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: EmptyStateView(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load product',
            text: _error ?? 'Product not found.',
            ctaLabel: 'Try Again',
            onCta: _load,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showShareSheet(
              context,
              productId: product.id,
              name: product.name,
              image: product.image,
              slug: product.slug,
              price: _price,
              oldPrice: _oldPrice,
              description: product.shortDescription ?? product.description,
            ),
          ),
          Builder(
            builder: (context) {
              final wished = context.watch<WishlistProvider>().isWishlisted(product.id);
              return IconButton(
                icon: Icon(wished ? Icons.favorite : Icons.favorite_border, color: wished ? c.accent : null),
                onPressed: () => toggleWishlistOrPromptLogin(context, product.id),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: product.images.isEmpty
                ? Container(color: c.bgAlt)
                : Stack(
                    children: [
                      PageView.builder(
                        itemCount: product.images.length,
                        onPageChanged: (i) => setState(() => _imageIndex = i),
                        itemBuilder: (_, i) => CachedNetworkImage(imageUrl: product.images[i], fit: BoxFit.cover),
                      ),
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _imageIndex ? c.primary : Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.brand != null)
                  Text(product.brand!.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.textFaint)),
                const SizedBox(height: 4),
                Text(product.name, style: Theme.of(context).textTheme.titleLarge),
                if (_reviewCount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StarRating(rating: _avgRating, size: 14, color: c.gold),
                      const SizedBox(width: 6),
                      Text('${_avgRating.toStringAsFixed(1)} ($_reviewCount)', style: TextStyle(fontSize: 12, color: c.textMuted)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(money(_price), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.secondary)),
                    if (_oldPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(money(_oldPrice!), style: TextStyle(fontSize: 14, color: c.textFaint, decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                if (_currentStock != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _outOfStock
                        ? 'Out of Stock'
                        : (_currentStock! <= 10 ? 'Only $_currentStock left in stock' : 'In Stock'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _outOfStock ? c.textFaint : (_currentStock! <= 10 ? c.accent : c.primary),
                    ),
                  ),
                ],
                if (!product.isSingleVariation && product.variations.length > 1) ...[
                  const SizedBox(height: 16),
                  Text('Options', style: TextStyle(fontWeight: FontWeight.w700, color: c.textSoft)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.variations.map((v) {
                      final selected = v.id == _selectedVariation?.id;
                      return ChoiceChip(
                        label: Text(v.label),
                        selected: selected,
                        onSelected: v.isOutOfStock ? null : (_) => _selectVariation(v),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700, color: c.textSoft)),
                    const Spacer(),
                    _QtyButton(icon: Icons.remove, onTap: () => setState(() => _quantity = (_quantity - 1).clamp(1, 99))),
                    SizedBox(width: 36, child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
                    _QtyButton(icon: Icons.add, onTap: () => setState(() => _quantity = (_quantity + 1).clamp(1, 99))),
                  ],
                ),
                if ((product.shortDescription ?? product.description) != null) ...[
                  const Divider(height: 32),
                  Text('Description', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 8),
                  Text(product.description ?? product.shortDescription ?? '', style: TextStyle(color: c.textSoft, height: 1.5)),
                ],
                if (product.features.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...product.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: c.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: f.name, style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                                    if (f.description != null) TextSpan(text: ' — ${f.description}', style: TextStyle(color: c.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ReviewsSection(productId: product.id),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: (_outOfStock || _variationId == null || _addingToCart)
                ? null
                : () async {
                    setState(() => _addingToCart = true);
                    final ok = await addToCartOrPromptLogin(context, product.id, _variationId!, quantity: _quantity);
                    if (!mounted) return;
                    setState(() => _addingToCart = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Added to cart' : 'Could not add to cart')),
                    );
                  },
            icon: _addingToCart
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.shopping_cart_outlined, size: 16),
            label: Text(_addingToCart ? 'Adding…' : (_outOfStock ? 'Unavailable' : 'Add to Cart')),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: c.secondary),
      ),
    );
  }
}
