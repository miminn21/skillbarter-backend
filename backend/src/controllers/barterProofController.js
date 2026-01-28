const Barter = require('../models/Barter');
const SkillcoinService = require('../services/skillcoinService');
const db = require('../config/database');

/**
 * Upload proof photo for completed barter
 */
exports.uploadProof = async (req, res) => {
  try {
    const { id } = req.params;
    const { foto_bukti, catatan } = req.body;
    const nik = req.user.nik;

    console.log('[UploadProof] Barter ID:', id, 'User:', nik);

    // Get barter details
    const barter = await Barter.findById(id);
    
    if (!barter) {
      return res.status(404).json({
        success: false,
        message: 'Barter not found'
      });
    }

    // Verify user is part of this barter
    if (barter.nik_penawar !== nik && barter.nik_ditawar !== nik) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    // Verify status allows proof upload
    if (!['diterima', 'berlangsung', 'selesai'].includes(barter.status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot upload proof. Current status: ${barter.status}`
      });
    }

    // Upload proof to confirmation table
    // Use INSERT ON DUPLICATE KEY UPDATE to handle missing records
    await db.execute(`
      INSERT INTO barter_confirmations 
        (id_barter, nik, foto_bukti, catatan, waktu_upload_foto, konfirmasi_selesai) 
      VALUES (?, ?, ?, ?, NOW(), FALSE)
      ON DUPLICATE KEY UPDATE 
        foto_bukti = VALUES(foto_bukti),
        catatan = VALUES(catatan),
        waktu_upload_foto = NOW()
    `, [id, nik, foto_bukti, catatan || null]);

    console.log('[UploadProof] Success!');

    res.json({
      success: true,
      message: 'Proof photo uploaded successfully'
    });
  } catch (error) {
    console.error('Upload proof error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * Get confirmations for a barter (both users)
 */
exports.getConfirmations = async (req, res) => {
  try {
    const { id } = req.params;
    const nik = req.user.nik;

    console.log('[GetConfirmations] Barter ID:', id);

    // Get barter details
    const barter = await Barter.findById(id);
    
    if (!barter) {
      return res.status(404).json({
        success: false,
        message: 'Barter not found'
      });
    }

    // Verify user is part of this barter
    if (barter.nik_penawar !== nik && barter.nik_ditawar !== nik) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    // Get both confirmations
    const [confirmations] = await db.execute(`
      SELECT 
        bc.*,
        p.nama_lengkap,
        CASE 
          WHEN bc.nik = ? THEN 'own'
          ELSE 'partner'
        END as confirmation_type
      FROM barter_confirmations bc
      JOIN pengguna p ON bc.nik = p.nik
      WHERE bc.id_barter = ?
      ORDER BY bc.nik = ? DESC
    `, [nik, id, nik]);

    console.log('[GetConfirmations] Found', confirmations.length, 'confirmations');

    res.json({
      success: true,
      data: confirmations
    });
  } catch (error) {
    console.error('Get confirmations error:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
