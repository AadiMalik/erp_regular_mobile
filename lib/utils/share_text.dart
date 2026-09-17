/// Builds the platform share links and the rich, ad-like message used by
/// ShareSheet. Facebook/LinkedIn's own unfurlers read OG tags from the
/// target URL, which the storefront doesn't render per-product server-side
/// - so price/rating/description are folded into the shared text itself
/// instead of relying on the link preview alone. Mirrors the website's
/// src/utils/share.js so both platforms produce the same message shape.
library;

String _truncate(String? s, int len) {
  if (s == null || s.isEmpty) return '';
  return s.length > len ? '${s.substring(0, len - 1).trim()}…' : s;
}

class ShareVariation {
  final String label;
  final String priceText;
  const ShareVariation(this.label, this.priceText);
}

String buildProductShareText({
  required String name,
  String? priceText,
  String? oldPriceText,
  double? rating,
  int? reviewCount,
  String? description,
  List<ShareVariation> variations = const [],
  String url = '',
}) {
  final lines = <String>['🛍️ ${name.isEmpty ? 'Check out this product' : name}'];

  if (priceText != null && priceText.isNotEmpty) {
    lines.add(oldPriceText != null && oldPriceText.isNotEmpty ? '💰 $priceText (was $oldPriceText)' : '💰 $priceText');
  }
  if (rating != null && rating > 0) {
    lines.add('⭐ ${rating.toStringAsFixed(1)}/5${reviewCount != null && reviewCount > 0 ? ' ($reviewCount reviews)' : ''}');
  }
  if (variations.isNotEmpty) {
    lines.add('📦 ${variations.map((v) => '${v.label}: ${v.priceText}').join('  |  ')}');
  }
  final desc = _truncate(description, 140);
  if (desc.isNotEmpty) lines.add('📝 $desc');
  if (url.isNotEmpty) {
    lines.add('');
    lines.add(url);
  }
  return lines.join('\n');
}

class ShareLinks {
  final String whatsapp, telegram, email;
  final String? facebook, linkedin, twitter, pinterest;
  const ShareLinks({
    required this.whatsapp,
    required this.telegram,
    required this.email,
    this.facebook,
    this.linkedin,
    this.twitter,
    this.pinterest,
  });
}

/// [url] empty means no public product link is configured (WEBSITE_URL
/// unset) - Facebook/LinkedIn/X/Pinterest need a real URL to unfurl, so
/// those come back null (ShareSheet disables those buttons) while
/// WhatsApp/Telegram/Email still work fine as text-only shares.
ShareLinks getShareLinks({required String url, required String text, String? title, String? image}) {
  final et = Uri.encodeComponent(text);
  final etitle = Uri.encodeComponent((title != null && title.isNotEmpty) ? title : 'Check out this product');

  String? eu;
  if (url.isNotEmpty) eu = Uri.encodeComponent(url);

  return ShareLinks(
    whatsapp: 'https://wa.me/?text=$et',
    telegram: eu != null ? 'https://t.me/share/url?url=$eu&text=$et' : 'https://t.me/share/url?text=$et',
    email: 'mailto:?subject=$etitle&body=$et',
    facebook: eu != null ? 'https://www.facebook.com/sharer/sharer.php?u=$eu&quote=$et' : null,
    linkedin: eu != null ? 'https://www.linkedin.com/sharing/share-offsite/?url=$eu' : null,
    twitter: eu != null ? 'https://twitter.com/intent/tweet?url=$eu&text=$etitle' : null,
    pinterest: (eu != null && image != null && image.isNotEmpty)
        ? 'https://pinterest.com/pin/create/button/?url=$eu&media=${Uri.encodeComponent(image)}&description=$etitle'
        : null,
  );
}
