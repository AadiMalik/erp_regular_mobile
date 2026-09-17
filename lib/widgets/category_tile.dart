import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category.dart';
import '../theme/theme_x.dart';

class CategoryTile extends StatelessWidget {
  final ProductCategory category;
  final VoidCallback? onTap;
  const CategoryTile({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final c = t.colors;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: c.primaryLight, borderRadius: BorderRadius.circular(t.rPanel)),
              clipBehavior: Clip.antiAlias,
              child: category.image != null && category.image!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: category.image!, fit: BoxFit.cover)
                  : Icon(Icons.category_outlined, color: c.primary),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.getFont(t.fontBody, fontSize: 11.5, fontWeight: FontWeight.w700, color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
