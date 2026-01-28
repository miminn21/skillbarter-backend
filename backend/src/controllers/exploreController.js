const Explore = require('../models/Explore');
const Recommendation = require('../models/Recommendation');
const Leaderboard = require('../models/Leaderboard');
const User = require('../models/User');
const Skill = require('../models/Skill');
const response = require('../utils/response');

/**
 * Explore skills with filters
 */
exports.exploreSkills = async (req, res) => {
  try {
    const filters = {
      kategori: req.query.kategori,
      tipe: req.query.tipe,
      tingkat: req.query.tingkat,
      search: req.query.search,
      page: req.query.page || 1,
      limit: req.query.limit || 20
    };

    const result = await Explore.searchSkills(filters);

    // Convert BLOBs to base64
    if (result && result.skills && result.skills.length > 0) {
      result.skills.forEach(skill => {
        if (skill.gambar_skill) {
          skill.gambar_skill = skill.gambar_skill.toString('base64');
        }
        if (skill.portofolio_gambar) {
          skill.portofolio_gambar = skill.portofolio_gambar.toString('base64');
        }
        if (skill.foto_profil) {
          skill.foto_profil = skill.foto_profil.toString('base64');
        }
      });
    }

    return response.success(res, 'Skills berhasil diambil', result);
  } catch (error) {
    console.error('Explore skills error:', error);
    return response.error(res, 'Gagal mengambil skills', 500);
  }
};

/**
 * Get personalized recommendations
 */
exports.getRecommendations = async (req, res) => {
  try {
    const nik = req.user.nik;

    const recommendations = await Recommendation.getRecommendations(nik);

    return response.success(
      res,
      'Rekomendasi berhasil diambil',
      recommendations
    );
  } catch (error) {
    console.error('Get recommendations error:', error);
    return response.error(res, 'Gagal mengambil rekomendasi', 500);
  }
};

/**
 * Get public user profile
 */
exports.getUserProfile = async (req, res) => {
  try {
    const { nik } = req.params;

    // Get user public profile with stats
    const user = await User.getPublicProfile(nik);
    if (!user) {
      return response.error(res, 'User tidak ditemukan', 404);
    }

    // Convert BLOB to base64 if exists
    if (user.foto_profil) {
      user.foto_profil = user.foto_profil.toString('base64');
    }

    // Get user's dikuasai skills
    const skills = await Skill.getUserSkills(nik, 'dikuasai');

    // Convert BLOB to base64 for skills
    if (skills && skills.length > 0) {
      skills.forEach(skill => {
        if (skill.gambar_skill) {
          skill.gambar_skill = skill.gambar_skill.toString('base64');
        }
        if (skill.portofolio_gambar) {
          skill.portofolio_gambar = skill.portofolio_gambar.toString('base64');
        }
      });
    }

    return response.success(res, 'Profil user berhasil diambil', {
      user,
      skills
    });
  } catch (error) {
    console.error('Get user profile error:', error);
    return response.error(res, 'Gagal mengambil profil user', 500);
  }
};

/**
 * Get leaderboard
 */
exports.getLeaderboard = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const nik = req.user?.nik; // Optional, if authenticated

    let result;
    if (nik) {
      // Get leaderboard with current user
      result = await Leaderboard.getLeaderboardWithUser(nik, limit);
    } else {
      // Get top users only
      const leaderboard = await Leaderboard.getTopUsers(limit);
      result = { leaderboard };
    }

    return response.success(res, 'Leaderboard berhasil diambil', result);
  } catch (error) {
    console.error('Get leaderboard error:', error);
    return response.error(res, 'Gagal mengambil leaderboard', 500);
  }
};
