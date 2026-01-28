const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { authenticate } = require('../middleware/auth'); // Check authentication

router.post('/send', authenticate, chatController.sendMessage);
router.get('/history/:transactionId', authenticate, chatController.getHistory);

module.exports = router;
