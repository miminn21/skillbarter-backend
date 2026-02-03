const fs = require('fs');
const path = require('path');
const Skill = require('../models/Skill');
const SkillRequest = require('../models/SkillRequest');
const Category = require('../models/Category');
const MatchingService = require('../services/matchingService');
const { success, error, notFound } = require('../utils/response');
const db = require('../config/database');

/**
 * Skill Controller
 */

/**
 * Get all categories
 * GET /api/categories
 */
exports.getCategories = async (req, res) => {
  try {
    const categories = await Category.getAll();
    return success(res, 'Kategori berhasil diambil', categories);
  } catch (err) {
    console.error('Get categories error:', err);
    return error(res, 'Gagal mengambil kategori: ' + err.message);
  }
};

/**
 * Get user's skills
 * GET /api/skills?tipe=dikuasai|dicari
 */
exports.getUserSkills = async (req, res) => {
  try {
    const { nik } = req.user;
    const { tipe } = req.query;
    
    const skills = await Skill.getUserSkills(nik, tipe);
    
    // Convert BLOB to base64 if exists
    skills.forEach(skill => {
      // Convert User Photo BLOB to base64 if exists (from join)
      // Note: User photo usually handled in profile controller but if joined here:
      // if (skill.foto_profil) skill.foto_profil = skill.foto_profil.toString('base64');

      if (skill.portofolio_gambar) {
        skill.portofolio_gambar = skill.portofolio_gambar.toString('base64');
      }
      if (skill.gambar_skill) {
        skill.gambar_skill = skill.gambar_skill.toString('base64');
      }
    });
    
    return success(res, 'Skill berhasil diambil', skills);
  } catch (err) {
    console.error('Get skills error:', err);
    return error(res, 'Gagal mengambil skill: ' + err.message);
  }
};

/**
 * Get skill detail
 * GET /api/skills/:id
 */
exports.getSkillDetail = async (req, res) => {
  try {
    const { id } = req.params;
    
    const skill = await Skill.findById(id);
    
    if (!skill) {
      return notFound(res, 'Skill tidak ditemukan');
    }
    
    // Convert BLOB to base64 if exists
    if (skill.portofolio_gambar) {
      skill.portofolio_gambar = skill.portofolio_gambar.toString('base64');
    }
    if (skill.gambar_skill) {
      skill.gambar_skill = skill.gambar_skill.toString('base64');
    }
    
    return success(res, 'Detail skill berhasil diambil', skill);
  } catch (err) {
    console.error('Get skill detail error:', err);
    return error(res, 'Gagal mengambil detail skill: ' + err.message);
  }
};

/**
 * Add new skill
 * POST /api/skills
 */
exports.addSkill = async (req, res) => {
  try {
    const { nik } = req.user;
    
    console.log('[AddSkill] Request body:', JSON.stringify(req.body, null, 2));
    console.log('[AddSkill] User NIK:', nik);
    
    const skillData = {
      ...req.body,
      nik_pengguna: nik
    };
    
    // Handle image upload
    if (req.file) {
      console.log('[AddSkill] Image file detected:', req.file.originalname);
      const filePath = req.file.path;
      const fileBuffer = fs.readFileSync(filePath);
      const fileType = path.extname(req.file.originalname).substring(1);
      
      skillData.gambar_skill = fileBuffer;
      skillData.jenis_gambar_skill = fileType;
      
      // Clean up temp file
      fs.unlinkSync(filePath);
    }
    
    console.log('[AddSkill] Skill data to insert:', JSON.stringify(skillData, null, 2));
    
    const result = await Skill.create(skillData);
    
    // Get created skill
    const newSkill = await Skill.findById(result.insertId);
    
    // Convert BLOB to base64 if exists
    if (newSkill) {
        if (newSkill.portofolio_gambar) {
            newSkill.portofolio_gambar = newSkill.portofolio_gambar.toString('base64');
        }
        if (newSkill.gambar_skill) {
            newSkill.gambar_skill = newSkill.gambar_skill.toString('base64');
        }
    }
    
    console.log('[AddSkill] Success! New skill ID:', result.insertId);
    
    return success(res, 'Skill berhasil ditambahkan', newSkill, 201);
  } catch (err) {
    console.error('[AddSkill] Error:', err);
    console.error('[AddSkill] Error message:', err.message);
    console.error('[AddSkill] Error stack:', err.stack);
    return error(res, 'Gagal menambahkan skill: ' + err.message);
  }
};

/**
 * Update skill
 * PUT /api/skills/:id
 */
