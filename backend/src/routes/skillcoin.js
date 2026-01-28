const express = require('express');
const router = express.Router();
const skillcoinController = require('../controllers/skillcoinController');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// Get transaction history
router.get('/history', skillcoinController.getHistory);

// Get current balance
router.get('/balance', skillcoinController.getBalance);

// Get transaction stats
router.get('/stats', skillcoinController.getStats);

// Manual transfer
router.post('/transfer', skillcoinController.transfer);

// Admin adjustment
router.post('/adjust', skillcoinController.adjust);

module.exports = router;
