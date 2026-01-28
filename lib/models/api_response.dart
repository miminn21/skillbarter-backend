// Import UserModel
import 'user_model.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<ValidationError>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'] != null
          ? (json['errors'] as List)
                .map((e) => ValidationError.fromJson(e))
                .toList()
          : null,
    );
  }

  // Factory method for success response
  factory ApiResponse.success(T? data, {String message = 'Success'}) {
    return ApiResponse<T>(success: true, message: message, data: data);
  }

  // Factory method for error response
  factory ApiResponse.error(String message, {List<ValidationError>? errors}) {
    return ApiResponse<T>(success: false, message: message, errors: errors);
  }
}

class ValidationError {
  final String field;
  final String message;

  ValidationError({required this.field, required this.message});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class AuthResponse {
  final UserModel user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      token: json['token'] ?? '',
    );
  }
}
