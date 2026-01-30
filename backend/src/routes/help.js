const express = require('express');
const router = express.Router();
const helpController = require('../controllers/helpController');
const { authenticate } = require('../middleware/auth');
const multer = require('multer');

// Memory storage for blob
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  }
});

router.post('/submit', authenticate, upload.single('bukti'), helpController.submitReport);
router.get('/history', authenticate, helpController.getHistory);

module.exports = router;
