import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';
import '../models/product.dart';
import '../providers/settings_provider.dart';
import '../services/products_service.dart';
import '../services/reviews_service.dart';
import '../theme/theme_x.dart';
import '../utils/share_text.dart';
import 'star_rating.dart';

/// "Share this product" bottom sheet - mirrors the website's ShareModal
/// (src/components/common/ShareModal.vue). Callers (e.g. an order line
/// item) usually only know name/image/price/slug; if [slug] is given and
/// [description] wasn't, this fetches the full product so the shared
/// content is as rich as the product page (description, rating, priced
/// variations) instead of staying limited to those bare fields.
Future<void> showShareSheet(
  BuildContext context, {
  required String productId,
  required String name,
  String? image,
  num? price,
  num? oldPrice,
  String? slug,
  String? description,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ShareSheet(
      productId: productId,
      name: name,
      image: image,
      price: price,
      oldPrice: oldPrice,
      slug: slug,
      description: description,
    ),
  );
}

class _ShareSheet extends StatefulWidget {
  final String productId;
  final String name;
  final String? image;
  final num? price;
  final num? oldPrice;
  final String? slug;
  final String? description;

  const _ShareSheet({
    required this.productId,
    required this.name,
    this.image,
    this.price,
    this.oldPrice,
    this.slug,
    this.description,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  Product? _product;
  double _rating = 0;
  int _reviewCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Ratings aren't part of showShareSheet()'s own parameters
    // (they're loaded separately there via ReviewsSection) - fetch them here
    // regardless of whether the caller already had a description, so the
    // preview always shows stars when the product has reviews.
    ReviewsService.fetchReviews(widget.productId).then((s) {
      if (!mounted) return;
      setState(() {
        _rating = s.average;
        _reviewCount = s.count;
      });
    });

    if ((widget.description == null || widget.description!.isEmpty) &&
        widget.slug != null &&
        widget.slug!.isNotEmpty) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    final res = await ProductsService.fetchProductBySlug(widget.slug!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) _product = res.data;
    });
  }

  String get _name => _product?.name ?? widget.name;
  String get _image => (_product?.images.isNotEmpty ?? false) ? _product!.images.first : (widget.image ?? '');
  num get _price => _product?.price ?? widget.price ?? 0;
  num? get _oldPrice => _product?.oldPrice ?? widget.oldPrice;
  String? get _description => _product?.description ?? widget.description;
  List<VariationOption> get _variations =>
      (_product != null && !_product!.isSingleVariation) ? _product!.variations : const [];
  String get _slug => _product?.slug ?? widget.slug ?? '';

  String get _shareUrl {
    final base = Env.websiteUrl;
    if (base.isEmpty || _slug.isEmpty) return '';
    final origin = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$origin/product/$_slug';
  }

  String _shareText(String Function(num) money) => buildProductShareText(
        name: _name,
        priceText: money(_price),
        oldPriceText: _oldPrice != null ? money(_oldPrice!) : null,
        rating: _rating,
        reviewCount: _reviewCount,
        description: _description,
        variations: _variations.map((v) => ShareVariation(v.label, money(v.price))).toList(),
        url: _shareUrl,
      );

  Future<void> _open(String? url, String platform) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the share link.')));
      return;
    }
    ProductsService.recordShare(widget.productId, platform);
  }

  Future<void> _copyLink() async {
    final url = _shareUrl;
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
    ProductsService.recordShare(widget.productId, 'copy_link');
  }

  Future<void> _nativeShare(String text) async {
    await Share.share(text, subject: _name);
    ProductsService.recordShare(widget.productId, 'native');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final money = context.watch<SettingsProvider>().money;
    final links = getShareLinks(url: _shareUrl, text: _shareText(money), title: _name, image: _image);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share_outlined, color: c.secondary, size: 18),
                const SizedBox(width: 8),
                Text('Share this product', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _image.isEmpty
                        ? Container(width: 72, height: 72, color: c.border)
                        : CachedNetworkImage(imageUrl: _image, width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        if (_reviewCount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              StarRating(rating: _rating, size: 12, color: c.gold),
                              const SizedBox(width: 6),
                              Text('($_reviewCount)', style: TextStyle(fontSize: 11, color: c.textMuted)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(money(_price), style: TextStyle(fontWeight: FontWeight.w700, color: c.secondary)),
                            if (_oldPrice != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                money(_oldPrice!),
                                style: TextStyle(fontSize: 11.5, color: c.textFaint, decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ],
                        ),
                        if (_description != null && _description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: c.textMuted),
                          ),
                        ],
                        if (_variations.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _variations
                                .map(
                                  (v) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      border: Border.all(color: c.border),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text('${v.label}: ${money(v.price)}', style: TextStyle(fontSize: 10.5, color: c.textMuted)),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (_loading) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.6, color: c.textFaint)),
                              const SizedBox(width: 6),
                              Text('Loading full details…', style: TextStyle(fontSize: 10.5, color: c.textFaint)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                _PlatformButton(icon: Icons.chat_bubble, label: 'WhatsApp', color: const Color(0xFF25D366), onTap: () => _open(links.whatsapp, 'whatsapp')),
                _PlatformButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: links.facebook != null ? () => _open(links.facebook, 'facebook') : null,
                ),
                _PlatformButton(
                  icon: Icons.business_center,
                  label: 'LinkedIn',
                  color: const Color(0xFF0A66C2),
                  onTap: links.linkedin != null ? () => _open(links.linkedin, 'linkedin') : null,
                ),
                _PlatformButton(
                  icon: Icons.close,
                  label: 'X',
                  color: c.text,
                  onTap: links.twitter != null ? () => _open(links.twitter, 'twitter') : null,
                ),
                _PlatformButton(icon: Icons.send, label: 'Telegram', color: const Color(0xFF26A5E4), onTap: () => _open(links.telegram, 'telegram')),
                _PlatformButton(
                  icon: Icons.push_pin_outlined,
                  label: 'Pinterest',
                  color: const Color(0xFFE60023),
                  onTap: links.pinterest != null ? () => _open(links.pinterest, 'pinterest') : null,
                ),
                _PlatformButton(icon: Icons.email_outlined, label: 'Email', color: c.secondary, onTap: () => _open(links.email, 'email')),
                _PlatformButton(icon: Icons.more_horiz, label: 'More', color: c.primary, onTap: () => _nativeShare(_shareText(money))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      _shareUrl.isEmpty ? 'Link unavailable' : _shareUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _shareUrl.isEmpty ? null : _copyLink,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _PlatformButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
