require('dotenv').config();
const mysql = require('mysql2/promise');

async function checkNotifications() {
  const connection = await mysql.createConnection({
    host: process.env.DATABASE_HOST,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
    port: process.env.DATABASE_PORT || 3306
  });

  console.log('✅ Connected to Railway database\n');

  // Check if notifications table exists
  const [tables] = await connection.execute(
    "SHOW TABLES LIKE 'notifications'"
  );
  
  if (tables.length === 0) {
    console.log('❌ Table "notifications" NOT FOUND!');
    console.log('   Notification system will NOT work!\n');
    await connection.end();
    return;
  }

  console.log('✅ Table "notifications" exists\n');

  // Check table structure
  const [columns] = await connection.execute(
    "DESCRIBE notifications"
  );
  
  console.log('📋 Table Structure:');
  columns.forEach(col => {
    console.log(`   - ${col.Field} (${col.Type}) ${col.Null === 'NO' ? 'NOT NULL' : 'NULL'}`);
  });
  console.log('');

  // Count total notifications
  const [countResult] = await connection.execute(
    'SELECT COUNT(*) as total FROM notifications'
  );
  console.log(`📊 Total notifications: ${countResult[0].total}\n`);

  // Get recent notifications
  const [recent] = await connection.execute(
    'SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10'
  );

  if (recent.length > 0) {
    console.log('📬 Recent Notifications:');
    recent.forEach((notif, idx) => {
      console.log(`\n${idx + 1}. ID: ${notif.id_notifikasi}`);
      console.log(`   NIK: ${notif.nik}`);
      console.log(`   Type: ${notif.tipe}`);
      console.log(`   Title: ${notif.judul}`);
      console.log(`   Message: ${notif.pesan}`);
      console.log(`   Read: ${notif.is_read ? 'Yes' : 'No'}`);
      console.log(`   Created: ${notif.created_at}`);
    });
  } else {
    console.log('📭 No notifications found in database');
    console.log('   This means:');
    console.log('   1. No barter offers have been sent yet, OR');
    console.log('   2. Notification creation is failing silently');
  }

  console.log('\n');

  // Check for any errors in notification creation
  console.log('🔍 Checking for NIK in User table...');
  const [users] = await connection.execute(
    'SELECT nik, nama FROM User LIMIT 5'
  );
  
  if (users.length > 0) {
    console.log('✅ Sample users:');
    users.forEach(user => {
      console.log(`   - ${user.nik}: ${user.nama}`);
    });
  }

  await connection.end();
  console.log('\n✅ Analysis complete!');
}

checkNotifications().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
