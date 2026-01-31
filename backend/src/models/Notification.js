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

  // Get notifications for a user
  static async getByUser(nik, limit = 50, offset = 0, unreadOnly = false) {
    let query = `
      SELECT *
      FROM notifications
      WHERE nik = ?
    `;
    
    const params = [nik];
    
    if (unreadOnly) {
      query += ' AND is_read = FALSE';
    }
    
    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);
    
    const [rows] = await db.execute(query, params);
    
    // Parse JSON data
    return rows.map(row => {
      let parsedData = null;
      try {
        if (row.data) {
          parsedData = typeof row.data === 'string' ? JSON.parse(row.data) : row.data;
        }
      } catch (e) {
        console.error(`[Notification] JSON Parse Error for ID ${row.id_notifikasi}:`, e.message);
        // Fallback: return null or raw string if needed, but null is safer for frontend
        parsedData = null; 
      }
      return {
        ...row,
        data: parsedData
      };
    });
  }

  // Get unread count
  static async getUnreadCount(nik) {
    const query = `
      SELECT COUNT(*) as count
      FROM notifications
      WHERE nik = ? AND is_read = FALSE
    `;
    
    const [rows] = await db.execute(query, [nik]);
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
