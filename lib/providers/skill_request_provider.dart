import 'package:flutter/foundation.dart';
import '../models/skill_request.dart';
import '../models/match_result.dart';
import '../services/skill_request_service.dart';

class SkillRequestProvider with ChangeNotifier {
  final SkillRequestService _service;

  SkillRequestProvider(this._service);

  List<SkillRequest> _myRequests = [];
  List<SkillRequest> _exploreRequests = [];
  List<MatchResult> _matches = [];
  SkillRequest? _selectedRequest;
  bool _isLoading = false;
  String? _error;

  List<SkillRequest> get myRequests => _myRequests;
  List<SkillRequest> get exploreRequests => _exploreRequests;
  List<MatchResult> get matches => _matches;
  SkillRequest? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyRequests({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myRequests = await _service.getUserRequests(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRequestDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedRequest = await _service.getRequestDetail(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRequest(SkillRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newRequest = await _service.createRequest(request);
      _myRequests.insert(0, newRequest);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRequest(int id, Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedRequest = await _service.updateRequest(id, updates);
      final index = _myRequests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _myRequests[index] = updatedRequest;
      }
      if (_selectedRequest?.id == id) {
        _selectedRequest = updatedRequest;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRequest(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteRequest(id);
      _myRequests.removeWhere((r) => r.id == id);
      if (_selectedRequest?.id == id) {
        _selectedRequest = null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> findMatches(int requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _matches = await _service.findMatches(requestId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExploreRequests({
    int? kategori,
    String? tingkat,
    String? lokasi,
    int limit = 20,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exploreRequests = await _service.exploreRequests(
        kategori: kategori,
        tingkat: tingkat,
        lokasi: lokasi,
        limit: limit,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearMatches() {
    _matches = [];
    notifyListeners();
  }

  void clearSelectedRequest() {
    _selectedRequest = null;
    notifyListeners();
  }
}
