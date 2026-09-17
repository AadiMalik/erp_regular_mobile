import 'package:flutter/material.dart';

/// Color tokens for one theme preset. Field names mirror the CSS custom
/// properties in the Vue site's src/styles/themes/theme*.css (--c-primary,
/// --c-text-faint, etc.) so a value can be cross-checked against that file.
class ThemeColors {
  final Color primary, primaryDark, primaryDarker, primaryLight;
  final Color secondary, accent, accentDark, gold;
  final Color danger, dangerLight, info;
  final Color bg, bgAlt, surface, border, borderStrong;
  final Color text, textSoft, textMuted, textFaint;

  const ThemeColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryDarker,
    required this.primaryLight,
    required this.secondary,
    required this.accent,
    required this.accentDark,
    required this.gold,
    required this.danger,
    required this.dangerLight,
    required this.info,
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSoft,
    required this.textMuted,
    required this.textFaint,
  });

  /// Builds a copy with any admin-picked overrides (ERP "Website Theme"
  /// colors: primary/secondary/accent/background/surface/text/heading/
  /// border/success/warning/error) applied on top of this preset.
  ThemeColors override({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? text,
    Color? border,
  }) {
    return ThemeColors(
      primary: primary ?? this.primary,
      primaryDark: primary ?? primaryDark,
      primaryDarker: primary ?? primaryDarker,
      primaryLight: primaryLight,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      accentDark: accent ?? accentDark,
      gold: gold,
      danger: danger,
      dangerLight: dangerLight,
      info: info,
      bg: background ?? bg,
      bgAlt: bgAlt,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      borderStrong: borderStrong,
      text: text ?? this.text,
      textSoft: textSoft,
      textMuted: textMuted,
      textFaint: textFaint,
    );
  }
}

/// One full theme preset: colors, fonts, and shape tokens. Values are
/// copied verbatim from the THEMES map in the mobile UI-kit artifact,
/// which itself ports src/styles/themes/theme{1..6}.css.
class AppThemeData {
  final String key, name, blurb;
  final String fontDisplay, fontBody;
  final FontWeight btnWeight;
  final double rBtn, rCard, rField, rPanel;
  final ThemeColors colors;

  const AppThemeData({
    required this.key,
    required this.name,
    required this.blurb,
    required this.fontDisplay,
    required this.fontBody,
    required this.btnWeight,
    required this.rBtn,
    required this.rCard,
    required this.rField,
    required this.rPanel,
    required this.colors,
  });

  AppThemeData copyWithColors(ThemeColors c) => AppThemeData(
        key: key,
        name: name,
        blurb: blurb,
        fontDisplay: fontDisplay,
        fontBody: fontBody,
        btnWeight: btnWeight,
        rBtn: rBtn,
        rCard: rCard,
        rField: rField,
        rPanel: rPanel,
        colors: c,
      );
}

const _pillRadius = 999.0;

