const db = require('../config/database');

class Report {
  /**
   * Create new report/help request
   */
  static async create(data) {
    const {
      nik_pelapor,
      nik_dilaporkan,
      jenis_laporan,
      deskripsi,
      bukti_gambar,
      jenis_bukti
    } = data;

    const query = `
      INSERT INTO laporan_pengguna (
        nik_pelapor, nik_dilaporkan, jenis_laporan, deskripsi, 
        bukti_gambar, jenis_bukti, status
      ) VALUES (?, ?, ?, ?, ?, ?, 'menunggu')
    `;

    const [result] = await db.execute(query, [
      nik_pelapor,
      nik_dilaporkan || null,
      jenis_laporan || 'lainnya',
      deskripsi,
      bukti_gambar || null,
      jenis_bukti || null
    ]);

    return result;
  }

  /**
   * Get reports by reporter (History)
   */
  static async findByReporter(nik) {
    const query = `
      SELECT * FROM laporan_pengguna 
      WHERE nik_pelapor = ? 
      ORDER BY dibuat_pada DESC
    `;
    const [rows] = await db.execute(query, [nik]);
    return rows;
  }
}

module.exports = Report;
