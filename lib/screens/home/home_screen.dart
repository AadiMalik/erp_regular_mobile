import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/home_data.dart';
import '../../providers/branch_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/home_service.dart';
import '../../theme/theme_x.dart';
import '../../widgets/branch_modal.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/deals_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/perks_grid.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/wishlist_toggle.dart';
import '../product/product_detail_screen.dart';
import '../product/product_listing_screen.dart';
import '../shop/shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeData _data = const HomeData();
  bool _loading = true;
  String? _error;

  BranchProvider? _branch;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Home stays mounted the whole app session (IndexedStack tab), so a
    // branch switch triggered from its own pill (below) must refresh this
    // screen's stock-bearing product sections itself - a rebuild from
    // context.watch() alone only updates the pill's label, not _data.
    final next = context.read<BranchProvider>();
    if (!identical(next, _branch)) {
      _branch?.removeListener(_onBranchChanged);
      _branch = next..addListener(_onBranchChanged);
    }
  }

  @override
  void dispose() {
    _branch?.removeListener(_onBranchChanged);
    super.dispose();
  }

  void _onBranchChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final branchId = context.read<BranchProvider>().selectedId;
    final res = await HomeService.fetch(branchId: branchId);
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Could not load homepage.';
        _data = const HomeData();
      });
      return;
    }
    setState(() {
      _data = res.data ?? const HomeData();
      _loading = false;
      _error = null;
    });
  }

  void _openShop() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<SettingsProvider>().money;
    final settings = context.watch<SettingsProvider>().settings;
    final branch = context.watch<BranchProvider>().selectedBranch;
    final c = context.appTheme.colors;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (settings.logo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(imageUrl: settings.logo!, width: 28, height: 28, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(settings.businessName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openShop,
          ),
          TextButton.icon(
            onPressed: () => showBranchModal(context),
            icon: Icon(Icons.storefront_outlined, size: 16, color: c.primary),
            label: Text(
              branch?.name ?? 'Select store',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load home',
                    text: _error!,
                    ctaLabel: 'Try Again',
                    onCta: _load,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (_data.hero != null)
                        HeroBanner(
                          hero: _data.hero!,
                          stats: _data.heroStats,
                          onShopNow: _openShop,
                          onSecondary: _data.hero!.secondaryButtonText != null ? _openShop : null,
                        ),
                      if (_data.categories.isNotEmpty) ...[
                        SizedBox(
                          // 68 image + 7 gap + up to 2 lines of an 11.5px name
                          // (~32px) + top/bottom padding — 108 clipped 2-line
                          // names in RenderFlex overflow warnings.
                          height: 136,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            scrollDirection: Axis.horizontal,
                            itemCount: _data.categories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (_, i) => CategoryTile(
                              category: _data.categories[i],
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProductListingScreen(category: _data.categories[i]))),
                            ),
                          ),
                        ),
                      ],
                      for (final promo in _data.promoBanners) DealsBanner(banner: promo),
                      _productRow(_data.featured, money),
                      _productRow(_data.trending, money),
                      if (_data.discounted.shouldShow) ...[
                        if (_data.discountBanners.isNotEmpty) DealsBanner(banner: _data.discountBanners.first),
                        _productRow(_data.discounted, money),
                      ],
                      _productRow(_data.newArrivals, money),
                      PerksGrid(section: _data.whyShopWithUs, benefits: _data.whyShopBenefits),
                      _productRow(_data.bestSellers, money),
                      SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
    );
  }

  Widget _productRow(ProductGroup group, String Function(num) money) {
    if (!group.shouldShow) return const SizedBox.shrink();
    final items = group.products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: group.heading, onSeeAll: _openShop),
        SizedBox(
          // ProductCard's padded content (brand + 2-line name + price row +
          // button) needs ~290px at this 150 width — 248 clipped it.
          height: 300,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 150,
              child: ProductCard(
                product: items[i],
                money: money,
                wished: context.watch<WishlistProvider>().isWishlisted(items[i].id),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: items[i].slug))),
                onWishlistToggle: () => toggleWishlistOrPromptLogin(context, items[i].id),
                onAddToCart: items[i].defaultVariationId == null
                    ? null
                    : () => addToCartOrPromptLogin(context, items[i].id, items[i].defaultVariationId!),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
