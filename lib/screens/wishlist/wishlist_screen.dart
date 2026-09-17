import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wishlist_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/wishlist_service.dart';
import '../../theme/theme_x.dart';
import '../../widgets/empty_state.dart';
import '../auth/login_screen.dart';
import '../product/product_detail_screen.dart';

/// Saved items list. The wishlist endpoint returns a lighter shape than the
/// catalog (no price/stock/variation-default — see WishlistItem), so this
/// shows image/name/brand and opens the full product page for pricing and
/// add-to-cart rather than trying to reuse ProductCard here.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<WishlistItem> _items = [];
  bool _loading = true;
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isLoggedIn) _load();
    });
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final items = await WishlistService.fetchWishlistItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _remove(WishlistItem item) async {
    setState(() => _removingIds.add(item.id));
    final ok = await context.read<WishlistProvider>().toggle(item.productId);
    if (!mounted) return;
    setState(() => _removingIds.remove(item.id));
    if (ok) {
      setState(() => _items.removeWhere((i) => i.id == item.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist'), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      appBar: AppBar(title: Text('Wishlist (${_items.length})')),
      body: !isLoggedIn
          ? Center(
              child: EmptyStateView(
                icon: Icons.lock_outline,
                title: 'Sign in to view your wishlist',
                text: 'Log in to save and see your favorite products.',
                ctaLabel: 'Sign In',
                onCta: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Center(
                      child: EmptyStateView(
                        icon: Icons.favorite_border,
                        title: 'No favorites yet',
                        text: 'Tap the heart on any product to save it here.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 24),
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final removing = _removingIds.contains(item.id);
                          return InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: item.slug))),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(10)),
                                  clipBehavior: Clip.antiAlias,
                                  child: item.image.isNotEmpty ? CachedNetworkImage(imageUrl: item.image, fit: BoxFit.cover) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item.brand != null)
                                        Text(item.brand!.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: c.textFaint)),
                                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (item.variationLabel != null)
                                        Text(item.variationLabel!, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
                                    ],
                                  ),
                                ),
                                removing
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                      )
                                    : TextButton(
                                        onPressed: () => _remove(item),
                                        child: Text('Remove', style: TextStyle(fontSize: 12.5, color: c.danger)),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
