const db = require('../config/database');

/**
 * Matching Service
 * Intelligent algorithm to match users based on skill requests
 */

class MatchingService {
  /**
   * Find matches for a skill request
   * @param {string} userNik - NIK of user requesting skill
   * @param {number} requestId - ID of skill request
   * @returns {Array} Top 10 matched users
   */
  static async findMatches(userNik, requestId) {
    try {
      // 1. Get skill request details
      const [requests] = await db.execute(
        `SELECT sr.*, sc.nama_kategori 
         FROM skill_requests sr
         JOIN skill_categories sc ON sr.id_kategori = sc.id
         WHERE sr.id = ? AND sr.nik_pengguna = ?`,
        [requestId, userNik]
      );

      if (requests.length === 0) {
        throw new Error('Skill request tidak ditemukan');
      }

      const request = requests[0];

      // 2. Get requester's offered skills (for mutual benefit check)
      const [requesterSkills] = await db.execute(
        `SELECT id_kategori, nama_keahlian 
         FROM skills 
         WHERE nik_pengguna = ? AND tipe = 'dikuasai' AND status_aktif = 1`,
        [userNik]
      );

      // 3. Find potential matches
      const [potentialMatches] = await db.execute(
        `SELECT DISTINCT
          s.nik_pengguna,
          p.nama_lengkap,
          p.foto_profil,
          p.lokasi,
          p.trust_score,
          s.id as skill_id,
          s.nama_keahlian,
          s.tingkat_keahlian,
          s.status_verifikasi,
          s.rating_rata_rata,
          s.jumlah_ulasan,
          (
            SELECT COUNT(*) 
            FROM skills 
            WHERE nik_pengguna = s.nik_pengguna 
            AND tipe = 'dikuasai' 
            AND status_aktif = 1
          ) as total_skills,
          (
            SELECT COUNT(*) 
            FROM barter_sessions bs
            JOIN barter_offers bo ON bs.id_penawaran = bo.id
            WHERE (bo.nik_penawar = s.nik_pengguna OR bo.nik_penerima = s.nik_pengguna)
            AND bs.status = 'selesai'
          ) as completed_sessions
        FROM skills s
        JOIN pengguna p ON s.nik_pengguna = p.nik
        WHERE s.id_kategori = ?
        AND s.tipe = 'dikuasai'
        AND s.status_aktif = 1
        AND s.nik_pengguna != ?
        AND p.status_akun = 'aktif'
        AND p.trust_score >= 3.0`,
        [request.id_kategori, userNik]
      );

      // 4. Calculate scores for each match
      const scoredMatches = await Promise.all(
        potentialMatches.map(async (match) => {
          const scores = await this.calculateMatchScore(
            match,
            request,
            requesterSkills,
            userNik
          );
          
          return {
            ...match,
            ...scores,
            total_score: scores.mutual_benefit_score * 0.4 +
                        scores.trust_score * 0.25 +
                        scores.proximity_score * 0.15 +
                        scores.skill_quality_score * 0.15 +
                        scores.availability_score * 0.05
          };
        })
      );

      // 5. Sort by total score and return top 10
      const topMatches = scoredMatches
        .sort((a, b) => b.total_score - a.total_score)
        .slice(0, 10);

      return topMatches;
    } catch (err) {
      console.error('Find matches error:', err);
      throw err;
    }
  }

  /**
   * Calculate match score components
   */
  static async calculateMatchScore(match, request, requesterSkills, userNik) {
    // 1. Mutual Benefit Score (0-100)
    const mutualBenefitScore = await this.calculateMutualBenefit(
      match.nik_pengguna,
      requesterSkills
    );

    // 2. Trust Score (0-100) - normalized from 0-5 scale
    const trustScore = (match.trust_score / 5) * 100;

    // 3. Proximity Score (0-100)
    const proximityScore = await this.calculateProximity(
      match.lokasi,
      request.lokasi_preferensi
    );

    // 4. Skill Quality Score (0-100)
    const skillQualityScore = this.calculateSkillQuality(match);

    // 5. Availability Score (0-100)
    const availabilityScore = await this.calculateAvailability(
      match.nik_pengguna
    );

    return {
      mutual_benefit_score: mutualBenefitScore,
      trust_score: trustScore,
      proximity_score: proximityScore,
      skill_quality_score: skillQualityScore,
      availability_score: availabilityScore
    };
  }

