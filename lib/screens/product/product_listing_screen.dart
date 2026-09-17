import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/branch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/products_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/wishlist_toggle.dart';
import '../../widgets/empty_state.dart';
import 'product_detail_screen.dart';

class ProductListingScreen extends StatefulWidget {
  final ProductCategory category;
  const ProductListingScreen({super.key, required this.category});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  List<Product> _products = [];
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
    final res = await ProductsService.fetchProducts(params: {
      'category_id': widget.category.id,
      if (branchId != null) 'branch_id': branchId,
    });
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load products.';
        _products = [];
      });
      return;
    }
    setState(() {
      _products = res.data?.items ?? [];
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<SettingsProvider>().money;

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load products',
                    text: _error!,
                    ctaLabel: 'Try Again',
                    onCta: _load,
                  ),
                )
              : _products.isEmpty
                  ? const Center(child: Text('No products in this category yet.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.52,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => ProductCard(
                        product: _products[i],
                        money: money,
                        wished: context.watch<WishlistProvider>().isWishlisted(_products[i].id),
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: _products[i].slug))),
                        onWishlistToggle: () => toggleWishlistOrPromptLogin(context, _products[i].id),
                        onAddToCart: () => addToCartOrPromptLogin(context, _products[i].id, _products[i].defaultVariationId!),
                      ),
                    ),
    );
  }
}
