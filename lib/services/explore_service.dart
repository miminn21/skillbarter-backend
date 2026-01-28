import 'package:dio/dio.dart';
import '../models/skill_model.dart';
import '../models/user_public_model.dart';
import '../models/leaderboard_model.dart';
import '../models/explore_filter_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class ExploreService {
  final ApiService _apiService = ApiService();

  /// Explore skills with filters
  Future<ApiResponse<Map<String, dynamic>>> exploreSkills(
    ExploreFilterModel filter,
  ) async {
    try {
      final response = await _apiService.get(
        '/explore',
        queryParameters: filter.toQueryParams(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final skillsData = data['data'];
          final List<SkillModel> skills = (skillsData['skills'] as List)
              .map((json) => SkillModel.fromJson(json))
              .toList();

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: {'skills': skills, 'pagination': skillsData['pagination']},
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to explore skills',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Get personalized recommendations
  Future<ApiResponse<List<SkillModel>>> getRecommendations() async {
    try {
      final response = await _apiService.get('/recommendations');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<SkillModel> recommendations = (data['data'] as List)
              .map((json) => SkillModel.fromJson(json))
              .toList();

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: recommendations,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to get recommendations',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Get user public profile
  Future<ApiResponse<UserPublicModel>> getUserProfile(String nik) async {
    try {
      final response = await _apiService.get('/users/$nik');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final userData = data['data'];

          // Parse user with skills
          final user = UserPublicModel.fromJson(userData['user']);
          final List<SkillModel> skills = userData['skills'] != null
              ? (userData['skills'] as List)
                    .map((json) => SkillModel.fromJson(json))
                    .toList()
              : [];

          final userWithSkills = UserPublicModel(
            nik: user.nik,
            namaLengkap: user.namaLengkap,
            namaPanggilan: user.namaPanggilan,
            fotoProfil: user.fotoProfil,
            ratingRataRata: user.ratingRataRata,
            jumlahTransaksi: user.jumlahTransaksi,
            saldoSkillcoin: user.saldoSkillcoin,
            totalJamBerkontribusi: user.totalJamBerkontribusi,
            statusOnline: user.statusOnline, // Copied from user
            terakhirAktif: user.terakhirAktif, // Copied from user
            skills: skills,
          );

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: userWithSkills,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to get user profile',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Get leaderboard
  Future<ApiResponse<Map<String, dynamic>>> getLeaderboard({
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.get(
        '/leaderboard',
        queryParameters: {'limit': limit.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final responseData = data['data'];

          final List<LeaderboardModel> leaderboard =
              (responseData['leaderboard'] as List)
                  .map((json) => LeaderboardModel.fromJson(json))
                  .toList();

          LeaderboardModel? currentUser;
          if (responseData['currentUser'] != null) {
            currentUser = LeaderboardModel.fromJson(
              responseData['currentUser'],
            );
          }

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: {'leaderboard': leaderboard, 'currentUser': currentUser},
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to get leaderboard',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}
