const db = require('../config/database');

/**
 * Barter Model
 * Handles barter offer/transaction operations
 */
class Barter {
  /**
   * Create new barter offer
   */
  static async create(offerData) {
    const {
      nik_penawar,
      nik_ditawar,
      id_keahlian_penawar,
      id_keahlian_diminta,
      id_skill_request,
      tipe_transaksi,      // NEW: 'barter' or 'bantuan'
      durasi_jam,
      tanggal_pelaksanaan,
      tipe_lokasi,
      detail_lokasi,
      catatan_penawar
    } = offerData;

    // Validate based on transaction type
    if (tipe_transaksi === 'barter' && !id_keahlian_penawar) {
      throw new Error('Barter transaction requires id_keahlian_penawar');
    }

    const query = `
      INSERT INTO transaksi_barter (
        nik_penawar, nik_ditawar, id_keahlian_penawar, id_keahlian_diminta,
        id_skill_request, tipe_transaksi, durasi_jam, tanggal_pelaksanaan, tipe_lokasi,
        detail_lokasi, catatan_penawar
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const [result] = await db.execute(query, [
      nik_penawar,
      nik_ditawar,
      id_keahlian_penawar || null,  // NULL for help requests
      id_keahlian_diminta,
      id_skill_request || null,
      tipe_transaksi || 'barter',
      durasi_jam,
      tanggal_pelaksanaan,
      tipe_lokasi || 'online',
      detail_lokasi,
      catatan_penawar
    ]);

    return result;
  }

  /**
   * Get offer by ID with full details
   */
  static async findById(id) {
    // Check if ID is negative (Skill Request)
    if (parseInt(id) < 0) {
      const requestId = Math.abs(parseInt(id));
      const query = `
        SELECT 
          -sr.id as id,
          CONCAT('REQ-', sr.id) as kode_transaksi,
          sr.nik_pengguna as nik_penawar,
          p.nama_lengkap as nama_penawar,
          p.foto_profil as foto_penawar,
          p.kota as kota_penawar,
          p.rating_rata_rata as rating_penawar,
          sr.dibuat_pada,
          sr.dibuat_pada as tanggal_pelaksanaan, -- Default
          'menunggu' as status, -- Map 'terbuka' to 'menunggu'
          'request' as tipe_transaksi,
          sr.nama_keahlian as skill_diminta,
          sr.deskripsi_kebutuhan as skill_request_deskripsi,
          sr.lokasi_preferensi as detail_lokasi,
          sr.durasi_estimasi,
          'Skillcoin' as skill_penawar,
          '(Menunggu)' as nama_ditawar,
          '' as nik_ditawar, -- Required field
          0 as rating_ditawar,
          'online' as tipe_lokasi, -- Default
          0 as harga_diminta,
          0 as id_keahlian_diminta, -- Required field
          sr.catatan_tambahan as catatan_penawar
        FROM skill_requests sr
        JOIN pengguna p ON sr.nik_pengguna = p.nik
        WHERE sr.id = ?
      `;

      const [rows] = await db.execute(query, [requestId]);
      
      if (rows.length > 0) {
        const offer = rows[0];
        // Convert BLOB to base64
        if (offer.foto_penawar) {
          offer.foto_penawar = offer.foto_penawar.toString('base64');
        }
        
        // Parse duration to int (simple assumption)
        offer.durasi_jam = parseInt(offer.durasi_estimasi) || 1;
        
        return offer;
      }
      return null;
    }

    const query = `
      SELECT 
        tb.*,
        p1.nama_lengkap as nama_penawar,
        p1.foto_profil as foto_penawar,
        p1.kota as kota_penawar,
        p1.rating_rata_rata as rating_penawar,
        p2.nama_lengkap as nama_ditawar,
        p2.foto_profil as foto_ditawar,
        p2.kota as kota_ditawar,
        p2.rating_rata_rata as rating_ditawar,
        COALESCE(k1.nama_keahlian, 'Skillcoin') as skill_penawar,
        k1.tingkat as tingkat_penawar,
        k1.harga_per_jam as harga_penawar,
        k2.nama_keahlian as skill_diminta,
        k2.tingkat as tingkat_diminta,
        k2.harga_per_jam as harga_diminta,
        sr.nama_keahlian as skill_request_nama,
        sr.deskripsi_kebutuhan as skill_request_deskripsi
      FROM transaksi_barter tb
      JOIN pengguna p1 ON tb.nik_penawar = p1.nik
      JOIN pengguna p2 ON tb.nik_ditawar = p2.nik
      LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
      JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
      LEFT JOIN skill_requests sr ON tb.id_skill_request = sr.id
      WHERE tb.id = ?
    `;

    const [rows] = await db.execute(query, [id]);
    
    if (rows.length > 0) {
      const offer = rows[0];
      // Convert BLOB to base64
      if (offer.foto_penawar) {
        offer.foto_penawar = offer.foto_penawar.toString('base64');
      }
      if (offer.foto_ditawar) {
        offer.foto_ditawar = offer.foto_ditawar.toString('base64');
      }
      return offer;
    }
    
    return rows[0];
  }

  /**
   * Get user's offers (sent or received)
   */
  static async getUserOffers(nik, role = 'all', status = null) {
    let query = `
      SELECT 
        tb.*,
        -- Partner info (conditional based on role)
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.nama_lengkap
          ELSE p1.nama_lengkap
        END as nama_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.foto_profil
          ELSE p1.foto_profil
        END as foto_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.kota
          ELSE p1.kota
        END as kota_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.rating_rata_rata
          ELSE p1.rating_rata_rata
        END as rating_partner,
        -- Skill info (conditional based on role)
        CASE 
          WHEN tb.nik_penawar = ? THEN k2.nama_keahlian
          ELSE COALESCE(k1.nama_keahlian, 'Skillcoin')
        END as skill_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN COALESCE(k1.nama_keahlian, 'Skillcoin')
          ELSE k2.nama_keahlian
        END as skill_own,
        -- All user info (for detail view)
        p1.nama_lengkap as nama_penawar,
        p1.foto_profil as foto_penawar,
        p1.kota as kota_penawar,
        p1.rating_rata_rata as rating_penawar,
        p2.nama_lengkap as nama_ditawar,
        p2.foto_profil as foto_ditawar,
        p2.kota as kota_ditawar,
        p2.rating_rata_rata as rating_ditawar,
        -- All skill info
        COALESCE(k1.nama_keahlian, 'Skillcoin') as skill_penawar,
        k1.tingkat as tingkat_penawar,
        k1.harga_per_jam as harga_penawar,
        k2.nama_keahlian as skill_diminta,
        k2.tingkat as tingkat_diminta,
        k2.harga_per_jam as harga_diminta,
        -- Role
        CASE 
          WHEN tb.nik_penawar = ? THEN 'sent'
          ELSE 'received'
        END as role
      FROM transaksi_barter tb
      JOIN pengguna p1 ON tb.nik_penawar = p1.nik
      JOIN pengguna p2 ON tb.nik_ditawar = p2.nik
      LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
      JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
      WHERE (tb.nik_penawar = ? OR tb.nik_ditawar = ?)
    `;

    const params = [nik, nik, nik, nik, nik, nik, nik, nik, nik];

    if (role === 'sent') {
      query += ' AND tb.nik_penawar = ?';
      params.push(nik);
    } else if (role === 'received') {
      query += ' AND tb.nik_ditawar = ?';
      params.push(nik);
    }

    if (status) {
      query += ' AND tb.status = ?';
      params.push(status);
    }

    query += ' ORDER BY tb.dibuat_pada DESC';

    console.log('[Barter.getUserOffers] Query for NIK:', nik, 'Role:', role, 'Status:', status);
    const [rows] = await db.execute(query, params);
    
    // Process barter rows
    const barterRows = rows.map(row => {
      if (row.foto_partner) row.foto_partner = row.foto_partner.toString('base64');
      if (row.foto_penawar) row.foto_penawar = row.foto_penawar.toString('base64');
      if (row.foto_ditawar) row.foto_ditawar = row.foto_ditawar.toString('base64');
      return row;
    });

    // If role is 'sent' or 'all', also fetch user's OPEN skill requests
    let requestRows = [];
    if ((!role || role === 'sent') && (!status || status === 'menunggu')) {
      const requestQuery = `
        SELECT 
          sr.id,
          CONCAT('REQ-', sr.id) as kode_transaksi,
          sr.nik_pengguna as nik_penawar,
          sr.dibuat_pada,
          sr.dibuat_pada as tanggal_pelaksanaan, -- Default to creation date
          sr.status,
          sr.nama_keahlian as skill_diminta,
          'menengah' as tingkat_diminta, -- Default
          'Skillcoin' as skill_penawar,
          'request' as tipe_transaksi,
          'sent' as role,
          '(Menunggu Partner)' as nama_ditawar,
          '' as nik_ditawar, -- Empty string for non-nullable frontend field
          0 as id_keahlian_diminta, -- Dummy ID
          0 as durasi_jam, -- Dummy duration
          'online' as tipe_lokasi,
          sr.lokasi_preferensi as detail_lokasi,
          sr.catatan_tambahan as catatan_penawar
        FROM skill_requests sr
        WHERE sr.nik_pengguna = ? 
        AND sr.status = 'terbuka'
      `;
      
      const [reqRows] = await db.execute(requestQuery, [nik]);
      
      requestRows = reqRows.map(row => ({
        ...row,
        id: -row.id, // Negative ID to distinguish
        status: 'menunggu', // Map 'terbuka' to 'menunggu' for UI
        harga_penawar: 0,
        harga_diminta: 0,
        skillcoin_ditransfer: 0,
        rating_diberikan: 0,
        rating_penawar: 0, // Ensure numeric
        rating_ditawar: 0  // Ensure numeric
      }));
    }

    // Merge and sort
    const allRows = [...barterRows, ...requestRows].sort((a, b) => {
      return new Date(b.dibuat_pada) - new Date(a.dibuat_pada);
    });

    console.log('[Barter.getUserOffers] Found', allRows.length, 'total offers (Barter + Requests)');
    
    return allRows;
  }

  /**
   * Update offer status
   */
  static async updateStatus(id, status, nikPengguna = null) {
    if (parseInt(id) < 0) {
      const requestId = Math.abs(parseInt(id));
      const query = `UPDATE skill_requests SET status = ? WHERE id = ?`;
      const [result] = await db.execute(query, [status, requestId]);
      return result;
    }

    const query = `
      UPDATE transaksi_barter 
      SET status = ?, diperbarui_pada = NOW()
      WHERE id = ?
    `;

    const [result] = await db.execute(query, [status, id]);

    // Log the action
    if (nikPengguna) {
      await this.logAction(id, nikPengguna, this.getActionFromStatus(status), `Status changed to ${status}`);
    }

    return result;
  }

  /**
   * Accept offer
   */
  static async accept(id, nik) {
    await this.updateStatus(id, 'diterima', nik);
    await this.logAction(id, nik, 'terima', 'Offer accepted');
  }

  /**
   * Reject offer
   */
  static async reject(id, nik, reason = null) {
    await this.updateStatus(id, 'ditolak', nik);
    await this.logAction(id, nik, 'tolak', reason || 'Offer rejected');
  }

  /**
   * Cancel offer
   */
  static async cancel(id, nik, reason = null) {
    await this.updateStatus(id, 'dibatalkan', nik);
    await this.logAction(id, nik, 'batalkan', reason || 'Offer cancelled');
  }

  /**
   * Delete offer (permanent)
   */
  static async delete(id) {
    // First, delete all related messages
    await db.execute(
      'DELETE FROM pesan WHERE id_transaksi = ?',
      [id]
    );
    
    // Then delete the transaction
    await db.execute(
      'DELETE FROM transaksi_barter WHERE id = ?',
      [id]
    );
  }

  /**
   * Mark as ongoing
   */
  static async markOngoing(id, nik) {
    await this.updateStatus(id, 'berlangsung', nik);
    await this.logAction(id, nik, 'mulai', 'Barter session started');
  }

  /**
   * Mark as complete
   */
  static async markComplete(id, nik) {
    await this.updateStatus(id, 'selesai', nik);
    await this.logAction(id, nik, 'selesai', 'Transaction marked as complete');
  }

  /**
   * Upload proof of completion
   */
  static async uploadProof(id, proofBase64, fileType) {
    // Convert base64 to buffer
    const proofBuffer = Buffer.from(proofBase64, 'base64');
    
    // Validate file size (max 5MB)
    const maxSize = 5 * 1024 * 1024;
    if (proofBuffer.length > maxSize) {
      throw new Error('File size too large (max 5MB)');
    }

    const query = `
      UPDATE transaksi_barter 
      SET bukti_pelaksanaan = ?, 
          jenis_bukti = ?,
          status = 'selesai',
          diperbarui_pada = NOW()
      WHERE id = ?
    `;

    const [result] = await db.execute(query, [proofBuffer, fileType, id]);
    return result;
  }

  /**
   * Get proof of completion
   */
  static async getProof(id) {
    const query = `
      SELECT bukti_pelaksanaan, jenis_bukti
      FROM transaksi_barter
      WHERE id = ?
    `;

    const [rows] = await db.execute(query, [id]);
    
    if (rows.length > 0 && rows[0].bukti_pelaksanaan) {
      return {
        proof: rows[0].bukti_pelaksanaan.toString('base64'),
        type: rows[0].jenis_bukti
      };
    }
    
    return null;
  }

  /**
   * Confirm completion (both users must confirm)
   */
  static async confirmCompletion(id, nik) {
    // Both users have confirmed (checked by controller)
    // Execute the Stored Procedure to process the transaction
    // The SP handles:
    // 1. Logic (Transfer vs Reward)
    // 2. Balances (Update & Log)
    // 3. Status (Update to 'terkonfirmasi')
    await db.execute('CALL proses_transaksi_barter(?)', [id]);
  }

  /**
   * Get transaction history
   */
  static async getHistory(nik, limit = 50) {
    const query = `
      SELECT 
        tb.*,
        -- Partner info (conditional based on role)
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.nama_lengkap
          ELSE p1.nama_lengkap
        END as nama_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.foto_profil
          ELSE p1.foto_profil
        END as foto_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.kota
          ELSE p1.kota
        END as kota_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN p2.rating_rata_rata
          ELSE p1.rating_rata_rata
        END as rating_partner,
        -- Skill info (conditional based on role)
        CASE 
          WHEN tb.nik_penawar = ? THEN k2.nama_keahlian
          ELSE k1.nama_keahlian
        END as skill_partner,
        CASE 
          WHEN tb.nik_penawar = ? THEN k1.nama_keahlian
          ELSE k2.nama_keahlian
        END as skill_own,
        -- All user info (for detail view)
        p1.nama_lengkap as nama_penawar,
        p1.foto_profil as foto_penawar,
        p1.kota as kota_penawar,
        p1.rating_rata_rata as rating_penawar,
        p2.nama_lengkap as nama_ditawar,
        p2.foto_profil as foto_ditawar,
        p2.kota as kota_ditawar,
        p2.rating_rata_rata as rating_ditawar,
        -- All skill info
        k1.nama_keahlian as skill_penawar,
        k1.tingkat as tingkat_penawar,
        k1.harga_per_jam as harga_penawar,
        k2.nama_keahlian as skill_diminta,
        k2.tingkat as tingkat_diminta,
        k2.harga_per_jam as harga_diminta,
        -- Role
        CASE 
          WHEN tb.nik_penawar = ? THEN 'sent'
          ELSE 'received'
        END as role
      FROM transaksi_barter tb
      JOIN pengguna p1 ON tb.nik_penawar = p1.nik
      JOIN pengguna p2 ON tb.nik_ditawar = p2.nik
      LEFT JOIN keahlian k1 ON tb.id_keahlian_penawar = k1.id
      JOIN keahlian k2 ON tb.id_keahlian_diminta = k2.id
      WHERE (tb.nik_penawar = ? OR tb.nik_ditawar = ?)
      AND tb.status IN ('terkonfirmasi', 'selesai', 'ditolak', 'dibatalkan')
      ORDER BY tb.diperbarui_pada DESC
      LIMIT ${Number(limit) || 50}
    `;

    const [rows] = await db.execute(query, [nik, nik, nik, nik, nik, nik, nik, nik, nik]);
    
    // Convert BLOB to base64 for all photo fields
    const processedRows = rows.map(row => {
      if (row.foto_partner) {
        row.foto_partner = row.foto_partner.toString('base64');
      }
      if (row.foto_penawar) {
        row.foto_penawar = row.foto_penawar.toString('base64');
      }
      if (row.foto_ditawar) {
        row.foto_ditawar = row.foto_ditawar.toString('base64');
      }
      return row;
    });
    
    return processedRows;
  }

  /**
   * Get transaction logs
   */
  static async getLogs(transactionId) {
    const query = `
      SELECT 
        lt.*,
        p.nama_lengkap
      FROM log_transaksi lt
      JOIN pengguna p ON lt.nik_pengguna = p.nik
      WHERE lt.id_transaksi = ?
      ORDER BY lt.created_at DESC
    `;

    const [rows] = await db.execute(query, [transactionId]);
    return rows;
  }

  /**
   * Log transaction action
   */
  static async logAction(transactionId, nik, action, description = null) {
    const query = `
      INSERT INTO log_transaksi (id_transaksi, nik_pengguna, aksi, keterangan)
      VALUES (?, ?, ?, ?)
    `;

    await db.execute(query, [transactionId, nik, action, description]);
  }

  /**
   * Check if user is participant
   */
  static async isParticipant(id, nik) {
    const query = `
      SELECT COUNT(*) as count
      FROM transaksi_barter
      WHERE id = ? AND (nik_penawar = ? OR nik_ditawar = ?)
    `;

    const [rows] = await db.execute(query, [id, nik, nik]);
    return rows[0].count > 0;
  }

  /**
   * Check if user is receiver
   */
  static async isReceiver(id, nik) {
    const query = `
      SELECT COUNT(*) as count
      FROM transaksi_barter
      WHERE id = ? AND nik_ditawar = ?
    `;

    const [rows] = await db.execute(query, [id, nik]);
    return rows[0].count > 0;
  }

  /**
   * Get action from status
   */
  static getActionFromStatus(status) {
    const mapping = {
      'menunggu': 'ajukan',
      'diterima': 'terima',
      'ditolak': 'tolak',
      'berlangsung': 'mulai',
      'selesai': 'selesai',
      'terkonfirmasi': 'konfirmasi',
      'dibatalkan': 'batalkan'
    };
    return mapping[status] || 'ajukan';
  }
}

module.exports = Barter;
