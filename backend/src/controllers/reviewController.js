const Review = require('../models/Review');
const Barter = require('../models/Barter');
const { notifyReviewReceived } = require('../helpers/notificationHelper');

// Create a review
exports.createReview = async (req, res) => {
  try {
    const { id_barter, rating, komentar } = req.body;
    const nik_reviewer = req.user.nik;

    // Validate input
    if (!id_barter || !rating) {
      return res.status(400).json({
        success: false,
        message: 'ID barter dan rating wajib diisi'
      });
    }

    if (rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating harus antara 1-5'
      });
    }

    // Get barter details
    const barter = await Barter.findById(id_barter);
    if (!barter) {
      return res.status(404).json({
        success: false,
        message: 'Barter tidak ditemukan'
      });
    }

    // Check if barter is completed
    if (barter.status !== 'selesai') {
      return res.status(400).json({
        success: false,
        message: 'Barter belum selesai'
      });
    }

    // Check if user is part of the barter
    if (barter.nik_penawar !== nik_reviewer && barter.nik_ditawar !== nik_reviewer) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak terlibat dalam barter ini'
      });
    }

    // Determine who is being reviewed
    const nik_reviewed = barter.nik_penawar === nik_reviewer 
      ? barter.nik_ditawar 
      : barter.nik_penawar;

    // Check if already reviewed
    const hasReviewed = await Review.hasReviewed(id_barter, nik_reviewer);
    if (hasReviewed) {
      return res.status(400).json({
        success: false,
        message: 'Anda sudah memberi review untuk barter ini'
      });
    }

    // Create review
    const reviewId = await Review.create(
      id_barter,
      nik_reviewer,
      nik_reviewed,
      rating,
      komentar
    );

    // Send notification
    await notifyReviewReceived(
      { id_review: reviewId, id_barter, rating, nik_reviewed },
      req.user.nama_lengkap
    );

    res.status(201).json({
      success: true,
      message: 'Review berhasil dibuat',
      data: { id_review: reviewId }
    });
  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal membuat review',
      error: error.message
    });
  }
};

// Get reviews for a barter
exports.getBarterReviews = async (req, res) => {
  try {
    const { barterId } = req.params;
    const reviews = await Review.getByBarter(barterId);

    res.json({
      success: true,
      data: reviews
    });
  } catch (error) {
    console.error('Error getting barter reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil review',
      error: error.message
    });
  }
};

// Get reviews for a user
exports.getUserReviews = async (req, res) => {
  try {
    const { nik } = req.params;
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    const reviews = await Review.getByUser(nik, limit, offset);
    const stats = await Review.getAverageRating(nik);
    const distribution = await Review.getRatingDistribution(nik);

    res.json({
      success: true,
      data: {
        reviews,
        stats,
        distribution
      }
    });
  } catch (error) {
    console.error('Error getting user reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil review pengguna',
      error: error.message
    });
  }
};

// Get my reviews (reviews I received)
exports.getMyReviews = async (req, res) => {
  try {
    const nik = req.user.nik;
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    const reviews = await Review.getByUser(nik, limit, offset);
    const stats = await Review.getAverageRating(nik);

    res.json({
      success: true,
      data: {
        reviews,
        stats
      }
    });
  } catch (error) {
    console.error('Error getting my reviews:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil review Anda',
      error: error.message
    });
  }
};

// Delete review (admin only)
exports.deleteReview = async (req, res) => {
  try {
    if (!req.user.is_admin) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak'
      });
    }

    const { id } = req.params;
    await Review.delete(id);

    res.json({
      success: true,
      message: 'Review berhasil dihapus'
    });
  } catch (error) {
    console.error('Error deleting review:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menghapus review',
      error: error.message
    });
  }
};

module.exports = exports;
