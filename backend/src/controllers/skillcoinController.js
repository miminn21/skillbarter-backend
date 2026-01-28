const SkillCoinTransaction = require('../models/SkillCoinTransaction');
const { notifySkillCoinReceived, notifySkillCoinSent } = require('../helpers/notificationHelper');

// Get transaction history
exports.getHistory = async (req, res) => {
  try {
    const nik = req.user.nik;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;

    const transactions = await SkillCoinTransaction.getHistory(nik, limit, offset);

    res.json({
      success: true,
      data: transactions,
      pagination: {
        limit,
        offset,
        total: transactions.length
      }
    });
  } catch (error) {
    console.error('Error getting transaction history:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil riwayat transaksi',
      error: error.message
    });
  }
};

// Get current balance
exports.getBalance = async (req, res) => {
  try {
    const nik = req.user.nik;
    const balance = await SkillCoinTransaction.getBalance(nik);

    res.json({
      success: true,
      data: { balance }
    });
  } catch (error) {
    console.error('Error getting balance:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil saldo',
      error: error.message
    });
  }
};

// Get transaction stats
exports.getStats = async (req, res) => {
  try {
    const nik = req.user.nik;
    const stats = await SkillCoinTransaction.getStats(nik);

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil statistik',
      error: error.message
    });
  }
};

// Manual transfer (admin only)
exports.transfer = async (req, res) => {
  try {
    const { nik_penerima, jumlah, keterangan } = req.body;

    if (!nik_penerima || !jumlah) {
      return res.status(400).json({
        success: false,
        message: 'NIK penerima dan jumlah wajib diisi'
      });
    }

    if (jumlah <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Jumlah harus lebih dari 0'
      });
    }

    const nik_pengirim = req.user.nik;

    // Use stored procedure for transfer
    const result = await SkillCoinTransaction.transfer(
      nik_pengirim,
      nik_penerima,
      jumlah,
      null,
      keterangan || 'Transfer manual'
    );

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }

    // Send notifications
    await notifySkillCoinReceived(nik_penerima, jumlah, req.user.nama_lengkap);
    await notifySkillCoinSent(nik_pengirim, jumlah, nik_penerima);

    res.json({
      success: true,
      message: 'Transfer berhasil'
    });
  } catch (error) {
    console.error('Error transferring SkillCoin:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal melakukan transfer',
      error: error.message
    });
  }
};

// Admin adjustment
exports.adjust = async (req, res) => {
  try {
    // Check if user is admin
    if (!req.user.is_admin) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak'
      });
    }

    const { nik, jumlah, keterangan } = req.body;

    if (!nik || !jumlah) {
      return res.status(400).json({
        success: false,
        message: 'NIK dan jumlah wajib diisi'
      });
    }

    await SkillCoinTransaction.adjust(nik, jumlah, keterangan || 'Adjustment oleh admin');

    res.json({
      success: true,
      message: 'Adjustment berhasil'
    });
  } catch (error) {
    console.error('Error adjusting SkillCoin:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal melakukan adjustment',
      error: error.message
    });
  }
};

module.exports = exports;
