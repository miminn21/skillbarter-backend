import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _apiService = ApiService();

  /// Update user profile
  Future<ApiResponse<UserModel>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put('/profile', data: data);

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: e.response?.data['message'] ?? 'Gagal memperbarui profile',
        errors: e.response?.data['errors'] != null
            ? (e.response!.data['errors'] as List)
                  .map((e) => ValidationError.fromJson(e))
                  .toList()
            : null,
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Change password
  Future<ApiResponse<void>> changePassword({
    required String kataSandiLama,
    required String kataSandiBaru,
    required String konfirmasiKataSandi,
  }) async {
    try {
      final response = await _apiService.put(
        '/profile/change-password',
        data: {
          'kata_sandi_lama': kataSandiLama,
          'kata_sandi_baru': kataSandiBaru,
          'konfirmasi_kata_sandi': konfirmasiKataSandi,
        },
      );

      return ApiResponse<void>.fromJson(response.data, null);
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        message: e.response?.data['message'] ?? 'Gagal mengubah password',
        errors: e.response?.data['errors'] != null
            ? (e.response!.data['errors'] as List)
                  .map((e) => ValidationError.fromJson(e))
                  .toList()
            : null,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  /// Upload profile photo using base64 (cross-platform)
  Future<ApiResponse<UserModel>> uploadPhoto(XFile imageFile) async {
    try {
      // Read file as bytes using XFile (works on all platforms)
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final extension = imageFile.path.split('.').last.toLowerCase();

      final response = await _apiService.post(
        '/profile/upload-photo-base64',
        data: {'foto_profil': base64Image, 'jenis_foto': extension},
      );

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } on DioException catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: e.response?.data['message'] ?? 'Gagal mengupload foto',
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }
}
