import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  /// Get notifications
  Future<ApiResponse<Map<String, dynamic>>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = {'limit': limit, 'offset': offset};

      if (unreadOnly) {
        queryParams['unread_only'] = true;
      }

      final response = await _apiService.get(
        '/notifications',
        queryParameters: queryParams,
      );

      final responseData = response.data['data'];

      final result = {
        'notifications': (responseData['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList(),
        'unread_count': responseData['unread_count'] ?? 0,
      };

      return ApiResponse.success(result);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get notifications',
      );
    }
  }

  /// Get unread count
  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');
      final count = response.data['data']['count'] ?? 0;
      return ApiResponse.success(count);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get unread count',
      );
    }
  }

  /// Mark notification as read
  Future<ApiResponse<void>> markAsRead(int id) async {
    try {
      await _apiService.put('/notifications/$id/read');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to mark as read',
      );
    }
  }

  /// Mark all as read
  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      await _apiService.put('/notifications/read-all');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to mark all as read',
      );
    }
  }

  /// Delete notification
  Future<ApiResponse<void>> deleteNotification(int id) async {
    try {
      await _apiService.delete('/notifications/$id');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to delete notification',
      );
    }
  }
}
