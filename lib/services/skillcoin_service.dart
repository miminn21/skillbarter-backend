import 'package:dio/dio.dart';
import '../models/skillcoin_transaction.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class SkillCoinService {
  final ApiService _apiService = ApiService();

  /// Get current balance
  Future<ApiResponse<int>> getBalance() async {
    try {
      final response = await _apiService.get('/skillcoin/balance');
      final balance = response.data['data']['balance'] ?? 0;
      return ApiResponse.success(balance);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get balance',
      );
    }
  }

  /// Get transaction history
  Future<ApiResponse<List<SkillcoinTransaction>>> getHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiService.get(
        '/skillcoin/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final List transactions = response.data['data'] ?? [];
      final history = transactions
          .map((json) => SkillcoinTransaction.fromJson(json))
          .toList();

      return ApiResponse.success(history);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get history',
      );
    }
  }

  /// Get statistics
  Future<ApiResponse<SkillcoinStatistics>> getStats() async {
    try {
      final response = await _apiService.get('/skillcoin/stats');
      final stats = SkillcoinStatistics.fromJson(response.data['data']);
      return ApiResponse.success(stats);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to get stats',
      );
    }
  }

  /// Manual transfer (admin only or future feature)
  Future<ApiResponse<void>> transfer({
    required String nikPenerima,
    required int jumlah,
    String? keterangan,
  }) async {
    try {
      await _apiService.post(
        '/skillcoin/transfer',
        data: {
          'nik_penerima': nikPenerima,
          'jumlah': jumlah,
          'keterangan': keterangan,
        },
      );
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data['message'] ?? 'Failed to transfer',
      );
    }
  }
}
