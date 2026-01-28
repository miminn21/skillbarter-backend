const db = require('../config/database');

class BarterConfirmation {
  // Create or update confirmation
  static async confirm(idBarter, nik, catatan = null) {
    const query = `
      INSERT INTO barter_confirmations 
        (id_barter, nik, konfirmasi_selesai, catatan)
      VALUES (?, ?, TRUE, ?)
      ON DUPLICATE KEY UPDATE 
        konfirmasi_selesai = TRUE,
        catatan = ?,
        waktu_konfirmasi = CURRENT_TIMESTAMP
    `;
    
    await db.execute(query, [idBarter, nik, catatan, catatan]);
  }

  // Check if both parties confirmed
  static async checkBothConfirmed(idBarter) {
    const query = `
      SELECT COUNT(*) as confirmed_count
      FROM barter_confirmations
      WHERE id_barter = ? AND konfirmasi_selesai = TRUE
    `;
    
    const [rows] = await db.execute(query, [idBarter]);
    return rows[0].confirmed_count >= 2;
  }

  // Get confirmations for a barter
  static async getByBarter(idBarter) {
    const query = `
      SELECT 
        bc.*,
        p.nama_lengkap,
        p.foto_profil
      FROM barter_confirmations bc
      JOIN pengguna p ON bc.nik = p.nik
      WHERE bc.id_barter = ?
    `;
    
    const [rows] = await db.execute(query, [idBarter]);
    return rows;
  }

  // Check if user has confirmed
  static async hasConfirmed(idBarter, nik) {
    const query = `
      SELECT konfirmasi_selesai
      FROM barter_confirmations
      WHERE id_barter = ? AND nik = ?
    `;
    
    const [rows] = await db.execute(query, [idBarter, nik]);
    return rows[0]?.konfirmasi_selesai || false;
  }

  // Get pending confirmations for user
  static async getPendingForUser(nik) {
    const query = `
      SELECT DISTINCT b.*
      FROM transaksi_barter b
      WHERE b.status = 'berlangsung'
        AND (b.nik_penawar = ? OR b.nik_ditawar = ?)
        AND NOT EXISTS (
          SELECT 1 FROM barter_confirmations bc
          WHERE bc.id_barter = b.id AND bc.nik = ?
        )
    `;
    
    const [rows] = await db.execute(query, [nik, nik, nik]);
    return rows;
  }
}

module.exports = BarterConfirmation;
