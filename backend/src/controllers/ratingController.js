const db = require('../config/database');
const { notifyReviewReceived } = require('../helpers/notificationHelper');

/**
 * Submit rating for completed barter
 * POST /api/barter/:id/rate
 */
exports.submitRating = async (req, res) => {
  const { id } = req.params;
  const { rating, komentar, anonim } = req.body;
  const userNik = req.user.nik;

  try {
    // Validate rating
    if (!rating || rating < 1 || rating > 5) {
      console.log(`[Rating Error] Invalid rating value: ${rating}`);
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    // Get barter details
    const [barterRows] = await db.execute(
      'SELECT nik_penawar, nik_ditawar, status FROM transaksi_barter WHERE id = ?',
      [id]
    );

    if (barterRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Barter not found'
      });
    }

    const barter = barterRows[0];
    console.log(`[Rating Debug] Barter Status: ${barter.status}`);

    // Check if barter is completed
    if (barter.status !== 'terkonfirmasi' && barter.status !== 'selesai') {
      console.log(`[Rating Error] Invalid status: ${barter.status}`);
      return res.status(400).json({
        success: false,
        message: 'Can only rate completed barters'
      });
    }

    // Check if user is part of this barter
    if (barter.nik_penawar !== userNik && barter.nik_ditawar !== userNik) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to rate this barter'
      });
    }

    // Determine who to rate (the other party) and role
    const nikDiulas = barter.nik_penawar === userNik ? barter.nik_ditawar : barter.nik_penawar;
    const peran = barter.nik_penawar === userNik ? 'murid' : 'pengajar';

    // Check if already rated
    const [existingRating] = await db.execute(
      'SELECT id FROM ulasan_dan_rating WHERE id_transaksi = ? AND nik_pemberi_ulasan = ?',
      [id, userNik]
    );

    if (existingRating.length > 0) {
      console.log(`[Rating Error] User ${userNik} already rated barter ${id}`);
      return res.status(400).json({
        success: false,
        message: 'You have already rated this barter'
      });
    }

    // Insert rating
    await db.execute(
      `INSERT INTO ulasan_dan_rating (id_transaksi, nik_pemberi_ulasan, nik_diulas, rating, komentar, peran, anonim) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [id, userNik, nikDiulas, rating, komentar || null, peran, anonim ? 1 : 0]
    );

    // Update average rating for the rated user
    const [avgResult] = await db.execute(
      'SELECT AVG(rating) as avg_rating FROM ulasan_dan_rating WHERE nik_diulas = ?',
      [nikDiulas]
    );

    const avgRating = avgResult[0].avg_rating || 0;

    await db.execute(
      'UPDATE pengguna SET rating_rata_rata = ? WHERE nik = ?',
      [avgRating, nikDiulas]
    );

    console.log(`[Rating] User ${userNik} rated ${nikDiulas} with ${rating} stars`);
    console.log(`[Rating] Updated average rating for ${nikDiulas}: ${avgRating}`);

    // Send notification to rated user
    const [reviewerInfo] = await db.execute(
      'SELECT nama_lengkap FROM pengguna WHERE nik = ?',
      [userNik]
    );
    const namaReviewer = reviewerInfo[0]?.nama_lengkap || 'Someone';
    
    await notifyReviewReceived(
      {
        id_review: null, // We don't have the ID yet, but it's not critical
        id_barter: id,
        rating: rating,
        nik_reviewed: nikDiulas
      },
      namaReviewer
    );

    res.json({
      success: true,
      message: 'Rating submitted successfully',
      data: {
        rating,
        avgRating: parseFloat(Number(avgRating).toFixed(2))
      }
    });

  } catch (error) {
    console.error('[Rating] Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit rating',
      error: error.message
    });
  }
};

/**
 * Get ratings for a barter
 * GET /api/barter/:id/ratings
 */
exports.getBarterRatings = async (req, res) => {
  const { id } = req.params;

  try {
    const [ratings] = await db.execute(
      `SELECT 
        u.*,
        p.nama_lengkap as nama_pemberi_ulasan
       FROM ulasan_dan_rating u
       JOIN pengguna p ON u.nik_pemberi_ulasan = p.nik
       WHERE u.id_transaksi = ?
       ORDER BY u.dibuat_pada DESC`,
      [id]
    );

    res.json({
      success: true,
      data: ratings
    });

  } catch (error) {
    console.error('[Rating] Error getting ratings:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get ratings',
      error: error.message
    });
  }
};

/**
 * Check if user has rated a barter
 * GET /api/barter/:id/my-rating
 */
exports.checkMyRating = async (req, res) => {
  const { id } = req.params;
  const userNik = req.user.nik;

  try {
    const [rating] = await db.execute(
      'SELECT * FROM ulasan_dan_rating WHERE id_transaksi = ? AND nik_pemberi_ulasan = ?',
      [id, userNik]
    );

    res.json({
      success: true,
      data: {
        hasRated: rating.length > 0,
        rating: rating.length > 0 ? rating[0] : null
      }
    });

  } catch (error) {
    console.error('[Rating] Error checking rating:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check rating',
      error: error.message
    });
  }
};
