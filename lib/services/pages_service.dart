import '../config/env.dart';
import 'api_client.dart';

/// Static CMS pages (Terms & Conditions, Privacy Policy, Return Policy,
/// Shipping Information, Cancellation Policy) — mirrors services/pages.js.
class CmsPage {
  final String title;
  final String content;
  const CmsPage({required this.title, required this.content});
}

class PagesService {
  static Future<CmsPage?> fetchPage(String slug) async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/pages/${Env.businessId}/$slug');
      final body = res.data;
      if (body?['Success'] != true || body?['Data']?['content'] == null) return null;
      final data = body['Data'];
      return CmsPage(title: data['title'] ?? '', content: data['content'] ?? '');
    } catch (_) {
      return null;
    }
  }
}
