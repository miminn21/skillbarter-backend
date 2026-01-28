import '../services/api_service.dart';

class RatingService {
  final ApiService _apiService = ApiService();

  /// Submit rating for a barter
  Future<Map<String, dynamic>> submitRating({
    required int barterId,
    required int rating,
    String? comment,
    bool anonymous = false,
  }) async {
    final response = await _apiService.post(
      '/barter/offers/$barterId/rate',
      data: {'rating': rating, 'komentar': comment, 'anonim': anonymous},
    );

    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'Failed to submit rating');
    }
  }

  /// Check if user has rated a barter
  Future<Map<String, dynamic>> checkMyRating(int barterId) async {
    final response = await _apiService.get(
      '/barter/offers/$barterId/my-rating',
    );

    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(data['message'] ?? 'Failed to check rating');
    }
  }

  /// Get all ratings for a barter
  Future<List<dynamic>> getBarterRatings(int barterId) async {
    final response = await _apiService.get('/barter/offers/$barterId/ratings');

    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as List<dynamic>;
    } else {
      throw Exception(data['message'] ?? 'Failed to get ratings');
    }
  }
}