exports.updateSkill = async (req, res) => {
  try {
    const { id } = req.params;
    const { nik } = req.user;
    
    // Check ownership
    const isOwner = await Skill.isOwner(id, nik);
    if (!isOwner) {
      if (req.file) {
        fs.unlinkSync(req.file.path);
      }
      return error(res, 'Anda tidak memiliki akses untuk mengubah skill ini', 403);
    }
    
    const skillData = { ...req.body };
    
    // Handle image file if uploaded
    if (req.file) {
      console.log('[UpdateSkill] Image file detected:', req.file.originalname);
      const filePath = req.file.path;
      const fileBuffer = fs.readFileSync(filePath);
      const fileType = path.extname(req.file.originalname).substring(1);
      
      skillData.gambar_skill = fileBuffer;
      skillData.jenis_gambar_skill = fileType;
      
      // Clean up temp file
      fs.unlinkSync(filePath);
    }
    
    await Skill.update(id, skillData);
    
    // Get updated skill
    const updatedSkill = await Skill.findById(id);
    
    // Convert BLOB to base64 if exists
    if (updatedSkill) {
        if (updatedSkill.portofolio_gambar) {
            updatedSkill.portofolio_gambar = updatedSkill.portofolio_gambar.toString('base64');
        }
        if (updatedSkill.gambar_skill) {
            updatedSkill.gambar_skill = updatedSkill.gambar_skill.toString('base64');
        }
    }
    
    return success(res, 'Skill berhasil diperbarui', updatedSkill);
  } catch (err) {
    if (req.file) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (e) {}
    }
    console.error('Update skill error:', err);
    return error(res, 'Gagal memperbarui skill: ' + err.message);
  }
};

/**
 * Delete skill
 * DELETE /api/skills/:id
 */
exports.deleteSkill = async (req, res) => {
  try {
    const { id } = req.params;
    const { nik } = req.user;
    
    // Check ownership
    const isOwner = await Skill.isOwner(id, nik);
    if (!isOwner) {
      return error(res, 'Anda tidak memiliki akses untuk menghapus skill ini', 403);
    }
    
    await Skill.delete(id);
    
    return success(res, 'Skill berhasil dihapus');
  } catch (err) {
    console.error('Delete skill error:', err);
    return error(res, 'Gagal menghapus skill: ' + err.message);
  }
};

/**
 * Upload portfolio image
 * POST /api/skills/:id/upload-portfolio
 */
exports.uploadPortfolio = async (req, res) => {
  try {
    const { id } = req.params;
    const { nik } = req.user;
    
    console.log('[uploadPortfolio] Request received');
    console.log('[uploadPortfolio] Skill ID:', id);
    console.log('[uploadPortfolio] User NIK:', nik);
    console.log('[uploadPortfolio] req.file:', req.file);
    console.log('[uploadPortfolio] req.body:', req.body);
    console.log('[uploadPortfolio] Content-Type:', req.headers['content-type']);
    
    if (!req.file) {
      console.log('[uploadPortfolio] ERROR: File tidak ditemukan');
      return error(res, 'File tidak ditemukan', 400);
    }
    
    // Check ownership
    const isOwner = await Skill.isOwner(id, nik);
    if (!isOwner) {
      return error(res, 'Anda tidak memiliki akses untuk mengubah skill ini', 403);
    }
    
    // Read file as buffer
    const filePath = req.file.path;
    const fileBuffer = fs.readFileSync(filePath);
    const fileType = path.extname(req.file.originalname).substring(1);
    
    // Update portfolio in database
    await Skill.updatePortfolio(id, {
      portofolio_gambar: fileBuffer,
      jenis_portofolio: fileType
    });
    
    // Delete temporary file
    fs.unlinkSync(filePath);
    
    // Get updated skill
    const updatedSkill = await Skill.findById(id);
    
    // Convert BLOB to base64
    if (updatedSkill && updatedSkill.portofolio_gambar) {
      updatedSkill.portofolio_gambar = updatedSkill.portofolio_gambar.toString('base64');
    }
    
    return success(res, 'Portfolio berhasil diupload', updatedSkill);
  } catch (err) {
    console.error('Upload portfolio error:', err);
    
    // Delete temporary file if exists
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (unlinkErr) {
        console.error('Failed to delete temp file:', unlinkErr);
      }
    }
    
    return error(res, 'Gagal mengupload portfolio: ' + err.message);
  }
};

/**
 * Verify skill (costs 10 skillcoin)
 * POST /api/skills/:id/verify
 */
exports.verifySkill = async (req, res) => {
  try {
    const { id } = req.params;
    const { nik } = req.user;
    
    const skill = await Skill.findById(id);
    
    if (!skill) {
      return notFound(res, 'Skill tidak ditemukan');
    }
    
    // Cannot verify own skill
    if (skill.nik_pengguna === nik) {
      return error(res, 'Tidak bisa memverifikasi skill sendiri', 400);
    }
    
    // Already verified
    if (skill.status_verifikasi) {
      return error(res, 'Skill sudah terverifikasi', 400);
    }
    
    // Call stored procedure (will handle skillcoin deduction)
    const query = 'CALL verifikasi_keahlian(?, ?)';
    await db.execute(query, [id, nik]);
    
    // Get updated skill
    const updatedSkill = await Skill.findById(id);
    
    return success(res, 'Skill berhasil diverifikasi', updatedSkill);
  } catch (err) {
    console.error('Verify skill error:', err);
    
    // Check if error is from stored procedure
    if (err.message.includes('Saldo skillcoin tidak cukup')) {
      return error(res, 'Saldo skillcoin tidak cukup untuk verifikasi (butuh 10 skillcoin)', 400);
    }
    
    return error(res, 'Gagal memverifikasi skill: ' + err.message);
  }
};

