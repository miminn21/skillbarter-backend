import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// Register new user
  Future<ApiResponse<AuthResponse>> register({
    required String nik,
    required String namaLengkap,
    required String namaPanggilan,
    required String kataSandi,
    required String jenisKelamin,
    required String tanggalLahir,
    required String alamatLengkap,
    required String kota,
    String? bio,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/register',
        data: {
          'nik': nik,
          'nama_lengkap': namaLengkap,
          'nama_panggilan': namaPanggilan,
          'kata_sandi': kataSandi,
          'jenis_kelamin': jenisKelamin,
          'tanggal_lahir': tanggalLahir,
          'alamat_lengkap': alamatLengkap,
          'kota': kota,
          'bio': bio,
        },
      );

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );

      // Save token if success
      if (apiResponse.success && apiResponse.data != null) {
        await _apiService.setToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: e.response?.data['message'] ?? 'Registrasi gagal',
        errors: e.response?.data['errors'] != null
            ? (e.response!.data['errors'] as List)
                  .map((e) => ValidationError.fromJson(e))
                  .toList()
            : null,
      );
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Login user
  Future<ApiResponse<AuthResponse>> login({
    required String nik,
    required String kataSandi,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {'nik': nik, 'kata_sandi': kataSandi},
      );

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );

      // Save token if success
      if (apiResponse.success && apiResponse.data != null) {
        await _apiService.setToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: e.response?.data['message'] ?? 'Login gagal',
      );
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Get user profile
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _apiService.get('/auth/profile');

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: e.response?.data['message'] ?? 'Gagal mengambil profile',
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _apiService.post('/auth/logout');

      // Clear token
      await _apiService.clearToken();

      return ApiResponse<void>.fromJson(response.data, null);
    } on DioException catch (e) {
      // Clear token anyway
      await _apiService.clearToken();

      return ApiResponse<void>(
        success: false,
        message: e.response?.data['message'] ?? 'Logout gagal',
      );
    } catch (e) {
      await _apiService.clearToken();

      return ApiResponse<void>(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _apiService.isAuthenticated;
  }

  /// Send heartbeat
  Future<void> heartbeat() async {
    try {
      if (_apiService.isAuthenticated) {
        await _apiService.post('/auth/heartbeat');
      }
    } catch (_) {}
  }

  /// Update Online Status
  Future<void> updateStatus(String status) async {
    try {
      if (_apiService.isAuthenticated) {
        await _apiService.post('/auth/status', data: {'status': status});
      }
    } catch (_) {}
  }
}
