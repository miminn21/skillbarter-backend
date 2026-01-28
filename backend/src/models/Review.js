const db = require('../config/database');

class Review {
  // Create a review
  static async create(idBarter, nikReviewer, nikReviewed, rating, komentar = null) {
    const query = `
      INSERT INTO reviews 
        (id_barter, nik_reviewer, nik_reviewed, rating, komentar)
      VALUES (?, ?, ?, ?, ?)
    `;
    
    const [result] = await db.execute(query, [
      idBarter,
      nikReviewer,
      nikReviewed,
      rating,
      komentar
    ]);
    
    return result.insertId;
  }

  // Get reviews for a barter
  static async getByBarter(idBarter) {
    const query = `
      SELECT 
        r.*,
        p.nama_lengkap as nama_reviewer,
        p.foto_profil as foto_reviewer
      FROM reviews r
      JOIN pengguna p ON r.nik_reviewer = p.nik
      WHERE r.id_barter = ?
      ORDER BY r.created_at DESC
    `;
    
    const [rows] = await db.execute(query, [idBarter]);
    return rows;
  }

  // Get reviews received by a user
  static async getByUser(nik, limit = 20, offset = 0) {
    const query = `
      SELECT 
        r.*,
        p.nama_lengkap as nama_reviewer,
        p.foto_profil as foto_reviewer,
        b.id as id_barter,
        b.tanggal_pelaksanaan
      FROM reviews r
      JOIN pengguna p ON r.nik_reviewer = p.nik
      JOIN transaksi_barter b ON r.id_barter = b.id
      WHERE r.nik_reviewed = ?
      ORDER BY r.created_at DESC
      LIMIT ? OFFSET ?
    `;
    
    const [rows] = await db.execute(query, [nik, limit, offset]);
    return rows;
  }

  // Get average rating for a user
  static async getAverageRating(nik) {
    const query = `
      SELECT 
        AVG(rating) as avg_rating,
        COUNT(*) as total_reviews
      FROM reviews
      WHERE nik_reviewed = ?
    `;
    
    const [rows] = await db.execute(query, [nik]);
    return {
      avgRating: rows[0].avg_rating || 0,
      totalReviews: rows[0].total_reviews || 0
    };
  }

  // Check if user has reviewed a barter
  static async hasReviewed(idBarter, nikReviewer) {
    const query = `
      SELECT id_review
      FROM reviews
      WHERE id_barter = ? AND nik_reviewer = ?
    `;
    
    const [rows] = await db.execute(query, [idBarter, nikReviewer]);
    return rows.length > 0;
  }

  // Get rating distribution for a user
  static async getRatingDistribution(nik) {
    const query = `
      SELECT 
        rating,
        COUNT(*) as count
      FROM reviews
      WHERE nik_reviewed = ?
      GROUP BY rating
      ORDER BY rating DESC
    `;
    
    const [rows] = await db.execute(query, [nik]);
    return rows;
  }

  // Delete review (admin only)
  static async delete(idReview) {
    const query = 'DELETE FROM reviews WHERE id_review = ?';
    await db.execute(query, [idReview]);
  }
}

module.exports = Review;
