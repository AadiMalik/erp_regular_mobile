import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/website_theme_service.dart';
import 'theme_tokens.dart';

/// Holds the ERP-selected theme and exposes it as both the raw
/// [AppThemeData] token set (for widgets that need e.g. `t.colors.gold`)
/// and a built Material [ThemeData] (for MaterialApp itself).
class ThemeProvider extends ChangeNotifier {
  AppThemeData _theme = kThemes[kDefaultThemeKey]!;
  bool _loaded = false;

  AppThemeData get theme => _theme;
  bool get loaded => _loaded;

  Future<void> loadFromApi() async {
    _theme = await WebsiteThemeService.fetchActiveTheme();
    _loaded = true;
    notifyListeners();
  }

  ThemeData toMaterialTheme() {
    final c = _theme.colors;
    final display = GoogleFonts.getFont(_theme.fontDisplay);
    final body = GoogleFonts.getFont(_theme.fontBody);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.light(
        primary: c.primary,
        secondary: c.accent,
        error: c.danger,
        surface: c.surface,
      ),
      textTheme: Typography.blackMountainView.apply(bodyColor: c.text, displayColor: c.text).copyWith(
            titleLarge: display.copyWith(fontWeight: FontWeight.w700, color: c.text),
            titleMedium: display.copyWith(fontWeight: FontWeight.w600, color: c.text),
            bodyMedium: body.copyWith(color: c.text),
            bodySmall: body.copyWith(color: c.textMuted),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        titleTextStyle: display.copyWith(fontWeight: FontWeight.w700, fontSize: 16.5, color: c.text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          textStyle: body.copyWith(fontWeight: _theme.btnWeight, fontSize: 13.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_theme.rBtn)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_theme.rField),
          borderSide: BorderSide(color: c.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_theme.rField),
          borderSide: BorderSide(color: c.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_theme.rField),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_theme.rCard),
          side: BorderSide(color: c.border),
        ),
      ),
      dividerColor: c.border,
    );
  }
}
