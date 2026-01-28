const db = require('../config/database');

/**
 * User Detail Model
 */
class UserDetail {
  /**
   * Create user detail
   */
  static async create(nik) {
    const query = `
      INSERT INTO detail_pengguna (nik) 
      VALUES (?)
    `;
    
    const [result] = await db.execute(query, [nik]);
    return result;
  }
  
  /**
   * Update user detail
   */
  static async update(nik, detailData) {
    const {
      pekerjaan, nama_instansi, pendidikan_terakhir,
      keahlian_khusus, media_sosial, preferensi_lokasi,
      zona_waktu, bahasa
    } = detailData;
    
    // Check if detail exists
    const checkQuery = 'SELECT nik FROM detail_pengguna WHERE nik = ?';
    const [existing] = await db.execute(checkQuery, [nik]);
    
    if (existing.length === 0) {
      // Create if not exists
      await this.create(nik);
    }
    
    // Update detail
    const query = `
      UPDATE detail_pengguna 
      SET 
        pekerjaan = COALESCE(?, pekerjaan),
        nama_instansi = COALESCE(?, nama_instansi),
        pendidikan_terakhir = COALESCE(?, pendidikan_terakhir),
        keahlian_khusus = COALESCE(?, keahlian_khusus),
        media_sosial = COALESCE(?, media_sosial),
        preferensi_lokasi = COALESCE(?, preferensi_lokasi),
        zona_waktu = COALESCE(?, zona_waktu),
        bahasa = COALESCE(?, bahasa)
      WHERE nik = ?
    `;
    
    const mediaSosialJson = media_sosial ? JSON.stringify(media_sosial) : null;
    
    const [result] = await db.execute(query, [
      pekerjaan, nama_instansi, pendidikan_terakhir,
      keahlian_khusus, mediaSosialJson, preferensi_lokasi,
      zona_waktu, bahasa, nik
    ]);
    
    return result;
  }
}

module.exports = UserDetail;
