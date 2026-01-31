const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');
const { authenticate } = require('../middleware/auth');

router.post('/update', authenticate, locationController.updateLocation);
router.get('/nearby', authenticate, locationController.getNearbyUsers);

module.exports = router;
