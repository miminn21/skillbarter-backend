const db = require('../config/database');

class Notification {
  // Create a notification
  static async create(nik, tipe, judul, pesan, data = null) {
    const query = `
      INSERT INTO notifications 
        (nik, tipe, judul, pesan, data)
      VALUES (?, ?, ?, ?, ?)
    `;
    
    const [result] = await db.execute(query, [
      nik,
      tipe,
      judul,
      pesan,
      data ? JSON.stringify(data) : null
    ]);
    
    return result.insertId;
  }

  // Get notifications for a user (merged from both tables)
  static async getByUser(nik, limit = 50, offset = 0, unreadOnly = false) {
    // Ensure limit and offset are safe integers
    const safeLimit = Math.max(1, Math.min(parseInt(limit) || 50, 100));
    const safeOffset = Math.max(0, parseInt(offset) || 0);
    
    // Build UNION query to combine notifications from both tables
    // Table 1: notifications (barter notifications)
    // Table 2: notifikasi (skillcoin notifications)
    let query = `
      SELECT 
        id_notifikasi as id,
        nik,
        tipe,
        judul,
        pesan,
        data,
        CAST(is_read AS UNSIGNED) as dibaca,
        created_at as dibuat_pada,
        'barter' as source
      FROM notifications
      WHERE nik = ?
      ${unreadOnly ? 'AND is_read = FALSE' : ''}
      
      UNION ALL
      
      SELECT
        id,
        nik_pengguna as nik,
        tipe,
        judul,
        isi_pesan as pesan,
        NULL as data,
        dibaca,
        dibuat_pada,
        'skillcoin' as source
      FROM notifikasi
      WHERE nik_pengguna = ?
      ${unreadOnly ? 'AND dibaca = 0' : ''}
      
      ORDER BY dibuat_pada DESC
      LIMIT ${safeLimit} OFFSET ${safeOffset}
    `;
    
    const params = [nik, nik]; // NIK for both queries
    
    const [rows] = await db.execute(query, params);
    
    // Parse JSON data (only for barter notifications)
    return rows.map(row => {
      let parsedData = null;
      if (row.source === 'barter' && row.data) {
        try {
          parsedData = typeof row.data === 'string' ? JSON.parse(row.data) : row.data;
        } catch (e) {
          console.error(`[Notification] JSON Parse Error for ID ${row.id}:`, e.message);
          parsedData = null;
        }
      }
      return {
        ...row,
        data: parsedData,
        dibaca: Boolean(row.dibaca) // Normalize to boolean
      };
    });
  }

  // Get unread count (from both tables)
  static async getUnreadCount(nik) {
    const query = `
      SELECT COUNT(*) as count FROM (
        SELECT id_notifikasi as id
        FROM notifications
        WHERE nik = ? AND is_read = FALSE
        
        UNION ALL
        
        SELECT id
        FROM notifikasi
        WHERE nik_pengguna = ? AND dibaca = 0
      ) as combined_notifications
    `;
    
    const [rows] = await db.execute(query, [nik, nik]);
    return rows[0].count;
  }

  // Mark as read
  static async markAsRead(id) {
    const query = `
      UPDATE notifications
      SET is_read = TRUE
      WHERE id_notifikasi = ?
    `;
    
    await db.execute(query, [id]);
  }

  // Mark all as read for a user
  static async markAllAsRead(nik) {
    const query = `
      UPDATE notifications
      SET is_read = TRUE
      WHERE nik = ? AND is_read = FALSE
    `;
    
    await db.execute(query, [nik]);
  }

  // Delete notification
  static async delete(id) {
    const query = 'DELETE FROM notifications WHERE id_notifikasi = ?';
    await db.execute(query, [id]);
  }

  // Delete old notifications (cleanup)
  static async deleteOld(daysOld = 30) {
    const query = `
      DELETE FROM notifications
      WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
        AND is_read = TRUE
    `;
    
    await db.execute(query, [daysOld]);
  }

  // Get notification by ID
  static async findById(id) {
    const query = 'SELECT * FROM notifications WHERE id_notifikasi = ?';
    const [rows] = await db.execute(query, [id]);
    
    if (rows.length === 0) return null;
    
    let parsedData = null;
    try {
      parsedData = rows[0].data ? JSON.parse(rows[0].data) : null;
    } catch (e) {
      console.error(`[Notification] JSON Parse Error for ID ${id}:`, e.message);
      parsedData = null;
    }

    return {
      ...rows[0],
      data: parsedData
    };
  }
}

module.exports = Notification;
