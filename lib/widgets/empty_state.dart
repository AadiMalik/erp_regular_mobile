import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme_x.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyStateView({super.key, required this.icon, required this.title, required this.text, this.ctaLabel, this.onCta});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = t.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.primaryLight, shape: BoxShape.circle),
            child: Icon(icon, color: c.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.getFont(t.fontDisplay, fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: c.textMuted, height: 1.6)),
          if (ctaLabel != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onCta, child: Text(ctaLabel!)),
          ],
        ],
      ),
    );
  }
}
