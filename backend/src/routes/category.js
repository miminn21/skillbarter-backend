const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// GET /api/categories - Get all categories
router.get('/', categoryController.getAllCategories);

// GET /api/categories/with-count - Get categories with skill count
router.get('/with-count', categoryController.getCategoriesWithCount);

// GET /api/categories/:id - Get category by ID
router.get('/:id', categoryController.getCategoryById);

module.exports = router;
