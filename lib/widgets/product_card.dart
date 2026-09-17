import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product.dart';
import '../theme/theme_x.dart';
import 'share_sheet.dart';

/// Grid product tile — image, badges, wishlist heart, rating, price, Add
/// to Cart — matches the .pcard block in the mobile UI-kit artifact across
/// all 6 themes (radius/shadow/font come from the active theme).
///
/// Owns its own busy/feedback state for both actions: a tap disables the
/// control immediately (so a slow request can't be tapped again) and shows
/// a confirming SnackBar once it resolves, instead of firing silently.
class ProductCard extends StatefulWidget {
  final Product product;
  final bool wished;
  final VoidCallback? onTap;
  final Future<bool> Function()? onWishlistToggle;
  final Future<bool> Function()? onAddToCart;
  final String Function(num) money;

  const ProductCard({
    super.key,
    required this.product,
    required this.money,
    this.wished = false,
    this.onTap,
    this.onWishlistToggle,
    this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _addingToCart = false;
  bool _togglingWishlist = false;

  Future<void> _handleAddToCart() async {
    if (widget.onAddToCart == null || _addingToCart) return;
    setState(() => _addingToCart = true);
    final ok = await widget.onAddToCart!();
    if (!mounted) return;
    setState(() => _addingToCart = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Added to cart' : 'Could not add to cart'), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _handleWishlistToggle() async {
    if (widget.onWishlistToggle == null || _togglingWishlist) return;
    final wasWished = widget.wished;
    setState(() => _togglingWishlist = true);
    final ok = await widget.onWishlistToggle!();
    if (!mounted) return;
    setState(() => _togglingWishlist = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wasWished ? 'Removed from wishlist' : 'Added to wishlist'), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = t.colors;
    final product = widget.product;
    final display = GoogleFonts.getFont(t.fontDisplay);
    final body = GoogleFonts.getFont(t.fontBody);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(t.rCard),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.image.isNotEmpty
                        ? CachedNetworkImage(imageUrl: product.image, fit: BoxFit.cover)
                        : Container(color: c.bgAlt),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _handleWishlistToggle,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                        child: _togglingWishlist
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: CircularProgressIndicator(strokeWidth: 2, color: c.secondary),
                              )
                            : Icon(widget.wished ? Icons.favorite : Icons.favorite_border, size: 16, color: widget.wished ? c.accent : c.secondary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 46,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => showShareSheet(
                        context,
                        productId: product.id,
                        name: product.name,
                        image: product.image,
                        slug: product.slug,
                        price: product.price,
                        oldPrice: product.oldPrice,
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                        child: Icon(Icons.share_outlined, size: 15, color: c.secondary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.isOutOfStock)
                          _Badge(text: 'Sold out', color: c.textFaint)
                        else if (product.oldPrice != null)
                          _Badge(text: 'Sale', color: c.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand != null)
                    Text(product.brand!.toUpperCase(), style: body.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, color: c.textFaint)),
                  const SizedBox(height: 3),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: display.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.text),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(widget.money(product.price), style: display.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: c.secondary)),
                      if (product.oldPrice != null) ...[
                        const SizedBox(width: 5),
                        Text(widget.money(product.oldPrice!),
                            style: body.copyWith(fontSize: 11, color: c.textFaint, decoration: TextDecoration.lineThrough)),
                      ],
                      if (product.loyaltyEligible) ...[
                        const SizedBox(width: 5),
                        // Google's actual Noto Color Emoji coin asset, not the
                        // raw Unicode character - U+1FA99 is a 2021 addition
                        // most device emoji fonts (esp. on older/Windows
                        // builds) don't render, so the glyph alone showed up
                        // blank/tofu for a lot of users.
                        CachedNetworkImage(
                          imageUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1fa99/72.png',
                          width: 14,
                          height: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: (product.isOutOfStock || product.defaultVariationId == null || _addingToCart) ? null : _handleAddToCart,
                      icon: _addingToCart
                          ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: c.primaryDark))
                          : const Icon(Icons.shopping_cart_outlined, size: 16),
                      label: Text(
                        _addingToCart ? 'Adding…' : (product.isOutOfStock ? 'Unavailable' : 'Add to Cart'),
                        style: body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primaryLight,
                        foregroundColor: c.primaryDark,
                        disabledBackgroundColor: c.bgAlt,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
    );
  }
}