/// The 6 predefined ERP themes (CLAUDE.md #4: no custom CSS builder, admin
/// picks one of these). Keyed the same as the ERP's theme_preset value.
final Map<String, AppThemeData> kThemes = {
  'theme1': AppThemeData(
    key: 'theme1',
    name: 'Classic Market',
    blurb: 'Fresh & trusted grocery classic — soft greens, pill buttons, generous rounded cards.',
    fontDisplay: 'Poppins',
    fontBody: 'Plus Jakarta Sans',
    btnWeight: FontWeight.w600,
    rBtn: _pillRadius,
    rCard: 20,
    rField: 8,
    rPanel: 14,
    colors: const ThemeColors(
      primary: Color(0xFF1E9E5A), primaryDark: Color(0xFF157A45), primaryDarker: Color(0xFF0E5C33), primaryLight: Color(0xFFE7F8EE),
      secondary: Color(0xFF0B3D2E), accent: Color(0xFFFF6B35), accentDark: Color(0xFFE1531F), gold: Color(0xFFFFB020),
      danger: Color(0xFFE5484D), dangerLight: Color(0xFFFDECEC), info: Color(0xFF2E8AE6),
      bg: Color(0xFFFFFFFF), bgAlt: Color(0xFFF3F6F4), surface: Color(0xFFFFFFFF), border: Color(0xFFE7ECE9), borderStrong: Color(0xFFD3DBD6),
      text: Color(0xFF16241C), textSoft: Color(0xFF38493F), textMuted: Color(0xFF6B7B72), textFaint: Color(0xFF9AA9A1),
    ),
  ),
  'theme2': AppThemeData(
    key: 'theme2',
    name: 'Vibrant Bazaar',
    blurb: 'Bold & energetic — violet and tangerine, extra-large radii, bouncy spring motion.',
    fontDisplay: 'Outfit',
    fontBody: 'Rubik',
    btnWeight: FontWeight.w700,
    rBtn: _pillRadius,
    rCard: 28,
    rField: 14,
    rPanel: 20,
    colors: const ThemeColors(
      primary: Color(0xFF7C3AED), primaryDark: Color(0xFF6D28D9), primaryDarker: Color(0xFF5B21B6), primaryLight: Color(0xFFF1E8FE),
      secondary: Color(0xFF1E1533), accent: Color(0xFFFB923C), accentDark: Color(0xFFEA580C), gold: Color(0xFFF472B6),
      danger: Color(0xFFE11D48), dangerLight: Color(0xFFFDE4EA), info: Color(0xFF2563EB),
      bg: Color(0xFFFFFFFF), bgAlt: Color(0xFFF4EEFC), surface: Color(0xFFFFFFFF), border: Color(0xFFEBE1FB), borderStrong: Color(0xFFD6C4F7),
      text: Color(0xFF1E1533), textSoft: Color(0xFF4A3B66), textMuted: Color(0xFF7A6B96), textFaint: Color(0xFFAB9FC7),
    ),
  ),
  'theme3': AppThemeData(
    key: 'theme3',
    name: 'Luxury Edit',
    blurb: 'Elegant & editorial — near-black and antique gold, serif display, sharp quiet corners.',
    fontDisplay: 'Playfair Display',
    fontBody: 'Inter',
    btnWeight: FontWeight.w500,
    rBtn: 8,
    rCard: 8,
    rField: 4,
    rPanel: 8,
    colors: const ThemeColors(
      primary: Color(0xFF1C1917), primaryDark: Color(0xFF0C0A09), primaryDarker: Color(0xFF000000), primaryLight: Color(0xFFF5F1E8),
      secondary: Color(0xFF1C1917), accent: Color(0xFFA16207), accentDark: Color(0xFF854D0E), gold: Color(0xFFCA8A04),
      danger: Color(0xFFB91C1C), dangerLight: Color(0xFFF7E5E5), info: Color(0xFF1E40AF),
      bg: Color(0xFFFAFAF9), bgAlt: Color(0xFFEFEDE9), surface: Color(0xFFFFFFFF), border: Color(0xFFE3DFD8), borderStrong: Color(0xFFC9C3B8),
      text: Color(0xFF1C1917), textSoft: Color(0xFF3F3A34), textMuted: Color(0xFF78716C), textFaint: Color(0xFFA8A29E),
    ),
  ),
  'theme4': AppThemeData(
    key: 'theme4',
    name: 'Fresh Block',
    blurb: 'Bold brutalist grocery — hard offset shadows, thick ink borders, blocky confident type.',
    fontDisplay: 'Rubik',
    fontBody: 'Nunito Sans',
    btnWeight: FontWeight.w800,
    rBtn: 10,
    rCard: 12,
    rField: 8,
    rPanel: 10,
    colors: const ThemeColors(
      primary: Color(0xFF0F7A3D), primaryDark: Color(0xFF0B5C2E), primaryDarker: Color(0xFF073D1F), primaryLight: Color(0xFFDFF3E4),
      secondary: Color(0xFF111827), accent: Color(0xFFFF5722), accentDark: Color(0xFFD8451A), gold: Color(0xFFFFC107),
      danger: Color(0xFFDC2626), dangerLight: Color(0xFFFBE3E3), info: Color(0xFF2563EB),
      bg: Color(0xFFFBFAF7), bgAlt: Color(0xFFECE9DF), surface: Color(0xFFFFFFFF), border: Color(0xFF111827), borderStrong: Color(0xFF111827),
      text: Color(0xFF111827), textSoft: Color(0xFF1F2937), textMuted: Color(0xFF4B5563), textFaint: Color(0xFF6B7280),
    ),
  ),
  'theme5': AppThemeData(
    key: 'theme5',
    name: 'Atelier',
    blurb: 'Clean, quiet boutique — ink and bronze, near-flat cards, single wide-tracked sans.',
    fontDisplay: 'Montserrat',
    fontBody: 'Montserrat',
    btnWeight: FontWeight.w500,
    rBtn: _pillRadius,
    rCard: 2,
    rField: 2,
    rPanel: 6,
    colors: const ThemeColors(
      primary: Color(0xFF14181A), primaryDark: Color(0xFF000000), primaryDarker: Color(0xFF000000), primaryLight: Color(0xFFEFEDE7),
      secondary: Color(0xFF14181A), accent: Color(0xFFA6803C), accentDark: Color(0xFF8A6A2F), gold: Color(0xFFA6803C),
      danger: Color(0xFFB3261E), dangerLight: Color(0xFFF6E3E1), info: Color(0xFF35506E),
      bg: Color(0xFFFAF9F6), bgAlt: Color(0xFFECE9E1), surface: Color(0xFFFFFFFF), border: Color(0xFFE4E0D6), borderStrong: Color(0xFFCFC9BB),
      text: Color(0xFF1B1D1E), textSoft: Color(0xFF3A3D3E), textMuted: Color(0xFF6E6A62), textFaint: Color(0xFF9C968A),
    ),
  ),
  'theme6': AppThemeData(
    key: 'theme6',
    name: 'Bazaar Bento',
    blurb: 'Playful marketplace — violet and jade, big bento radii, app-style bottom nav.',
    fontDisplay: 'Outfit',
    fontBody: 'Work Sans',
    btnWeight: FontWeight.w700,
    rBtn: _pillRadius,
    rCard: 24,
    rField: 14,
    rPanel: 20,
    colors: const ThemeColors(
      primary: Color(0xFF7C3AED), primaryDark: Color(0xFF6D28D9), primaryDarker: Color(0xFF5B21B6), primaryLight: Color(0xFFEDE4FD),
      secondary: Color(0xFF4C1D95), accent: Color(0xFF16A34A), accentDark: Color(0xFF15803D), gold: Color(0xFFF59E0B),
      danger: Color(0xFFE11D48), dangerLight: Color(0xFFFCE4EA), info: Color(0xFF2563EB),
      bg: Color(0xFFFBF9FF), bgAlt: Color(0xFFECE2FC), surface: Color(0xFFFFFFFF), border: Color(0xFFE3D6FB), borderStrong: Color(0xFFC9B3F5),
      text: Color(0xFF2E1065), textSoft: Color(0xFF4C1D95), textMuted: Color(0xFF6B5B95), textFaint: Color(0xFF9A8CC0),
    ),
  ),
};

const kDefaultThemeKey = 'theme1';
