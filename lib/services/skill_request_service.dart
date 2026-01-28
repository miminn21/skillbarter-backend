import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/skill_request.dart';
import '../models/match_result.dart';
import '../services/api_service.dart';

class SkillRequestService {
  final ApiService _apiService = ApiService();
  String get _baseUrl => ApiService.baseUrl;

  SkillRequestService();

  // Get user's skill requests
  Future<List<SkillRequest>> getUserRequests({String? status}) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      var url = '${_baseUrl}/skills/requests';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> requestsJson = data['data'];
        return requestsJson.map((json) => SkillRequest.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch requests');
      }
    } catch (e) {
      throw Exception('Error fetching skill requests: $e');
    }
  }

  // Get skill request detail
  Future<SkillRequest> getRequestDetail(int id) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${_baseUrl}/skills/requests/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SkillRequest.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch request detail');
      }
    } catch (e) {
      throw Exception('Error fetching request detail: $e');
    }
  }

  // Create skill request
  Future<SkillRequest> createRequest(SkillRequest request) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('${_baseUrl}/skills/requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return SkillRequest.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create request');
      }
    } catch (e) {
      throw Exception('Error creating skill request: $e');
    }
  }

  // Update skill request
  Future<SkillRequest> updateRequest(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${_baseUrl}/skills/requests/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SkillRequest.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update request');
      }
    } catch (e) {
      throw Exception('Error updating skill request: $e');
    }
  }

  // Delete skill request
  Future<void> deleteRequest(int id) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('${_baseUrl}/skills/requests/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete request');
      }
    } catch (e) {
      throw Exception('Error deleting skill request: $e');
    }
  }

  // Find matches for skill request
  Future<List<MatchResult>> findMatches(int requestId) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${_baseUrl}/skills/requests/$requestId/matches'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> matchesJson = data['data']['matches'];
        return matchesJson.map((json) => MatchResult.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to find matches');
      }
    } catch (e) {
      throw Exception('Error finding matches: $e');
    }
  }

  // Explore open skill requests
  Future<List<SkillRequest>> exploreRequests({
    int? kategori,
    String? tingkat,
    String? lokasi,
    int limit = 20,
  }) async {
    try {
      final token = _apiService.token;
      if (token == null) throw Exception('Not authenticated');

      var url = '${_baseUrl}/skills/requests/explore?limit=$limit';
      if (kategori != null) url += '&kategori=$kategori';
      if (tingkat != null) url += '&tingkat=$tingkat';
      if (lokasi != null) url += '&lokasi=$lokasi';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> requestsJson = data['data'];
        return requestsJson.map((json) => SkillRequest.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to explore requests');
      }
    } catch (e) {
      throw Exception('Error exploring requests: $e');
    }
  }
}
