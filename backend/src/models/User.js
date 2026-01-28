const db = require('../config/database');

/**
 * User Model
 */
class User {
  /**
   * Create new user
   */
  static async create(userData) {
    const {
      nik, nama_lengkap, nama_panggilan, kata_sandi,
      jenis_kelamin, tanggal_lahir, alamat_lengkap, kota, bio
    } = userData;
    
    const query = `
      INSERT INTO pengguna (
        nik, nama_lengkap, nama_panggilan, kata_sandi,
        jenis_kelamin, tanggal_lahir, alamat_lengkap, kota, bio
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const [result] = await db.execute(query, [
      nik, nama_lengkap, nama_panggilan, kata_sandi,
      jenis_kelamin, tanggal_lahir, alamat_lengkap, kota, bio || null
    ]);
    
    return result;
  }
  
  /**
   * Find user by NIK
   */
  static async findByNik(nik) {
    const query = `
      SELECT 
        p.*,
        d.pekerjaan, d.nama_instansi, d.pendidikan_terakhir,
        d.keahlian_khusus, d.media_sosial, d.preferensi_lokasi,
        d.zona_waktu, d.bahasa
      FROM pengguna p
      LEFT JOIN detail_pengguna d ON p.nik = d.nik
      WHERE p.nik = ?
    `;
    
    const [rows] = await db.execute(query, [nik]);
    return rows[0];
  }
  
  /**
   * Get public profile with stats (for viewing other users)
   */
  static async getPublicProfile(nik) {
    const query = `
      SELECT 
        p.nik,
        p.nama_lengkap,
        p.nama_panggilan,
        p.foto_profil,
        p.bio,
        CASE
          WHEN p.status_online = 'online' AND TIMESTAMPDIFF(SECOND, p.terakhir_aktif, NOW()) > 120 THEN 'offline'
          ELSE p.status_online
        END as status_online,
        p.terakhir_aktif,
        COALESCE(p.rating_rata_rata, 0.0) as rating_rata_rata,
        COALESCE(p.jumlah_transaksi, 0) as jumlah_transaksi,
        COALESCE(p.saldo_skillcoin, 0) as saldo_skillcoin,
        COALESCE(p.total_jam_berkontribusi, 0) as total_jam_berkontribusi
      FROM pengguna p
      WHERE p.nik = ?
    `;
    
    const [rows] = await db.execute(query, [nik]);
    // Note: The logic above handles the timeout check natively in the database
    // ensuring perfect synchronization with the last_active timestamp.
    
    return rows[0];
  }
  
  /**
   * Update user profile
   */
  static async update(nik, userData) {
    const {
      nama_lengkap, nama_panggilan, jenis_kelamin,
      tanggal_lahir, alamat_lengkap, kota, bio
    } = userData;
    
    const query = `
      UPDATE pengguna 
      SET 
        nama_lengkap = COALESCE(?, nama_lengkap),
        nama_panggilan = COALESCE(?, nama_panggilan),
        jenis_kelamin = COALESCE(?, jenis_kelamin),
        tanggal_lahir = COALESCE(?, tanggal_lahir),
        alamat_lengkap = COALESCE(?, alamat_lengkap),
        kota = COALESCE(?, kota),
        bio = COALESCE(?, bio),
        diperbarui_pada = CURRENT_TIMESTAMP
      WHERE nik = ?
    `;
    
    const [result] = await db.execute(query, [
      nama_lengkap, nama_panggilan, jenis_kelamin,
      tanggal_lahir, alamat_lengkap, kota, bio, nik
    ]);
    
    return result;
  }
  
  /**
   * Update password
   */
  static async updatePassword(nik, newPassword) {
    const query = `
      UPDATE pengguna 
      SET kata_sandi = ?, diperbarui_pada = CURRENT_TIMESTAMP
      WHERE nik = ?
    `;
    
    const [result] = await db.execute(query, [newPassword, nik]);
    return result;
  }
  
  /**
   * Update last login
   */
  static async updateLastLogin(nik) {
    const query = `
      UPDATE pengguna 
      SET terakhir_login = CURRENT_TIMESTAMP
      WHERE nik = ?
    `;
    
    const [result] = await db.execute(query, [nik]);
    return result;
  }
  
  /**
   * Update profile photo
   */
  static async updatePhoto(nik, photoData) {
    const { foto_profil, jenis_foto, ukuran_foto } = photoData;
    
    const query = `
      UPDATE pengguna 
      SET 
        foto_profil = ?,
        jenis_foto = ?,
        ukuran_foto = ?,
        diperbarui_pada = CURRENT_TIMESTAMP
      WHERE nik = ?
    `;
    
    const [result] = await db.execute(query, [
      foto_profil, jenis_foto, ukuran_foto, nik
    ]);
    
    return result;
  }

  /**
   * Update online status
   */
  static async updateOnlineStatus(nik, status) {
    const query = `
      UPDATE pengguna 
      SET 
        status_online = ?,
        terakhir_aktif = CURRENT_TIMESTAMP
      WHERE nik = ?
    `;
    
    const [result] = await db.execute(query, [status, nik]);
    return result;
  }
}

module.exports = User;
