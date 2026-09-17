class Review {
  final String id, reviewerName;
  final int rating;
  final String? comment, date;

  const Review({required this.id, required this.reviewerName, required this.rating, this.comment, this.date});

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: '${json['id']}',
        reviewerName: json['reviewer_name'] ?? 'Customer',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'],
        date: json['date'],
      );
}

class ReviewSummary {
  final double average;
  final int count;
  final List<Review> reviews;
  const ReviewSummary({this.average = 0, this.count = 0, this.reviews = const []});

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
        average: (json['average'] as num?)?.toDouble() ?? 0,
        count: json['count'] ?? 0,
        reviews: (json['reviews'] as List? ?? []).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
