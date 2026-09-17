import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../services/categories_service.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/empty_state.dart';
import '../product/product_listing_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<ProductCategory> _categories = [];
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
    final res = await CategoriesService.fetchCategories();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load categories.';
        _categories = [];
      });
      return;
    }
    setState(() {
      _categories = res.data ?? [];
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load categories',
                    text: _error!,
                    ctaLabel: 'Try Again',
                    onCta: _load,
                  ),
                )
              : _categories.isEmpty
                  ? const Center(
                      child: EmptyStateView(
                        icon: Icons.category_outlined,
                        title: 'No categories yet',
                        text: 'Categories will appear here once the store adds them.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) => CategoryTile(
                          category: _categories[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductListingScreen(category: _categories[i])),
                          ),
                        ),
                      ),
                    ),
    );
  }
}
