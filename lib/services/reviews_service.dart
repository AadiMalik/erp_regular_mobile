import '../config/env.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewsService {
  static Future<ReviewSummary> fetchReviews(String productId) async {
    try {
      final res = await ApiClient.instance.dio.get('/mobile/reviews/${Env.businessId}/$productId');
      final body = res.data;
      if (body?['Success'] != true || body?['Data'] == null) return const ReviewSummary();
      return ReviewSummary.fromJson(body['Data'] as Map<String, dynamic>);
    } catch (_) {
      return const ReviewSummary();
    }
  }

  static Future<ApiResult<dynamic>> submitReview({required String productId, required int rating, String? comment}) async {
    try {
      final res = await ApiClient.instance.dio.post('/mobile/reviews/${Env.businessId}', data: {
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      });
      return ApiResult.fromResponse(res, (d) => d);
    } catch (e) {
      return ApiResult.failure(e);
    }
  }
}
