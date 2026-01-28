const express = require('express');
const router = express.Router();
const exploreController = require('../controllers/exploreController');
const { authenticate } = require('../middleware/auth');

/**
 * Explore Routes
 */

// Explore skills (public)
router.get('/explore', exploreController.exploreSkills);

// Get recommendations (protected)
router.get('/recommendations', authenticate, exploreController.getRecommendations);

// Get user public profile
router.get('/users/:nik', exploreController.getUserProfile);

// Get leaderboard (optional auth for current user position)
router.get('/leaderboard', exploreController.getLeaderboard);

module.exports = router;
