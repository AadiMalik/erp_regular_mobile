import 'package:flutter/material.dart';

/// Read-only stars (0.5-precision) when [onChanged] is null; a tappable
/// 1-5 picker otherwise.
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final ValueChanged<int>? onChanged;

  const StarRating({super.key, required this.rating, this.size = 16, this.color, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i && rating < i + 1;
        final icon = filled ? Icons.star : (half ? Icons.star_half : Icons.star_border);
        final star = Icon(icon, size: size, color: starColor);
        if (onChanged == null) return star;
        return InkWell(onTap: () => onChanged!(i + 1), child: star);
      }),
    );
  }
}
