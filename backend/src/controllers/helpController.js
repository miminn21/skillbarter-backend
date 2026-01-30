const Report = require('../models/Report');
const { success, error } = require('../utils/response');

/**
 * Submit Help/Report
 * POST /api/help/submit
 */
exports.submitReport = async (req, res) => {
  try {
    const { nik } = req.user;
    const { deskripsi, jenis_laporan, nik_dilaporkan } = req.body;

    if (!deskripsi) {
      return error(res, 'Deskripsi masalah harus diisi', 400);
    }

    let bukti_gambar = null;
    let jenis_bukti = null;

    // Handle file upload
    if (req.file) {
      bukti_gambar = req.file.buffer;
      // Simple mime mapping
      if (req.file.mimetype === 'image/jpeg') jenis_bukti = 'jpg';
      else if (req.file.mimetype === 'image/png') jenis_bukti = 'png';
      else jenis_bukti = 'jpg'; // Default
    }

    await Report.create({
      nik_pelapor: nik,
      nik_dilaporkan: nik_dilaporkan || null,
      jenis_laporan: jenis_laporan || 'lainnya', 
      deskripsi,
      bukti_gambar,
      jenis_bukti
    });

    return success(res, 'Laporan Anda telah dikirim. Tim kami akan segera meninjaunya.', null, 201);

  } catch (err) {
    console.error('Submit report error:', err);
    return error(res, 'Gagal mengirim laporan: ' + err.message);
  }
};

/**
 * Get Report History
 * GET /api/help/history
 */
exports.getHistory = async (req, res) => {
    try {
        const { nik } = req.user;
        const history = await Report.findByReporter(nik);
        
        // Don't send heavy blobs in list
        const sanitized = history.map(h => ({
            ...h,
            bukti_gambar: undefined, // Hide blob
            has_bukti: !!h.bukti_gambar
        }));

        return success(res, 'Riwayat laporan diambil', sanitized);
    } catch (err) {
        return error(res, 'Gagal mengambil riwayat: ' + err.message);
    }
}
