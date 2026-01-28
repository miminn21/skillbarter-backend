const db = require('../config/database');

class SkillCoinTransaction {
  // Get transaction history for a user
  static async getHistory(nik, limit = 50, offset = 0) {
    const query = `
      SELECT 
        st.*,
        p1.nama_lengkap as nama_pengirim,
        p2.nama_lengkap as nama_penerima,
        b.status as status_barter
      FROM skillcoin_transactions st
      LEFT JOIN pengguna p1 ON st.nik_pengirim = p1.nik
      LEFT JOIN pengguna p2 ON st.nik_penerima = p2.nik
      LEFT JOIN transaksi_barter b ON st.id_barter = b.id
      WHERE st.nik_pengirim = ? OR st.nik_penerima = ?
      ORDER BY st.created_at DESC
      LIMIT ? OFFSET ?
    `;
    
    const [rows] = await db.execute(query, [nik, nik, limit, offset]);
    return rows;
  }

  // Get transaction by ID
  static async findById(id) {
    const query = `
      SELECT 
        st.*,
        p1.nama_lengkap as nama_pengirim,
        p2.nama_lengkap as nama_penerima
      FROM skillcoin_transactions st
      LEFT JOIN pengguna p1 ON st.nik_pengirim = p1.nik
      LEFT JOIN pengguna p2 ON st.nik_penerima = p2.nik
      WHERE st.id_transaksi = ?
    `;
    
    const [rows] = await db.execute(query, [id]);
    return rows[0];
  }

  // Transfer SkillCoin using stored procedure
  static async transfer(nikPengirim, nikPenerima, jumlah, idBarter, keterangan) {
    try {
      await db.execute(
        'CALL transfer_skillcoin(?, ?, ?, ?, ?)',
        [nikPengirim, nikPenerima, jumlah, idBarter, keterangan]
      );
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Get balance for a user
  static async getBalance(nik) {
    const query = 'SELECT saldo_skillcoin FROM pengguna WHERE nik = ?';
    const [rows] = await db.execute(query, [nik]);
    return rows[0]?.saldo_skillcoin || 0;
  }

  // Get transaction stats
  static async getStats(nik) {
    const query = `
      SELECT 
        COUNT(*) as total_transactions,
        COALESCE(SUM(CASE WHEN nik_penerima = ? THEN jumlah ELSE 0 END), 0) as total_received,
        COALESCE(SUM(CASE WHEN nik_pengirim = ? THEN jumlah ELSE 0 END), 0) as total_sent
      FROM skillcoin_transactions
      WHERE nik_pengirim = ? OR nik_penerima = ?
    `;
    
    const [rows] = await db.execute(query, [nik, nik, nik, nik]);
    return rows[0];
  }

  // Manual adjustment (admin only)
  static async adjust(nik, jumlah, keterangan) {
    const query = `
      INSERT INTO skillcoin_transactions 
        (nik_penerima, jumlah, tipe, keterangan)
      VALUES (?, ?, 'adjustment', ?)
    `;
    
    await db.execute(query, [nik, jumlah, keterangan]);
    
    // Update user balance
    await db.execute(
      'UPDATE pengguna SET saldo_skillcoin = saldo_skillcoin + ? WHERE nik = ?',
      [jumlah, nik]
    );
  }
}

module.exports = SkillCoinTransaction;
