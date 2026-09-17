import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/home_data.dart';
import '../theme/theme_x.dart';

/// Home's top banner — CMS-editable heading/description/image/CTA, plus
/// optional floating stat chips (hero_stats). Mirrors themes/*/Hero.vue.
class HeroBanner extends StatelessWidget {
  final HomeSection hero;
  final List<HeroStat> stats;
  final VoidCallback? onShopNow;
  final VoidCallback? onSecondary;

  const HeroBanner({
    super.key,
    required this.hero,
    this.stats = const [],
    this.onShopNow,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = t.colors;
    final onImage = hero.image != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      decoration: BoxDecoration(color: c.primaryLight, borderRadius: BorderRadius.circular(t.rCard)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hero.image != null)
            Positioned.fill(
              child: CachedNetworkImage(imageUrl: hero.image!, fit: BoxFit.cover, color: Colors.black.withValues(alpha: 0.15), colorBlendMode: BlendMode.darken),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hero.tagline != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(999)),
                    child: Text(hero.tagline!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 10),
                Text(
                  hero.heading ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: onImage ? Colors.white : c.text),
                ),
                if (hero.description != null) ...[
                  const SizedBox(height: 6),
                  Text(hero.description!, style: TextStyle(fontSize: 13, color: onImage ? Colors.white70 : c.textMuted)),
                ],
                if (hero.buttonText != null || hero.secondaryButtonText != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      if (hero.buttonText != null)
                        ElevatedButton(onPressed: onShopNow, child: Text(hero.buttonText!)),
                      if (hero.secondaryButtonText != null && onSecondary != null)
                        OutlinedButton(
                          onPressed: onSecondary,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onImage ? Colors.white : c.primary,
                            side: BorderSide(color: onImage ? Colors.white70 : c.primary),
                          ),
                          child: Text(hero.secondaryButtonText!),
                        ),
                    ],
                  ),
                ],
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: stats
                        .map((s) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: onImage ? Colors.white : c.primary)),
                                Text(s.label, style: TextStyle(fontSize: 10.5, color: onImage ? Colors.white70 : c.textMuted)),
                              ],
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
