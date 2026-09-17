import 'dart:async';

import 'package:flutter/material.dart';

import '../models/home_data.dart';
import '../theme/theme_x.dart';

/// Promo/discount CMS banner, paired directly above the discounted-products
/// rail — mirrors DealsBanner.vue, including the optional real countdown.
class DealsBanner extends StatefulWidget {
  final HomeSection banner;
  const DealsBanner({super.key, required this.banner});

  @override
  State<DealsBanner> createState() => _DealsBannerState();
}

class _DealsBannerState extends State<DealsBanner> {
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    final end = widget.banner.countdownEndAt;
    if (end != null) {
      _tick(end);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick(end));
    }
  }

  void _tick(DateTime end) {
    final left = end.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _remaining = left.isNegative ? Duration.zero : left);
    if (left.isNegative) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final b = widget.banner;
    final r = _remaining;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(context.appTheme.rCard)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.tagline != null)
            Text(b.tagline!.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w800)),
          if (b.heading != null) ...[
            const SizedBox(height: 4),
            Text(b.heading!, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
          if (b.description != null) ...[
            const SizedBox(height: 4),
            Text(b.description!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
          if (r != null) ...[
            const SizedBox(height: 10),
            Text(
              r == Duration.zero
                  ? 'Offer ended'
                  : '${r.inDays}d ${r.inHours % 24}h ${r.inMinutes % 60}m ${r.inSeconds % 60}s left',
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}
