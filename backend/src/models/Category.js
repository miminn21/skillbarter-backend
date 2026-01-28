const db = require('../config/database');

/**
 * Category Model
 */
class Category {
  /**
   * Get all active categories
   */
  static async getAll() {
    const query = `
      SELECT id, nama_kategori, ikon, deskripsi, urutan_tampil
      FROM kategori_skill
      WHERE status_aktif = TRUE
      ORDER BY urutan_tampil ASC, nama_kategori ASC
    `;
    
    const [rows] = await db.execute(query);
    return rows;
  }
  
  /**
   * Get category by ID
   */
  static async findById(id) {
    const query = `
      SELECT id, nama_kategori, ikon, deskripsi, urutan_tampil
      FROM kategori_skill
      WHERE id = ? AND status_aktif = TRUE
    `;
    
    const [rows] = await db.execute(query, [id]);
    return rows[0];
  }
  
  /**
   * Alias for getAll (for compatibility)
   */
  static async findAll() {
    return await this.getAll();
  }
  
  /**
   * Get categories with skill count
   */
  static async findAllWithCount() {
    const query = `
      SELECT 
        ks.id,
        ks.nama_kategori,
        ks.ikon,
        ks.deskripsi,
        ks.urutan_tampil,
        COUNT(k.id) as jumlah_skill
      FROM kategori_skill ks
      LEFT JOIN keahlian k ON ks.id = k.id_kategori
      WHERE ks.status_aktif = TRUE
      GROUP BY ks.id, ks.nama_kategori, ks.ikon, ks.deskripsi, ks.urutan_tampil
      ORDER BY ks.urutan_tampil ASC, ks.nama_kategori ASC
    `;
    
    const [rows] = await db.execute(query);
    return rows;
  }
}

module.exports = Category;
