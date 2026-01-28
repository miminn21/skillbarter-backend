import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/skill_model.dart';
import '../services/skill_service.dart';
import 'package:image_picker/image_picker.dart';

class SkillProvider with ChangeNotifier {
  final SkillService _skillService = SkillService();

  List<CategoryModel> _categories = [];
  List<SkillModel> _dikuasaiSkills = [];
  List<SkillModel> _dicariSkills = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  List<SkillModel> get dikuasaiSkills => _dikuasaiSkills;
  List<SkillModel> get dicariSkills => _dicariSkills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load categories
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _skillService.getCategories();

      if (response.success && response.data != null) {
        _categories = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load user skills
  Future<void> loadUserSkills({String? tipe}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _skillService.getUserSkills(tipe: tipe);

      if (response.success && response.data != null) {
        if (tipe == 'dikuasai') {
          _dikuasaiSkills = response.data!;
        } else if (tipe == 'dicari') {
          _dicariSkills = response.data!;
        } else {
          // Load both
          _dikuasaiSkills = response.data!
              .where((s) => s.tipe == 'dikuasai')
              .toList();
          _dicariSkills = response.data!
              .where((s) => s.tipe == 'dicari')
              .toList();
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

  /// Add new skill
  Future<bool> addSkill(
    Map<String, dynamic> skillData, {
    XFile? imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _skillService.addSkill(
        skillData,
        imageFile: imageFile,
      );

      if (response.success && response.data != null) {
        // Add to appropriate list
        if (response.data!.tipe == 'dikuasai') {
          _dikuasaiSkills.insert(0, response.data!);
        } else {
          _dicariSkills.insert(0, response.data!);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update skill
  Future<bool> updateSkill(
    int id,
    Map<String, dynamic> skillData, {
    XFile? imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _skillService.updateSkill(
        id,
        skillData,
        imageFile: imageFile,
      );

      if (response.success && response.data != null) {
        // Update in list
        final index = _dikuasaiSkills.indexWhere((s) => s.id == id);
        if (index != -1) {
          _dikuasaiSkills[index] = response.data!;
        } else {
          final index2 = _dicariSkills.indexWhere((s) => s.id == id);
          if (index2 != -1) {
            _dicariSkills[index2] = response.data!;
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete skill
  Future<bool> deleteSkill(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _skillService.deleteSkill(id);

      if (response.success) {
        // Remove from list
        _dikuasaiSkills.removeWhere((s) => s.id == id);
        _dicariSkills.removeWhere((s) => s.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload portfolio
  Future<bool> uploadPortfolio(int id, String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _skillService.uploadPortfolio(id, filePath);

      if (response.success && response.data != null) {
        // Update in list
        final index = _dikuasaiSkills.indexWhere((s) => s.id == id);
        if (index != -1) {
          _dikuasaiSkills[index] = response.data!;
        } else {
          final index2 = _dicariSkills.indexWhere((s) => s.id == id);
          if (index2 != -1) {
            _dicariSkills[index2] = response.data!;
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
