import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Same ERP business this app talks to, mirrors the Vue site's .env
/// (VITE_API_BASE_URL / VITE_BUSINESS_ID). Loaded from .env at startup
/// (see main.dart) instead of being compiled in, so the business/API this
/// build targets can change without touching code — set by the
/// deployment, never by end users.
class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL']!;
  static String get businessId => dotenv.env['BUSINESS_ID']!;

  /// Public storefront domain (the Vue site), distinct from [apiBaseUrl]
  /// which points at the ERP API host - used to build shareable product
  /// links. Optional: falls back to '' so a deployment that hasn't set it
  /// yet degrades (link-based share options disable) instead of crashing.
  static String get websiteUrl => (dotenv.env['WEBSITE_URL'] ?? '').trim();
}