/**
 * ========================================
 * SKILL REQUEST ENDPOINTS
 * ========================================
 */

/**
 * Get user's skill requests
 * GET /api/skills/requests?status=terbuka|dipenuhi|dibatalkan
 */
exports.getUserSkillRequests = async (req, res) => {
  try {
    const { nik } = req.user;
    const { status } = req.query;
    
    const requests = await SkillRequest.getUserRequests(nik, status);
    
    return success(res, 'Skill requests berhasil diambil', requests);
  } catch (err) {
    console.error('Get skill requests error:', err);
    return error(res, 'Gagal mengambil skill requests: ' + err.message);
  }
};

/**
 * Get skill request detail
 * GET /api/skills/requests/:id
 */
exports.getSkillRequestDetail = async (req, res) => {
  try {
    const { id } = req.params;
    
    const request = await SkillRequest.findById(id);
    
    if (!request) {
      return notFound(res, 'Skill request tidak ditemukan');
    }
    
    return success(res, 'Detail skill request berhasil diambil', request);
  } catch (err) {
    console.error('Get skill request detail error:', err);
    return error(res, 'Gagal mengambil detail skill request: ' + err.message);
  }
};

/**
 * Create new skill request
 * POST /api/skills/requests
 */
exports.createSkillRequest = async (req, res) => {
  try {
    const { nik } = req.user;
    const requestData = {
      ...req.body,
      nik_pengguna: nik
    };
    
    const result = await SkillRequest.create(requestData);
    
    // Get created request
    const newRequest = await SkillRequest.findById(result.insertId);
    
    return success(res, 'Skill request berhasil dibuat', newRequest, 201);
  } catch (err) {
    console.error('Create skill request error:', err);
    return error(res, 'Gagal membuat skill request: ' + err.message);
  }
};

/**
 * Update skill request
 * PUT /api/skills/requests/:id
 */
exports.updateSkillRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { nik } = req.user;
    
    // Check ownership
    const isOwner = await SkillRequest.isOwner(id, nik);
    if (!isOwner) {
      return error(res, 'Anda tidak memiliki akses untuk mengubah request ini', 403);
    }
    
    await SkillRequest.update(id, req.body);
    
    // Get updated request
    const updatedRequest = await SkillRequest.findById(id);
    
    return success(res, 'Skill request berhasil diperbarui', updatedRequest);
  } catch (err) {
    console.error('Update skill request error:', err);
    return error(res, 'Gagal memperbarui skill request: ' + err.message);
  }
};

/**
 * Delete skill request
 * DELETE /api/skills/requests/:id
 */
exports.deleteSkillRequest = async (req, res) => {
  try {
    const { id } = req.params;
    const { nik } = req.user;
    
    // Check ownership
    const isOwner = await SkillRequest.isOwner(id, nik);
    if (!isOwner) {
      return error(res, 'Anda tidak memiliki akses untuk menghapus request ini', 403);
    }
    
    await SkillRequest.delete(id);
    
    return success(res, 'Skill request berhasil dihapus');
  } catch (err) {
    console.error('Delete skill request error:', err);
    return error(res, 'Gagal menghapus skill request: ' + err.message);
  }
};

/**
 * Find matches for a skill request
 * GET /api/skills/requests/:id/matches
 */
exports.findMatches = async (req, res) => {
  try {
    const { id } = req.params;
    const { nik } = req.user;
    
    // Verify ownership
    const isOwner = await SkillRequest.isOwner(id, nik);
    if (!isOwner) {
      return error(res, 'Anda tidak memiliki akses untuk melihat matches request ini', 403);
    }
    
    // Find matches using matching service
    const matches = await MatchingService.findMatches(nik, id);
    
    return success(res, 'Matches berhasil ditemukan', {
      request_id: id,
      total_matches: matches.length,
      matches: matches
    });
  } catch (err) {
    console.error('Find matches error:', err);
    return error(res, 'Gagal mencari matches: ' + err.message);
  }
};

/**
 * Get all open skill requests (for explore)
 * GET /api/skills/requests/explore?kategori=&tingkat=&lokasi=&limit=
 */
exports.exploreSkillRequests = async (req, res) => {
  try {
    const filters = {
      id_kategori: req.query.kategori,
      tingkat_keahlian: req.query.tingkat,
      lokasi: req.query.lokasi,
      limit: req.query.limit || 20
    };
    
    const requests = await SkillRequest.getOpenRequests(filters);
    
    return success(res, 'Open skill requests berhasil diambil', requests);
  } catch (err) {
    console.error('Explore skill requests error:', err);
    return error(res, 'Gagal mengambil open skill requests: ' + err.message);
  }
};

module.exports = exports;
