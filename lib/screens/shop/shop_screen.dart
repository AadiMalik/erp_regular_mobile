import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/branch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/products_service.dart';
import '../../theme/theme_x.dart';
import '../../widgets/product_card.dart';
import '../../widgets/wishlist_toggle.dart';
import '../../widgets/empty_state.dart';
import '../product/product_detail_screen.dart';

/// Full catalog with text search + price/sort filters — the artifact's
/// listing+filters screens combined into one, since the mobile app has no
/// separate "browse all" entry point otherwise.
class ShopScreen extends StatefulWidget {
  final String? initialQuery;
  const ShopScreen({super.key, this.initialQuery});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

enum _SortOption { relevance, priceLow, priceHigh, newest }

class _ShopScreenState extends State<ShopScreen> {
  late final _searchCtrl = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  RangeValues? _appliedPriceRange;
  _SortOption _sort = _SortOption.relevance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final params = <String, dynamic>{};
    final branchId = context.read<BranchProvider>().selectedId;
    if (branchId != null) params['branch_id'] = branchId;
    if (_searchCtrl.text.trim().isNotEmpty) params['search'] = _searchCtrl.text.trim();
    if (_appliedPriceRange != null) {
      params['price_min'] = _appliedPriceRange!.start.round();
      params['price_max'] = _appliedPriceRange!.end.round();
    }
    switch (_sort) {
      case _SortOption.priceLow:
        params['sort'] = 'price_asc';
        break;
      case _SortOption.priceHigh:
        params['sort'] = 'price_desc';
        break;
      case _SortOption.newest:
        params['sort'] = 'newest';
        break;
      case _SortOption.relevance:
        break;
    }
    final res = await ProductsService.fetchProducts(params: params);
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

  Future<void> _openFilters() async {
    final maxPrice = _products.isEmpty ? 1000.0 : _products.map((p) => p.price.toDouble()).reduce((a, b) => a > b ? a : b);
    var range = _appliedPriceRange ?? RangeValues(0, maxPrice);
    var sort = _sort;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              const Text('Price range', style: TextStyle(fontWeight: FontWeight.w700)),
              RangeSlider(
                values: range,
                min: 0,
                max: maxPrice < 1 ? 1000 : maxPrice,
                divisions: 20,
                labels: RangeLabels(range.start.round().toString(), range.end.round().toString()),
                onChanged: (v) => setSheetState(() => range = v),
              ),
              const SizedBox(height: 12),
              const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700)),
              Wrap(
                spacing: 8,
                children: _SortOption.values.map((opt) {
                  return ChoiceChip(
                    label: Text(_sortLabel(opt)),
                    selected: sort == opt,
                    onSelected: (_) => setSheetState(() => sort = opt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _appliedPriceRange = range;
                    _sort = sort;
                  });
                  Navigator.pop(ctx);
                  _load();
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(_SortOption o) => switch (o) {
        _SortOption.relevance => 'Relevance',
        _SortOption.priceLow => 'Price: Low to High',
        _SortOption.priceHigh => 'Price: High to Low',
        _SortOption.newest => 'Newest',
      };

  @override
  Widget build(BuildContext context) {
    final money = context.watch<SettingsProvider>().money;
    final c = context.appTheme.colors;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: widget.initialQuery == null,
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _load(),
          decoration: const InputDecoration(hintText: 'Search products…', border: InputBorder.none),
        ),
        actions: [
          IconButton(
            icon: Badge(isLabelVisible: _appliedPriceRange != null || _sort != _SortOption.relevance, child: const Icon(Icons.tune)),
            onPressed: _openFilters,
          ),
        ],
      ),
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
                  ? Center(child: Text('No products found.', style: TextStyle(color: c.textMuted)))
                  : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.52,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (_, i) {
                    final product = _products[i];
                    return ProductCard(
                      product: product,
                      money: money,
                      wished: context.watch<WishlistProvider>().isWishlisted(product.id),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: product.slug))),
                      onAddToCart: product.defaultVariationId == null
                          ? null
                          : () => addToCartOrPromptLogin(context, product.id, product.defaultVariationId!),
                      onWishlistToggle: () => toggleWishlistOrPromptLogin(context, product.id),
                    );
                  },
                ),
    );
  }
}
