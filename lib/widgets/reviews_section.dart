import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../services/reviews_service.dart';
import '../theme/theme_x.dart';
import 'star_rating.dart';

class ReviewsSection extends StatefulWidget {
  final String productId;
  const ReviewsSection({super.key, required this.productId});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  ReviewSummary _summary = const ReviewSummary();
  bool _loading = true;
  int _myRating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await ReviewsService.fetchReviews(widget.productId);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_myRating == 0) {
      setState(() => _error = 'Please pick a star rating.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final res = await ReviewsService.submitReview(productId: widget.productId, rating: _myRating, comment: _commentCtrl.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!res.success) {
      setState(() => _error = res.message);
      return;
    }
    _commentCtrl.clear();
    setState(() => _myRating = 0);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appTheme.colors;
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reviews', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator()))
          else ...[
            Row(
              children: [
                Text(_summary.average.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                StarRating(rating: _summary.average, color: c.gold),
                const SizedBox(width: 8),
                Text('(${_summary.count})', style: TextStyle(color: c.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoggedIn) ...[
              Text('Write a review', style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 13)),
              const SizedBox(height: 6),
              StarRating(rating: _myRating.toDouble(), size: 22, color: c.gold, onChanged: (v) => setState(() => _myRating = v)),
              const SizedBox(height: 8),
              TextField(
                controller: _commentCtrl,
                decoration: const InputDecoration(hintText: 'Share your thoughts (optional)'),
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit Review'),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.bgAlt, borderRadius: BorderRadius.circular(10)),
                child: const Text('Log in to write a review.'),
              ),
            const Divider(height: 32),
            if (_summary.reviews.isEmpty)
              Text('No reviews yet.', style: TextStyle(color: c.textMuted))
            else
              ..._summary.reviews.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(r.reviewerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(width: 8),
                            StarRating(rating: r.rating.toDouble(), size: 13, color: c.gold),
                          ],
                        ),
                        if (r.comment != null && r.comment!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r.comment!, style: TextStyle(color: c.textSoft, fontSize: 13)),
                        ],
                      ],
                    ),
                  )),
          ],
        ],
      ),
    );
  }
}
