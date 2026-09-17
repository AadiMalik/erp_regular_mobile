import 'api_client.dart';

class BankDetails {
  final String? bankName, accountTitle, accountNumber, iban, branch, swiftCode, instructions;
  const BankDetails({this.bankName, this.accountTitle, this.accountNumber, this.iban, this.branch, this.swiftCode, this.instructions});

  factory BankDetails.fromJson(Map<String, dynamic>? json) => BankDetails(
        bankName: json?['bank_name'],
        accountTitle: json?['account_title'],
        accountNumber: json?['account_number'],
        iban: json?['iban'],
        branch: json?['branch'],
        swiftCode: json?['swift_code'],
        instructions: json?['instructions'],
      );

  bool get hasDetails => [bankName, accountTitle, accountNumber, iban].any((v) => v != null && v.isNotEmpty);
}

/// Google/Facebook Login + CAPTCHA - off/absent until enabled and
/// configured in Settings > Social Login & Security. Public keys only,
/// never secrets (App\Models\LoginSecuritySetting).
class AuthSettings {
  final bool googleEnabled;
  final String? googleClientId;
  final bool facebookEnabled;
  final String? facebookAppId;
  final bool captchaEnabled;
  final String? recaptchaSiteKey;

  const AuthSettings({
    this.googleEnabled = false,
    this.googleClientId,
    this.facebookEnabled = false,
    this.facebookAppId,
    this.captchaEnabled = false,
    this.recaptchaSiteKey,
  });

  factory AuthSettings.fromJson(Map<String, dynamic>? json) {
    final google = json?['google'] as Map<String, dynamic>? ?? {};
    final facebook = json?['facebook'] as Map<String, dynamic>? ?? {};
    final captcha = json?['captcha'] as Map<String, dynamic>? ?? {};
    return AuthSettings(
      googleEnabled: google['enabled'] == true,
      googleClientId: google['client_id'],
      facebookEnabled: facebook['enabled'] == true,
      facebookAppId: facebook['app_id'],
      captchaEnabled: captcha['enabled'] == true,
      recaptchaSiteKey: captcha['site_key'],
    );
  }
}

class WebsiteSettings {
  final String businessName;
  final String? logo, phone, email, address;
  final String currencySymbol;
  final String currencyPosition;
  final BankDetails bankDetails;
  final AuthSettings auth;

  const WebsiteSettings({
    required this.businessName,
    this.logo,
    this.phone,
    this.email,
    this.address,
    this.currencySymbol = '\$',
    this.currencyPosition = 'before',
    this.bankDetails = const BankDetails(),
    this.auth = const AuthSettings(),
  });

  factory WebsiteSettings.fromJson(Map<String, dynamic> json) {
    final business = json['business'] as Map<String, dynamic>? ?? {};
    final currency = json['currency'] as Map<String, dynamic>? ?? {};
    return WebsiteSettings(
      businessName: business['name'] ?? 'Smart Mart',
      logo: business['logo'],
      phone: business['phone'],
      email: business['email'],
      address: business['address'],
      currencySymbol: currency['symbol'] ?? '\$',
      currencyPosition: currency['position'] ?? 'before',
      bankDetails: BankDetails.fromJson(json['bank_details'] as Map<String, dynamic>?),
      auth: AuthSettings.fromJson(json['auth'] as Map<String, dynamic>?),
    );
  }

  static const fallback = WebsiteSettings(businessName: 'Smart Mart');

  String money(num amount) {
    final formatted = amount.toStringAsFixed(2);
    return currencyPosition == 'after' ? '$formatted$currencySymbol' : '$currencySymbol$formatted';
  }
}

class WebsiteSettingsService {
  static Future<WebsiteSettings> fetch() async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/website-settings');
      final body = res.data;
      if (body?['Success'] != true || body?['Data']?['business'] == null) return WebsiteSettings.fallback;
      return WebsiteSettings.fromJson(body['Data']);
    } catch (_) {
      return WebsiteSettings.fallback;
    }
  }
}
