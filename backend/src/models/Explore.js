const db = require('../config/database');

class Explore {
  /**
   * Search skills with filters and pagination
   */
  static async searchSkills(filters = {}) {
    const {
      kategori,
      tipe,
      tingkat,
      search,
      page = 1,
      limit = 20
    } = filters;

    const offset = (page - 1) * limit;
    let query = `
      SELECT 
        k.id,
        k.nik_pengguna,
        k.nama_keahlian,
        k.id_kategori,
        k.tipe,
        k.tingkat,
        k.pengalaman,
        k.deskripsi,
        k.harga_per_jam,
        k.status_verifikasi,
        k.dibuat_pada,
        DATE_FORMAT(k.tanggal_berakhir, '%Y-%m-%d') as tanggal_berakhir,
        k.gambar_skill,
        k.portofolio_gambar,
        p.nama_panggilan as nama_pemilik,
        p.foto_profil,
        p.rating_rata_rata,
        p.jumlah_transaksi,
        ks.nama_kategori,
        ks.ikon as kategori_ikon
      FROM keahlian k
      INNER JOIN pengguna p ON k.nik_pengguna = p.nik
      INNER JOIN kategori_skill ks ON k.id_kategori = ks.id
      WHERE 1=1
    `;

    const params = [];

    // Apply filters
    if (kategori) {
      query += ' AND k.id_kategori = ?';
      params.push(kategori);
    }

    if (tipe) {
      query += ' AND k.tipe = ?';
      params.push(tipe);
    }

    if (tingkat) {
      query += ' AND k.tingkat = ?';
      params.push(tingkat);
    }

    if (search) {
      query += ' AND (k.nama_keahlian LIKE ? OR k.deskripsi LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }

    // Get total count for pagination
    const countQuery = `SELECT COUNT(*) as total FROM keahlian k WHERE 1=1${
      kategori ? ' AND k.id_kategori = ?' : ''
    }${tipe ? ' AND k.tipe = ?' : ''}${tingkat ? ' AND k.tingkat = ?' : ''}${
      search ? ' AND (k.nama_keahlian LIKE ? OR k.deskripsi LIKE ?)' : ''
    }`;
    
    const countParams = [];
    if (kategori) countParams.push(kategori);
    if (tipe) countParams.push(tipe);
    if (tingkat) countParams.push(tingkat);
    if (search) countParams.push(`%${search}%`, `%${search}%`);

    const [countResult] = await db.query(countQuery, countParams);
    const total = countResult[0].total;

    // Add pagination - convert to integers to avoid SQL quotes
    query += ' ORDER BY k.dibuat_pada DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const [skills] = await db.query(query, params);

    return {
      skills,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }
}

module.exports = Explore;


