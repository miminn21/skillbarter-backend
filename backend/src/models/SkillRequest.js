const db = require('../config/database');

/**
 * Skill Request Model
 * Handles skill requests (skills that users are looking for)
 */
class SkillRequest {
  /**
   * Get user's skill requests
   */
  static async getUserRequests(nik, status = null) {
    let query = `
      SELECT 
        sr.*,
        sc.nama_kategori,
        sc.ikon as kategori_ikon
      FROM skill_requests sr
      JOIN kategori_skill sc ON sr.id_kategori = sc.id
      WHERE sr.nik_pengguna = ?
    `;
    
    const params = [nik];
    
    if (status) {
      query += ' AND sr.status = ?';
      params.push(status);
    }
    
    query += ' ORDER BY sr.dibuat_pada DESC';
    
    const [rows] = await db.execute(query, params);
    return rows;
  }
  
  /**
   * Get request by ID
   */
  static async findById(id) {
    const query = `
      SELECT 
        sr.*,
        sc.nama_kategori,
        sc.ikon as kategori_ikon,
        p.nama_lengkap as nama_pemohon,
        p.foto_profil,
        p.kota as lokasi,
        p.rating_rata_rata as trust_score
      FROM skill_requests sr
      JOIN kategori_skill sc ON sr.id_kategori = sc.id
      JOIN pengguna p ON sr.nik_pengguna = p.nik
      WHERE sr.id = ?
    `;
    
    const [rows] = await db.execute(query, [id]);
    return rows[0];
  }
  
  /**
   * Create new skill request
   */
  static async create(requestData) {
    const {
      nik_pengguna, id_kategori, nama_keahlian,
      deskripsi_kebutuhan, tingkat_keahlian_diinginkan,
      durasi_estimasi, lokasi_preferensi, catatan_tambahan
    } = requestData;
    
    const query = `
      INSERT INTO skill_requests (
        nik_pengguna, id_kategori, nama_keahlian,
        deskripsi_kebutuhan, tingkat_keahlian_diinginkan,
        durasi_estimasi, lokasi_preferensi, catatan_tambahan
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    const [result] = await db.execute(query, [
      nik_pengguna, id_kategori, nama_keahlian,
      deskripsi_kebutuhan, tingkat_keahlian_diinginkan || 'menengah',
      durasi_estimasi, lokasi_preferensi, catatan_tambahan
    ]);
    
    return result;
  }
  
  /**
   * Update skill request
   */
  static async update(id, requestData) {
    const {
      nama_keahlian, deskripsi_kebutuhan, tingkat_keahlian_diinginkan,
      durasi_estimasi, lokasi_preferensi, catatan_tambahan, status
    } = requestData;
    
    const query = `
      UPDATE skill_requests 
      SET 
        nama_keahlian = COALESCE(?, nama_keahlian),
        deskripsi_kebutuhan = COALESCE(?, deskripsi_kebutuhan),
        tingkat_keahlian_diinginkan = COALESCE(?, tingkat_keahlian_diinginkan),
        durasi_estimasi = COALESCE(?, durasi_estimasi),
        lokasi_preferensi = COALESCE(?, lokasi_preferensi),
        catatan_tambahan = COALESCE(?, catatan_tambahan),
        status = COALESCE(?, status)
      WHERE id = ?
    `;
    
    const [result] = await db.execute(query, [
      nama_keahlian, deskripsi_kebutuhan, tingkat_keahlian_diinginkan,
      durasi_estimasi, lokasi_preferensi, catatan_tambahan, status, id
    ]);
    
    return result;
  }
  
  /**
   * Delete skill request
   */
  static async delete(id) {
    const query = 'DELETE FROM skill_requests WHERE id = ?';
    const [result] = await db.execute(query, [id]);
    return result;
  }
  
  /**
   * Update request status
   */
  static async updateStatus(id, status) {
    const query = 'UPDATE skill_requests SET status = ? WHERE id = ?';
    const [result] = await db.execute(query, [status, id]);
    return result;
  }
  
  /**
   * Check if user owns request
   */
  static async isOwner(id, nik) {
    const query = 'SELECT nik_pengguna FROM skill_requests WHERE id = ?';
    const [rows] = await db.execute(query, [id]);
    
    if (rows.length === 0) return false;
    return rows[0].nik_pengguna === nik;
  }
  
  /**
   * Get all open requests (for explore/browse)
   */
  static async getOpenRequests(filters = {}) {
    let query = `
      SELECT 
        sr.*,
        sc.nama_kategori,
        sc.ikon as kategori_ikon,
        p.nama_lengkap,
        p.foto_profil,
        p.kota as lokasi,
        p.rating_rata_rata as trust_score
      FROM skill_requests sr
      JOIN kategori_skill sc ON sr.id_kategori = sc.id
      JOIN pengguna p ON sr.nik_pengguna = p.nik
      WHERE sr.status = 'terbuka'
      AND p.status_aktif = TRUE
    `;
    
    const params = [];
    
    if (filters.id_kategori) {
      query += ' AND sr.id_kategori = ?';
      params.push(filters.id_kategori);
    }
    
    if (filters.tingkat_keahlian) {
      query += ' AND sr.tingkat_keahlian_diinginkan = ?';
      params.push(filters.tingkat_keahlian);
    }
    
    if (filters.lokasi) {
      query += ' AND (sr.lokasi_preferensi LIKE ? OR p.kota LIKE ?)';
      const lokasi = `%${filters.lokasi}%`;
      params.push(lokasi, lokasi);
    }
    
    query += ' ORDER BY sr.dibuat_pada DESC';
    
    if (filters.limit) {
      query += ' LIMIT ?';
      params.push(parseInt(filters.limit));
    }
    
    const [rows] = await db.execute(query, params);
    return rows;
  }
}

module.exports = SkillRequest;
