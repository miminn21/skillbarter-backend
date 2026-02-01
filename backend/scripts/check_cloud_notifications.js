const mysql = require('mysql2/promise');

async function checkNotifications() {
  // Connect to Railway Cloud Database
  const conn = await mysql.createConnection({
    host: 'junction.proxy.rlwy.net',
    port: 17890,
    user: 'root',
    password: 'GrqVJBWvvPCVPXIwLOqBQNmLMNLDCxFp',
    database: 'railway',
    connectTimeout: 30000
  });

  try {
    console.log('🔍 Checking Notifications in Cloud Database...\n');

    // Check if notifications table exists
    const [tables] = await conn.query("SHOW TABLES LIKE 'notifications'");
    if (tables.length === 0) {
      console.log('❌ Table "notifications" NOT FOUND in Cloud database!');
      await conn.end();
      return;
    }

    console.log('✅ Table "notifications" found\n');

    // Get table structure
    const [columns] = await conn.query('DESCRIBE notifications');
    console.log('📋 Columns:', columns.map(c => c.Field).join(', '));

    // Count total notifications
    const [count] = await conn.query('SELECT COUNT(*) as total FROM notifications');
    console.log(`\n📊 Total notifications: ${count[0].total}`);

    if (count[0].total === 0) {
      console.log('\n⚠️  Database has ZERO notifications!');
      console.log('This is why the app shows "Gagal mengambil notifikasi"');
      console.log('\nNotifications are created automatically when:');
      console.log('  - User creates a barter offer');
      console.log('  - User accepts/rejects an offer');
      console.log('  - Barter transaction is completed');
      await conn.end();
      return;
    }

    // Show sample notifications
    console.log('\n📬 Sample Notifications:');
    const [notifications] = await conn.query(`
      SELECT id_notifikasi, nik, tipe, judul, pesan, is_read, created_at
      FROM notifications
      ORDER BY created_at DESC
      LIMIT 10
    `);

    notifications.forEach((n, i) => {
      const status = n.is_read ? '✅ Read' : '🔔 Unread';
      console.log(`\n${i+1}. ${status}`);
      console.log(`   ID: ${n.id_notifikasi}`);
      console.log(`   To: ${n.nik}`);
      console.log(`   Type: ${n.tipe}`);
      console.log(`   Title: ${n.judul}`);
      console.log(`   Message: ${n.pesan}`);
      console.log(`   Date: ${n.created_at}`);
    });

    // Check notifications per user
    console.log('\n\n👥 Notifications per User:');
    const [perUser] = await conn.query(`
      SELECT nik, COUNT(*) as count, SUM(is_read = 0) as unread
      FROM notifications
      GROUP BY nik
      ORDER BY count DESC
    `);

    perUser.forEach(u => {
      console.log(`  ${u.nik}: ${u.count} total (${u.unread} unread)`);
    });

  } catch (error) {
    console.error('\n❌ Error:', error.message);
  } finally {
    await conn.end();
  }
}

checkNotifications();