  /**
   * Calculate mutual benefit score
   * Check if provider needs skills that requester has
   */
  static async calculateMutualBenefit(providerNik, requesterSkills) {
    if (requesterSkills.length === 0) return 0;

    // Get provider's skill requests
    const [providerRequests] = await db.execute(
      `SELECT id_kategori, deskripsi_kebutuhan 
       FROM skill_requests 
       WHERE nik_pengguna = ? AND status = 'terbuka'`,
      [providerNik]
    );

    if (providerRequests.length === 0) return 20; // Base score

    // Check for category matches
    const requesterCategoryIds = requesterSkills.map(s => s.id_kategori);
    const providerRequestCategoryIds = providerRequests.map(r => r.id_kategori);
    
    const matchingCategories = requesterCategoryIds.filter(id =>
      providerRequestCategoryIds.includes(id)
    );

    if (matchingCategories.length > 0) {
      return 100; // Perfect mutual benefit
    }

    return 40; // Provider has requests but no direct match
  }

  /**
   * Calculate proximity score based on location
   */
  static async calculateProximity(providerLocation, requestedLocation) {
    if (!providerLocation || !requestedLocation) return 50; // Neutral score

    // Simple string matching (can be enhanced with geocoding)
    const providerLoc = providerLocation.toLowerCase();
    const requestedLoc = requestedLocation.toLowerCase();

    if (providerLoc === requestedLoc) return 100; // Same location
    
    // Check if same city/region
    const providerParts = providerLoc.split(/[,\s]+/);
    const requestedParts = requestedLoc.split(/[,\s]+/);
    
    const hasCommonPart = providerParts.some(part =>
      requestedParts.some(reqPart => 
        part.includes(reqPart) || reqPart.includes(part)
      )
    );

    if (hasCommonPart) return 70; // Same region

    return 30; // Different location
  }

  /**
   * Calculate skill quality score
   */
  static calculateSkillQuality(match) {
    let score = 0;

    // Skill level (1-5) -> 0-30 points
    score += (match.tingkat_keahlian / 5) * 30;

    // Verification status -> 0-25 points
    if (match.status_verifikasi) score += 25;

    // Rating -> 0-25 points
    if (match.rating_rata_rata) {
      score += (match.rating_rata_rata / 5) * 25;
    }

    // Number of reviews -> 0-20 points
    if (match.jumlah_ulasan) {
      const reviewScore = Math.min(match.jumlah_ulasan / 10, 1) * 20;
      score += reviewScore;
    }

    return score;
  }

  /**
   * Calculate availability score
   */
  static async calculateAvailability(providerNik) {
    // Check active barter sessions
    const [activeSessions] = await db.execute(
      `SELECT COUNT(*) as count
       FROM barter_sessions bs
       JOIN barter_offers bo ON bs.id_penawaran = bo.id
       WHERE (bo.nik_penawar = ? OR bo.nik_penerima = ?)
       AND bs.status IN ('dijadwalkan', 'berlangsung')`,
      [providerNik, providerNik]
    );

    const activeCount = activeSessions[0].count;

    // Less active sessions = higher availability
    if (activeCount === 0) return 100;
    if (activeCount === 1) return 80;
    if (activeCount === 2) return 60;
    if (activeCount === 3) return 40;
    return 20;
  }

  /**
   * Get recommended users for a specific skill category
   * Used in explore/browse features
   */
  static async getRecommendedProviders(categoryId, userNik, limit = 10) {
    try {
      const [providers] = await db.execute(
        `SELECT 
          s.nik_pengguna,
          p.nama_lengkap,
          p.foto_profil,
          p.lokasi,
          p.trust_score,
          COUNT(DISTINCT s.id) as skill_count,
          AVG(s.rating_rata_rata) as avg_rating,
          SUM(s.jumlah_ulasan) as total_reviews,
          (
            SELECT COUNT(*) 
            FROM barter_sessions bs
            JOIN barter_offers bo ON bs.id_penawaran = bo.id
            WHERE (bo.nik_penawar = s.nik_pengguna OR bo.nik_penerima = s.nik_pengguna)
            AND bs.status = 'selesai'
          ) as completed_sessions
        FROM skills s
        JOIN pengguna p ON s.nik_pengguna = p.nik
        WHERE s.id_kategori = ?
        AND s.tipe = 'dikuasai'
        AND s.status_aktif = 1
        AND s.nik_pengguna != ?
        AND p.status_akun = 'aktif'
        GROUP BY s.nik_pengguna
        ORDER BY 
          p.trust_score DESC,
          avg_rating DESC,
          completed_sessions DESC
        LIMIT ?`,
        [categoryId, userNik, limit]
      );

      return providers;
    } catch (err) {
      console.error('Get recommended providers error:', err);
      throw err;
    }
  }
}

module.exports = MatchingService;
