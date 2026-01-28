const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { validate, updateProfileSchema, changePasswordSchema } = require('../utils/validator');
const { authenticate } = require('../middleware/auth');
const upload = require('../middleware/upload');

/**
 * Profile Routes (All protected)
 */

router.put('/', authenticate, validate(updateProfileSchema), profileController.updateProfile);
router.put('/change-password', authenticate, validate(changePasswordSchema), profileController.changePassword);
router.post('/upload-photo', authenticate, upload.single('foto_profil'), profileController.uploadPhoto);
router.post('/upload-photo-base64', authenticate, profileController.uploadPhotoBase64);

module.exports = router;
