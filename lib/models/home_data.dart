import 'category.dart';
import 'product.dart';

/// A CMS "section" row (hero / promo_banner / discount_banner) — shape
/// mirrors WebsiteSectionService public section fetch on the ERP.
class HomeSection {
  final String? tagline, taglineIcon, heading, headingIcon, description, image, imageMobile;
  final String? buttonText, buttonLink, secondaryButtonText, secondaryButtonLink;
  final DateTime? countdownEndAt;

  const HomeSection({
    this.tagline,
    this.taglineIcon,
    this.heading,
    this.headingIcon,
    this.description,
    this.image,
    this.imageMobile,
    this.buttonText,
    this.buttonLink,
    this.secondaryButtonText,
    this.secondaryButtonLink,
    this.countdownEndAt,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) => HomeSection(
        tagline: json['tagline'],
        taglineIcon: json['tagline_icon'],
        heading: json['heading'],
        headingIcon: json['heading_icon'],
        description: json['description'],
        image: json['image'],
        imageMobile: json['image_mobile'],
        buttonText: json['button_text'],
        buttonLink: json['button_link'],
        secondaryButtonText: json['secondary_button_text'],
        secondaryButtonLink: json['secondary_button_link'],
        countdownEndAt: DateTime.tryParse(json['countdown_end_at']?.toString() ?? ''),
      );

  bool get hasContent => (heading?.isNotEmpty ?? false) || (image?.isNotEmpty ?? false);
}

class HeroStat {
  final String value, label;
  final String? icon;
  const HeroStat({required this.value, required this.label, this.icon});

  factory HeroStat.fromJson(Map<String, dynamic> json) =>
      HeroStat(value: '${json['value'] ?? ''}', label: json['label'] ?? '', icon: json['icon']);
}

class Benefit {
  final String title;
  final String? description, icon;
  const Benefit({required this.title, this.description, this.icon});

  factory Benefit.fromJson(Map<String, dynamic> json) =>
      Benefit(title: json['title'] ?? '', description: json['description'], icon: json['icon']);
}

class ProductGroup {
  final bool enabled;
  final String heading;
  final String? headingIcon, description;
  final List<Product> products;

  const ProductGroup({this.enabled = false, this.heading = '', this.headingIcon, this.description, this.products = const []});

  factory ProductGroup.fromJson(Map<String, dynamic> json) => ProductGroup(
        enabled: json['enabled'] == true,
        heading: json['heading'] ?? '',
        headingIcon: json['heading_icon'],
        description: json['description'],
        products: (json['products'] as List? ?? []).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      );

  bool get shouldShow => enabled && products.isNotEmpty;
}

/// One-call aggregated homepage payload from GET /mobile/website-home
/// (WebsiteHomeService::build on the ERP) — mirrors the site's own single
/// bootstrap fetch instead of stitching several separate calls together.
class HomeData {
  final List<ProductCategory> categories;
  final HomeSection? hero;
  final List<HeroStat> heroStats;
  final HomeSection? whyShopWithUs;
  final List<Benefit> whyShopBenefits;
  final List<HomeSection> promoBanners, discountBanners;
  final ProductGroup featured, discounted, trending, newArrivals, bestSellers;

  const HomeData({
    this.categories = const [],
    this.hero,
    this.heroStats = const [],
    this.whyShopWithUs,
    this.whyShopBenefits = const [],
    this.promoBanners = const [],
    this.discountBanners = const [],
    this.featured = const ProductGroup(),
    this.discounted = const ProductGroup(),
    this.trending = const ProductGroup(),
    this.newArrivals = const ProductGroup(),
    this.bestSellers = const ProductGroup(),
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final sections = json['sections'] as Map<String, dynamic>? ?? {};
    final groups = sections['product_groups'] as Map<String, dynamic>? ?? {};
    HomeSection? single(String key) {
      final raw = sections[key];
      return raw is Map<String, dynamic> ? HomeSection.fromJson(raw) : null;
    }

    List<HomeSection> list(String key) =>
        (sections[key] as List? ?? []).map((e) => HomeSection.fromJson(e as Map<String, dynamic>)).toList();

    ProductGroup group(String key) {
      final raw = groups[key];
      return raw is Map<String, dynamic> ? ProductGroup.fromJson(raw) : const ProductGroup();
    }

    final navCategories = (json['navigation'] as Map<String, dynamic>?)?['categories'] as List? ?? [];

    return HomeData(
      categories: navCategories.map((e) => ProductCategory.fromJson(e as Map<String, dynamic>)).toList(),
      hero: single('hero')?.hasContent == true ? single('hero') : null,
      heroStats: (sections['hero_stats'] as List? ?? []).map((e) => HeroStat.fromJson(e as Map<String, dynamic>)).toList(),
      whyShopWithUs: single('why_shop_with_us'),
      whyShopBenefits: (sections['why_shop_benefits'] as List? ?? []).map((e) => Benefit.fromJson(e as Map<String, dynamic>)).toList(),
      promoBanners: list('promo_banners'),
      discountBanners: list('discount_banners'),
      featured: group('featured_products'),
      discounted: group('discounted_products'),
      trending: group('trending_products'),
      newArrivals: group('new_arrivals'),
      bestSellers: group('best_sellers'),
    );
  }
}
