const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { validate, registerSchema, loginSchema } = require('../utils/validator');
const { authenticate } = require('../middleware/auth');

/**
 * Auth Routes
 */

// Public routes
router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);

// Protected routes
router.get('/profile', authenticate, authController.getProfile);
router.post('/logout', authenticate, authController.logout);
router.post('/heartbeat', authenticate, authController.heartbeat);
router.post('/status', authenticate, authController.updateStatus);

module.exports = router;
