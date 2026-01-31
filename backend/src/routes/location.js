const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');
const auth = require('../middleware/auth');

router.post('/update', auth, locationController.updateLocation);
router.get('/nearby', auth, locationController.getNearbyUsers);

module.exports = router;
