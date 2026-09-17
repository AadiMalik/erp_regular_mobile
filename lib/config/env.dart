import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API and storefront URLs for this ERP installation. Loaded from .env at
/// startup (see main.dart) instead of being compiled in, so the API this
/// build targets can change without touching code — set by the deployment,
/// never by end users.
class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL']!;

  /// Public storefront domain (the Vue site), distinct from [apiBaseUrl]
  /// which points at the ERP API host - used to build shareable product
  /// links. Optional: falls back to '' so a deployment that hasn't set it
  /// yet degrades (link-based share options disable) instead of crashing.
  static String get websiteUrl => (dotenv.env['WEBSITE_URL'] ?? '').trim();
}
