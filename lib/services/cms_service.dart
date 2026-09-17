import 'api_client.dart';

/// Generic CMS content block (About Us, Contact Us intro, ...) — mirrors
/// services/cms.js fetchSection(type).
class CmsSection {
  final String? title, subtitle, content, image;
  const CmsSection({this.title, this.subtitle, this.content, this.image});

  factory CmsSection.fromJson(Map<String, dynamic> json) => CmsSection(
        title: json['title'],
        subtitle: json['subtitle'],
        content: json['content'],
        image: json['image'],
      );
}

class CmsService {
  static Future<CmsSection?> fetchSection(String type) async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/sections/$type');
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) return null;
      return CmsSection.fromJson(body['Data']);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> submitContactMessage({
    required String name,
    required String email,
    String? phone,
    String? subject,
    required String message,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post('/mobile/contact', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'subject': subject,
        'message': message,
      });
      return res.data?['Success'] == true;
    } catch (_) {
      return false;
    }
  }
}
