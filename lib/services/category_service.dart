import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../services/api_service.dart';

class CategoryService {
  final ApiService _apiService = ApiService();
  String get _baseUrl => ApiService.baseUrl;

  CategoryService();

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categoriesJson = data['data'];
        return categoriesJson.map((json) => Category.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Get category detail
  Future<Category> getCategoryDetail(int id) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$_baseUrl/categories/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Category.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch category detail');
      }
    } catch (e) {
      throw Exception('Error fetching category detail: $e');
    }
  }
}
