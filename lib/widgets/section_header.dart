import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme_x.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.getFont(t.fontDisplay, fontSize: 16, fontWeight: FontWeight.w700, color: t.colors.text)),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: Text('See all', style: TextStyle(color: t.colors.primary, fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
