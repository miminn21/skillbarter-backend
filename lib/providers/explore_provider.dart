import 'package:flutter/material.dart';
import '../models/skill_model.dart';
import '../models/user_public_model.dart';
import '../models/leaderboard_model.dart';
import '../models/explore_filter_model.dart';
import '../services/explore_service.dart';

class ExploreProvider with ChangeNotifier {
  final ExploreService _exploreService = ExploreService();

  // Explore skills
  List<SkillModel> _exploreSkills = [];
  Map<String, dynamic>? _pagination;
  ExploreFilterModel _currentFilter = ExploreFilterModel();

  // Recommendations
  List<SkillModel> _recommendations = [];

  // Leaderboard
  List<LeaderboardModel> _leaderboard = [];
  LeaderboardModel? _currentUserRank;

  // Loading & Error states
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Getters
  List<SkillModel> get exploreSkills => _exploreSkills;
  Map<String, dynamic>? get pagination => _pagination;
  ExploreFilterModel get currentFilter => _currentFilter;
  List<SkillModel> get recommendations => _recommendations;
  List<LeaderboardModel> get leaderboard => _leaderboard;
  LeaderboardModel? get currentUserRank => _currentUserRank;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  bool get hasMore {
    if (_pagination == null) return false;
    final currentPage = _pagination!['page'] as int;
    final totalPages = _pagination!['totalPages'] as int;
    return currentPage < totalPages;
  }

  /// Load explore skills
  Future<void> loadExploreSkills({bool refresh = false}) async {
    if (refresh) {
      _currentFilter = _currentFilter.copyWith(page: 1);
      _exploreSkills.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _exploreService.exploreSkills(_currentFilter);

      if (response.success && response.data != null) {
        final skills = response.data!['skills'] as List<SkillModel>;
        _pagination = response.data!['pagination'];

        if (refresh) {
          _exploreSkills = skills;
        } else {
          _exploreSkills.addAll(skills);
        }
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load more skills (pagination)
  Future<void> loadMoreSkills() async {
    if (!hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = (_pagination!['page'] as int) + 1;
      _currentFilter = _currentFilter.copyWith(page: nextPage);

      final response = await _exploreService.exploreSkills(_currentFilter);

      if (response.success && response.data != null) {
        final skills = response.data!['skills'] as List<SkillModel>;
        _pagination = response.data!['pagination'];
        _exploreSkills.addAll(skills);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Apply filter
  Future<void> applyFilter(ExploreFilterModel filter) async {
    _currentFilter = filter.copyWith(page: 1);
    await loadExploreSkills(refresh: true);
  }

  /// Search skills
  Future<void> searchSkills(String query) async {
    _currentFilter = _currentFilter.copyWith(searchQuery: query, page: 1);
    await loadExploreSkills(refresh: true);
  }

  /// Clear filter
  Future<void> clearFilter() async {
    _currentFilter = ExploreFilterModel();
    await loadExploreSkills(refresh: true);
  }

  /// Load recommendations
  Future<void> loadRecommendations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _exploreService.getRecommendations();

      if (response.success && response.data != null) {
        _recommendations = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load leaderboard
  Future<void> loadLeaderboard({int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _exploreService.getLeaderboard(limit: limit);

      if (response.success && response.data != null) {
        _leaderboard = response.data!['leaderboard'] as List<LeaderboardModel>;
        _currentUserRank = response.data!['currentUser'] as LeaderboardModel?;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get user public profile
  Future<UserPublicModel?> getUserProfile(String nik) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _exploreService.getUserProfile(nik);

      if (response.success && response.data != null) {
        _isLoading = false;
        notifyListeners();
        return response.data;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
