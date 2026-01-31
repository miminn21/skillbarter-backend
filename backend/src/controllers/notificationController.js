const Notification = require('../models/Notification');

// Get user notifications
exports.getNotifications = async (req, res) => {
  try {
    // DEBUG LOGS
    console.log('[DEBUG NOTIF] Request received');
    console.log('[DEBUG NOTIF] req.user:', JSON.stringify(req.user));
    
    if (!req.user || !req.user.nik) {
      console.error('[DEBUG NOTIF] User not authenticated or NIK missing');
      return res.status(401).json({ success: false, message: 'Unauthorized: No NIK' });
    }

    const nik = req.user.nik;
    const limit = parseInt(req.query.limit) || 50;
    const offset = parseInt(req.query.offset) || 0;
    const unreadOnly = req.query.unread_only === 'true';

    console.log(`[DEBUG NOTIF] Fetching for NIK: ${nik}, Limit: ${limit}, Offset: ${offset}`);

    const notifications = await Notification.getByUser(nik, limit, offset, unreadOnly);
    console.log(`[DEBUG NOTIF] Got ${notifications.length} notifications`);
    
    const unreadCount = await Notification.getUnreadCount(nik);

    res.json({
      success: true,
      data: {
        notifications,
        unread_count: unreadCount,
        pagination: {
          limit,
          offset,
          total: notifications.length
        }
      }
    });
  } catch (error) {
    console.error('[DEBUG NOTIF] CRITICAL ERROR:', error);
    console.error('[DEBUG NOTIF] Stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil notifikasi',
      error: error.message
    });
  }
};

// Get unread count
exports.getUnreadCount = async (req, res) => {
  try {
    const nik = req.user.nik;
    const count = await Notification.getUnreadCount(nik);

    res.json({
      success: true,
      data: { count }
    });
  } catch (error) {
    console.error('Error getting unread count:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil jumlah notifikasi',
      error: error.message
    });
  }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const nik = req.user.nik;

    // Verify notification belongs to user
    const notification = await Notification.findById(id);
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notifikasi tidak ditemukan'
      });
    }

    if (notification.NIK !== nik) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak'
      });
    }

    await Notification.markAsRead(id);

    res.json({
      success: true,
      message: 'Notifikasi ditandai sudah dibaca'
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menandai notifikasi',
      error: error.message
    });
  }
};

// Mark all as read
exports.markAllAsRead = async (req, res) => {
  try {
    const nik = req.user.nik;
    await Notification.markAllAsRead(nik);

    res.json({
      success: true,
      message: 'Semua notifikasi ditandai sudah dibaca'
    });
  } catch (error) {
    console.error('Error marking all as read:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menandai semua notifikasi',
      error: error.message
    });
  }
};

// Delete notification
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const nik = req.user.nik;

    // Verify notification belongs to user
    const notification = await Notification.findById(id);
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notifikasi tidak ditemukan'
      });
    }

    if (notification.NIK !== nik) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak'
      });
    }

    await Notification.delete(id);

    res.json({
      success: true,
      message: 'Notifikasi berhasil dihapus'
    });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menghapus notifikasi',
      error: error.message
    });
  }
};

// Cleanup old notifications (admin/cron)
exports.cleanup = async (req, res) => {
  try {
    if (!req.user.is_admin) {
      return res.status(403).json({
        success: false,
        message: 'Akses ditolak'
      });
    }

    const daysOld = parseInt(req.query.days) || 30;
    await Notification.deleteOld(daysOld);

    res.json({
      success: true,
      message: `Notifikasi lama (>${daysOld} hari) berhasil dihapus`
    });
  } catch (error) {
    console.error('Error cleaning up notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal membersihkan notifikasi',
      error: error.message
    });
  }
};

module.exports = exports;
