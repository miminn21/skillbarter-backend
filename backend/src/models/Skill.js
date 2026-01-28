const db = require('../config/database');

/**
 * Skill Model
 */
class Skill {
  /**
   * Get user's skills
   */
  static async getUserSkills(nik, tipe = null) {
    let query = `
      SELECT 
        k.*,
        DATE_FORMAT(k.tanggal_berakhir, '%Y-%m-%d') as tanggal_berakhir,
        ks.nama_kategori,
        ks.ikon as kategori_ikon
      FROM keahlian k
      JOIN kategori_skill ks ON k.id_kategori = ks.id
      WHERE k.nik_pengguna = ?
    `;
    
    const params = [nik];
    
    if (tipe) {
      query += ' AND k.tipe = ?';
      params.push(tipe);
    }
    
    query += ' ORDER BY k.dibuat_pada DESC';
    
    const [rows] = await db.execute(query, params);
    return rows;
  }
  
  /**
   * Get skill by ID
   */
  static async findById(id) {
    const query = `
      SELECT 
        k.*,
        DATE_FORMAT(k.tanggal_berakhir, '%Y-%m-%d') as tanggal_berakhir,
        ks.nama_kategori,
        ks.ikon as kategori_ikon,
        p.nama_panggilan as nama_pemilik
      FROM keahlian k
      JOIN kategori_skill ks ON k.id_kategori = ks.id
      JOIN pengguna p ON k.nik_pengguna = p.nik
      WHERE k.id = ?
    `;
    
    const [rows] = await db.execute(query, [id]);
    return rows[0];
  }
  
  /**
   * Create new skill
   */
  static async create(skillData) {
    const {
      nik_pengguna, nama_keahlian, id_kategori, tipe,
      tingkat, pengalaman, deskripsi, harga_per_jam, link_portofolio,
      tanggal_berakhir, gambar_skill, jenis_gambar_skill
    } = skillData;
    
    console.log('[Skill.create] Creating skill with data:', {
      nik_pengguna,
      nama_keahlian,
      id_kategori,
      tipe,
      tingkat: tingkat || 'menengah',
      pengalaman,
      deskripsi,
      harga_per_jam: harga_per_jam || 1,
      link_portofolio,
      tanggal_berakhir: tanggal_berakhir || null,
      has_image: !!gambar_skill
    });
    
    const query = `
      INSERT INTO keahlian (
        nik_pengguna, nama_keahlian, id_kategori, tipe,
        tingkat, pengalaman, deskripsi, harga_per_jam, link_portofolio, 
        tanggal_berakhir, gambar_skill, jenis_gambar_skill
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    try {
      const params = [
        nik_pengguna, 
        nama_keahlian, 
        id_kategori, 
        tipe,
        tingkat || 'menengah', 
        pengalaman !== undefined ? pengalaman : null, 
        deskripsi !== undefined ? deskripsi : null,
        harga_per_jam || 1, 
        link_portofolio !== undefined ? link_portofolio : null, 
        tanggal_berakhir || null,
        gambar_skill !== undefined ? gambar_skill : null, 
        jenis_gambar_skill !== undefined ? jenis_gambar_skill : null
      ];

      const [result] = await db.execute(query, params);
      
      console.log('[Skill.create] Success! Insert ID:', result.insertId);
      return result;
    } catch (err) {
      console.error('[Skill.create] Database error:', err);
      console.error('[Skill.create] SQL State:', err.sqlState);
      throw err;
    }
  }
  
  /**
   * Update skill
   */
  static async update(id, skillData) {
    const {
      nama_keahlian, id_kategori, tingkat,
      pengalaman, deskripsi, harga_per_jam, link_portofolio,
      gambar_skill, jenis_gambar_skill
    } = skillData;
    
    const query = `
      UPDATE keahlian 
      SET 
        nama_keahlian = COALESCE(?, nama_keahlian),
        id_kategori = COALESCE(?, id_kategori),
        tingkat = COALESCE(?, tingkat),
        pengalaman = COALESCE(?, pengalaman),
        deskripsi = COALESCE(?, deskripsi),
        harga_per_jam = COALESCE(?, harga_per_jam),
        link_portofolio = COALESCE(?, link_portofolio),
        gambar_skill = COALESCE(?, gambar_skill),
        jenis_gambar_skill = COALESCE(?, jenis_gambar_skill)
      WHERE id = ?
    `;
    
    const params = [
      nama_keahlian !== undefined ? nama_keahlian : null,
      id_kategori !== undefined ? id_kategori : null,
      tingkat !== undefined ? tingkat : null,
      pengalaman !== undefined ? pengalaman : null,
      deskripsi !== undefined ? deskripsi : null,
      harga_per_jam !== undefined ? harga_per_jam : null,
      link_portofolio !== undefined ? link_portofolio : null,
      gambar_skill !== undefined ? gambar_skill : null,
      jenis_gambar_skill !== undefined ? jenis_gambar_skill : null,
      id
    ];
    
    const [result] = await db.execute(query, params);
    
    return result;
  }
  
  /**
   * Delete skill
   */
  static async delete(id) {
    const query = 'DELETE FROM keahlian WHERE id = ?';
    const [result] = await db.execute(query, [id]);
    return result;
  }
  
  /**
   * Update portfolio image
   */
  static async updatePortfolio(id, portfolioData) {
    const { portofolio_gambar, jenis_portofolio } = portfolioData;
    
    const query = `
      UPDATE keahlian 
      SET 
        portofolio_gambar = ?,
        jenis_portofolio = ?
      WHERE id = ?
    `;
    
    const [result] = await db.execute(query, [
      portofolio_gambar, jenis_portofolio, id
    ]);
    
    return result;
  }
  
  /**
   * Verify skill
   */
  static async verify(id) {
    const query = `
      UPDATE keahlian 
      SET status_verifikasi = TRUE
      WHERE id = ?
    `;
    
    const [result] = await db.execute(query, [id]);
    return result;
  }
  
  /**
   * Check if user owns skill
   */
  static async isOwner(id, nik) {
    const query = 'SELECT nik_pengguna FROM keahlian WHERE id = ?';
    const [rows] = await db.execute(query, [id]);
    
    if (rows.length === 0) return false;
    return rows[0].nik_pengguna === nik;
  }
  
  /**
   * Check if skill is expired
   */
  static isExpired(skill) {
    if (!skill || !skill.tanggal_berakhir) return false;
    
    const today = new Date();
    const expiry = new Date(skill.tanggal_berakhir);
    
    // Set both to start of day for fair comparison
    today.setHours(0, 0, 0, 0);
    expiry.setHours(0, 0, 0, 0);
    
    return today > expiry;
  }
}

module.exports = Skill;
