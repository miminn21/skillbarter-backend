import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _service;

  CategoryProvider(this._service);

  // State
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _service.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch category detail
  Future<void> fetchCategoryDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedCategory = await _service.getCategoryDetail(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selected category
  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }
}
