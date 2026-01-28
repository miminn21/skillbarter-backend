const db = require('../config/database');

class Recommendation {
  /**
   * Get personalized skill recommendations with scoring
   * Uses improved view: rekomendasi_pencocokan with skor_kecocokan
   */
  static async getRecommendations(nik) {
    const query = `
      SELECT 
        pengguna_a,
        pengguna_b,
        keahlian_ditawarkan,
        keahlian_dicari,
        nama_kategori,
        nama_a,
        nama_b,
        kota_a,
        kota_b,
        rating_a,
        rating_b,
        selisih_rating,
        skor_kecocokan,
        verifikasi_a,
        verifikasi_b,
        tingkat_a,
        tingkat_b
      FROM rekomendasi_pencocokan
      WHERE pengguna_a = ? OR pengguna_b = ?
      ORDER BY skor_kecocokan DESC, selisih_rating ASC
      LIMIT 20
    `;

    const [recommendations] = await db.query(query, [nik, nik]);
    return recommendations;
  }

  /**
   * Get matching skills for a specific user (what they can offer)
   */
  static async getMatchingSkills(nik) {
    const query = `
      SELECT 
        pengguna_b AS matched_user_nik,
        nama_b AS matched_user_name,
        keahlian_dicari AS skill_needed,
        keahlian_ditawarkan AS skill_offered,
        skor_kecocokan AS match_score,
        kota_b AS user_city,
        rating_b AS user_rating,
        tingkat_b AS skill_level
      FROM rekomendasi_pencocokan
      WHERE pengguna_a = ?
      ORDER BY skor_kecocokan DESC
      LIMIT 10
    `;

    const [matches] = await db.query(query, [nik]);
    return matches;
  }
}

module.exports = Recommendation;
