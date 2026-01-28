const express = require('express');
const router = express.Router();
const barterController = require('../controllers/barterController');
const barterProofController = require('../controllers/barterProofController');
const ratingController = require('../controllers/ratingController');
const { authenticate } = require('../middleware/auth');

/**
 * Barter Routes
 * All routes require authentication
 */

// Create new barter offer
router.post('/offers', authenticate, barterController.createOffer);

// Get user's offers (sent/received)
router.get('/offers', authenticate, barterController.getUserOffers);

// Get offer detail
router.get('/offers/:id', authenticate, barterController.getOfferDetail);

// Accept offer
router.put('/offers/:id/accept', authenticate, barterController.acceptOffer);

// Reject offer
router.put('/offers/:id/reject', authenticate, barterController.rejectOffer);

// Cancel offer
router.put('/offers/:id/cancel', authenticate, barterController.cancelOffer);

// Delete offer (permanent)
router.delete('/offers/:id', authenticate, barterController.deleteOffer);

// Start barter session
router.put('/offers/:id/start', authenticate, barterController.startSession);

// Complete barter session
router.put('/offers/:id/complete', authenticate, barterController.completeSession);

// Confirm completion and transfer skillcoin
router.put('/offers/:id/confirm', authenticate, barterController.confirmCompletion);

// Rating routes
router.post('/offers/:id/rate', authenticate, ratingController.submitRating);
router.get('/offers/:id/ratings', authenticate, ratingController.getBarterRatings);
router.get('/offers/:id/my-rating', authenticate, ratingController.checkMyRating);

// Get transaction history
router.get('/history', authenticate, barterController.getHistory);

// Get skillcoin balance
router.get('/skillcoin/balance', authenticate, barterController.getSkillcoinBalance);

// Get skillcoin transaction history
router.get('/skillcoin/history', authenticate, barterController.getSkillcoinHistory);

// Upload proof of completion
router.post('/offers/:id/upload-proof', authenticate, barterController.uploadProof);

// Get proof of completion
router.get('/offers/:id/proof', authenticate, barterController.getProof);

// Upload proof photo
router.put('/:id/upload-proof', authenticate, barterProofController.uploadProof);

// Get confirmations
router.get('/:id/confirmations', authenticate, barterProofController.getConfirmations);

module.exports = router;
