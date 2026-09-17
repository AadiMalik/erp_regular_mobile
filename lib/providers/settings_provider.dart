import 'package:flutter/material.dart';

import '../services/website_settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  WebsiteSettings _settings = WebsiteSettings.fallback;
  WebsiteSettings get settings => _settings;

  Future<void> loadFromApi() async {
    _settings = await WebsiteSettingsService.fetch();
    notifyListeners();
  }

  String money(num amount) => _settings.money(amount);
}
