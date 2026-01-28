import 'package:dio/dio.dart';
import '../models/review_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class ReviewService {
  final ApiService _apiService = ApiService();

  /// Create a review
  Future<ApiResponse<void>> createReview({
    required int barterId,
    required int rating,
    String? komentar,
  }) async {
    try {
      await _apiService.post(
        '/reviews',
        data: {'id_barter': barterId, 'rating': rating, 'komentar': komentar},
      );
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to create review',
      );
    }
  }

  /// Get reviews for a barter
  Future<ApiResponse<List<Review>>> getBarterReviews(int barterId) async {
    try {
      final response = await _apiService.get('/reviews/barter/$barterId');

      final List reviews = response.data['data'] ?? [];
      final reviewList = reviews.map((json) => Review.fromJson(json)).toList();

      return ApiResponse.success(reviewList);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get barter reviews',
      );
    }
  }

  /// Get reviews for a user
  Future<ApiResponse<Map<String, dynamic>>> getUserReviews(
    String nik, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/reviews/user/$nik',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final responseData = response.data['data'];

      final result = {
        'reviews': (responseData['reviews'] as List)
            .map((json) => Review.fromJson(json))
            .toList(),
        'stats': ReviewStats.fromJson(responseData['stats']),
        'distribution': responseData['distribution'],
      };

      return ApiResponse.success(result);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get user reviews',
      );
    }
  }

  /// Get my reviews (reviews I received)
  Future<ApiResponse<Map<String, dynamic>>> getMyReviews({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/reviews/my-reviews',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final responseData = response.data['data'];

      final result = {
        'reviews': (responseData['reviews'] as List)
            .map((json) => Review.fromJson(json))
            .toList(),
        'stats': ReviewStats.fromJson(responseData['stats']),
      };

      return ApiResponse.success(result);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get my reviews',
      );
    }
  }
}
