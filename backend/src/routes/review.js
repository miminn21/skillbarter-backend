const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// Create a review
router.post('/', reviewController.createReview);

// Get reviews for a barter
router.get('/barter/:barterId', reviewController.getBarterReviews);

// Get reviews for a user
router.get('/user/:nik', reviewController.getUserReviews);

// Get my reviews (reviews I received)
router.get('/my-reviews', reviewController.getMyReviews);

// Delete review (admin only)
router.delete('/:id', reviewController.deleteReview);

module.exports = router;
