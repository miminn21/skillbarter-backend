import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/skill_model.dart';
import '../models/api_response.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class SkillService {
  final ApiService _apiService = ApiService();

  /// Get all categories
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    try {
      final response = await _apiService.get('/categories');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<CategoryModel> categories = (data['data'] as List)
              .map((json) => CategoryModel.fromJson(json))
              .toList();

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: categories,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to get categories',
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

  /// Get user's skills
  Future<ApiResponse<List<SkillModel>>> getUserSkills({String? tipe}) async {
    try {
      final queryParams = tipe != null ? {'tipe': tipe} : null;
      final response = await _apiService.get(
        '/skills',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<SkillModel> skills = (data['data'] as List)
              .map((json) => SkillModel.fromJson(json))
              .toList();

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: skills,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to get skills',
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

  /// Get skill detail
  Future<ApiResponse<SkillModel>> getSkillDetail(int id) async {
    try {
      final response = await _apiService.get('/skills/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final skill = SkillModel.fromJson(data['data']);

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: skill,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to get skill detail',
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

  /// Add new skill
  Future<ApiResponse<SkillModel>> addSkill(
    Map<String, dynamic> skillData, {
    XFile? imageFile,
  }) async {
    try {
      print('[SkillService] Sending request to /skills');
      print('[SkillService] Data: $skillData');
      if (imageFile != null) {
        print('[SkillService] Image: ${imageFile.name}');
      }

      dynamic data;

      if (imageFile != null) {
        // Create FormData for multipart request
        final map = <String, dynamic>{};
        skillData.forEach((key, value) {
          map[key] = value.toString(); // Convert all to string for FormData
        });

        // Add file
        final bytes = await imageFile.readAsBytes();
        map['gambar_skill'] = MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );

        data = FormData.fromMap(map);
      } else {
        data = skillData;
      }

      final response = await _apiService.post('/skills', data: data);

      print('[SkillService] Response status: ${response.statusCode}');
      print('[SkillService] Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final skill = SkillModel.fromJson(data['data']);

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: skill,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to add skill',
      );
    } on DioException catch (e) {
      print('[SkillService] DioException caught!');
      print('[SkillService] Error type: ${e.type}');
      print('[SkillService] Error message: ${e.message}');
      print('[SkillService] Response status: ${e.response?.statusCode}');
      print('[SkillService] Response data: ${e.response?.data}');

      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
        errors: e.response?.data['errors'] != null
            ? (e.response!.data['errors'] as List)
                  .map((e) => ValidationError.fromJson(e))
                  .toList()
            : null,
      );
    } catch (e) {
      print('[SkillService] General exception: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Update skill
  Future<ApiResponse<SkillModel>> updateSkill(
    int id,
    Map<String, dynamic> skillData, {
    XFile? imageFile,
  }) async {
    try {
      print('[SkillService] Sending request to PUT /skills/$id');
      print('[SkillService] Data: $skillData');

      dynamic data;

      if (imageFile != null) {
        // Create FormData for multipart request
        final map = <String, dynamic>{};
        skillData.forEach((key, value) {
          if (value != null) {
            map[key] = value.toString();
          }
        });

        // Add file (Compatible with Web)
        final bytes = await imageFile.readAsBytes();
        map['gambar_skill'] = MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );

        data = FormData.fromMap(map);
      } else {
        data = skillData;
      }

      final response = await _apiService.put('/skills/$id', data: data);

      print('[SkillService] Response status: ${response.statusCode}');
      print('[SkillService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final skill = SkillModel.fromJson(data['data']);

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: skill,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update skill',
      );
    } on DioException catch (e) {
      print('[SkillService] DioException caught!');
      print('[SkillService] Response status: ${e.response?.statusCode}');
      print('[SkillService] Response data: ${e.response?.data}');

      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
        errors: e.response?.data['errors'] != null
            ? (e.response!.data['errors'] as List)
                  .map((e) => ValidationError.fromJson(e))
                  .toList()
            : null,
      );
    } catch (e) {
      print('[SkillService] Unexpected error: $e');
      return ApiResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Delete skill
  Future<ApiResponse<void>> deleteSkill(int id) async {
    try {
      final response = await _apiService.delete('/skills/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        return ApiResponse(
          success: data['success'] ?? false,
          message: data['message'] ?? 'Success',
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete skill',
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

  /// Upload portfolio image
  Future<ApiResponse<SkillModel>> uploadPortfolio(
    int id,
    String filePath,
  ) async {
    try {
      print('[SkillService] Uploading portfolio for skill $id');
      print('[SkillService] File path: $filePath');

      // Read file as bytes (works on all platforms)
      final file = XFile(filePath);
      final bytes = await file.readAsBytes();

      print('[SkillService] File name: ${file.name}');
      print('[SkillService] File size: ${bytes.length} bytes');

      // Create FormData with MultipartFile.fromBytes
      final formData = FormData.fromMap({
        'portfolio': MultipartFile.fromBytes(bytes, filename: file.name),
      });

      print('[SkillService] FormData created, sending request...');

      final response = await _apiService.post(
        '/skills/$id/upload-portfolio',
        data: formData,
      );

      print('[SkillService] Response status: ${response.statusCode}');
      print('[SkillService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final skill = SkillModel.fromJson(data['data']);

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: skill,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to upload portfolio',
      );
    } on DioException catch (e) {
      print('[SkillService] DioException caught!');
      print('[SkillService] Error type: ${e.type}');
      print('[SkillService] Response status: ${e.response?.statusCode}');
      print('[SkillService] Response data: ${e.response?.data}');

      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Network error',
      );
    } catch (e) {
      print('[SkillService] General exception: $e');
      return ApiResponse(success: false, message: e.toString());
    }
  }

  /// Verify skill (costs 10 skillcoin)
  Future<ApiResponse<SkillModel>> verifySkill(int id) async {
    try {
      final response = await _apiService.post('/skills/$id/verify');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final skill = SkillModel.fromJson(data['data']);

          return ApiResponse(
            success: true,
            message: data['message'] ?? 'Success',
            data: skill,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to verify skill',
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
