const Category = require('../models/Category');
const { success, error, notFound } = require('../utils/response');

/**
 * Get all categories
 */
exports.getAllCategories = async (req, res) => {
  try {
    const categories = await Category.findAll();
    return success(res, 'Categories retrieved successfully', categories);
  } catch (err) {
    console.error('Get categories error:', err);
    return error(res, 'Failed to retrieve categories', 500);
  }
};

/**
 * Get category by ID
 */
exports.getCategoryById = async (req, res) => {
  try {
    const { id } = req.params;
    const category = await Category.findById(id);

    if (!category) {
      return notFound(res, 'Category not found');
    }

    return success(res, 'Category retrieved successfully', category);
  } catch (err) {
    console.error('Get category error:', err);
    return error(res, 'Failed to retrieve category', 500);
  }
};

/**
 * Get categories with skill count
 */
exports.getCategoriesWithCount = async (req, res) => {
  try {
    const categories = await Category.findAllWithCount();
    return success(res, 'Categories with count retrieved successfully', categories);
  } catch (err) {
    console.error('Get categories with count error:', err);
    return error(res, 'Failed to retrieve categories', 500);
  }
};
