import 'package:flutter/material.dart';

import '../models/home_data.dart';
import '../theme/theme_x.dart';
import 'section_header.dart';

/// "Why shop with us" perks — mirrors PerksGrid.vue. Icons are generic
/// (the CMS icon field is a web icon-font class name with no Flutter
/// equivalent to map 1:1) rather than trying to match the site pixel-for-pixel.
class PerksGrid extends StatelessWidget {
  final HomeSection? section;
  final List<Benefit> benefits;
  const PerksGrid({super.key, this.section, this.benefits = const []});

  @override
  Widget build(BuildContext context) {
    if (benefits.isEmpty) return const SizedBox.shrink();
    final c = context.appTheme.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: section?.heading ?? 'Why Shop With Us'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.5),
              itemCount: benefits.length,
              itemBuilder: (_, i) {
                final b = benefits[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: c.primary, size: 20),
                      const SizedBox(height: 6),
                      Text(b.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: c.text)),
                      if (b.description != null)
                        Text(b.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: c.textMuted)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
