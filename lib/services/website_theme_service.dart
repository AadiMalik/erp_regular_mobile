import 'package:flutter/material.dart';

import '../theme/theme_tokens.dart';
import 'api_client.dart';

/// Fetches the admin's ERP "Website Theme" choice: which of the 6 presets
/// is active, plus optional color overrides. Mirrors
/// services/websiteTheme.js — any failure (down API,
/// malformed response) must fall back to theme1 untouched (CLAUDE.md #12/13).
class WebsiteThemeService {
  static Future<AppThemeData> fetchActiveTheme() async {
    final fallback = kThemes[kDefaultThemeKey]!;
    try {
      final res = await ApiClient.instance.dio.get('/mobile/website-theme');
      final body = res.data;
      if (body?['Success'] != true || body?['Data']?['colors'] == null) return fallback;

      final data = body['Data'] as Map<String, dynamic>;
      final presetKey = data['theme_preset'] as String?;
      final preset = kThemes[presetKey] ?? fallback;
      final c = data['colors'] as Map<String, dynamic>? ?? {};

      return preset.copyWithColors(preset.colors.override(
        primary: _color(c['primary']),
        secondary: _color(c['secondary']),
        accent: _color(c['accent']),
        background: _color(c['background']),
        surface: _color(c['surface']),
        text: _color(c['text']),
        border: _color(c['border']),
      ));
    } catch (_) {
      return fallback;
    }
  }

  static Color? _color(dynamic hex) {
    if (hex is! String || hex.isEmpty) return null;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }
}
