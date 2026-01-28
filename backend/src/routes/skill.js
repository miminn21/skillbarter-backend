const express = require('express');
const router = express.Router();
const skillController = require('../controllers/skillController');
const { authenticate } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { validate, addSkillSchema, updateSkillSchema } = require('../utils/validator');

/**
 * Skill Routes
 */

// Get all categories
router.get('/categories', skillController.getCategories);

// Get user's skills (protected)
router.get('/skills', authenticate, skillController.getUserSkills);

// Get skill detail
router.get('/skills/:id', skillController.getSkillDetail);

// Add new skill (protected)
router.post(
  '/skills',
  authenticate,
  upload.single('gambar_skill'),
  validate(addSkillSchema),
  skillController.addSkill
);

// Update skill (protected)
router.put(
  '/skills/:id',
  authenticate,
  upload.single('gambar_skill'),
  validate(updateSkillSchema),
  skillController.updateSkill
);

// Delete skill (protected)
router.delete('/skills/:id', authenticate, skillController.deleteSkill);

// Upload portfolio image (protected)
router.post(
  '/skills/:id/upload-portfolio',
  authenticate,
  upload.single('portfolio'),
  skillController.uploadPortfolio
);

// Verify skill (protected)
router.post('/skills/:id/verify', authenticate, skillController.verifySkill);

/**
 * Skill Request Routes
 */

// Get user's skill requests (protected)
router.get('/skills/requests', authenticate, skillController.getUserSkillRequests);

// Explore open skill requests
router.get('/skills/requests/explore', authenticate, skillController.exploreSkillRequests);

// Get skill request detail
router.get('/skills/requests/:id', authenticate, skillController.getSkillRequestDetail);

// Create new skill request (protected)
router.post('/skills/requests', authenticate, skillController.createSkillRequest);

// Update skill request (protected)
router.put('/skills/requests/:id', authenticate, skillController.updateSkillRequest);

// Delete skill request (protected)
router.delete('/skills/requests/:id', authenticate, skillController.deleteSkillRequest);

// Find matches for skill request (protected)
router.get('/skills/requests/:id/matches', authenticate, skillController.findMatches);

module.exports = router;
