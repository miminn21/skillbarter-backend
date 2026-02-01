const db = require('./src/config/database');

async function debugNotifications() {
  try {
    console.log('=== DEBUGGING NOTIFICATION SYSTEM ===\n');

    // 1. Check recent barter transactions
    console.log('1. Recent Barter Transactions:');
    const [barters] = await db.query(`
      SELECT id, nik_penawar, nik_ditawar, status, dibuat_pada, diperbarui_pada
      FROM transaksi_barter 
      ORDER BY dibuat_pada DESC 
      LIMIT 5
    `);
    console.table(barters);

    // 2. Check if notifications were created
    console.log('\n2. Recent Notifications:');
    const [notifications] = await db.query(`
      SELECT id_notifikasi, nik, tipe, judul, pesan, created_at
      FROM notifications 
      ORDER BY created_at DESC 
      LIMIT 5
    `);
    
    if (notifications.length === 0) {
      console.log('❌ NO NOTIFICATIONS FOUND!');
      console.log('This means notification creation functions are NOT being called!\n');
    } else {
      console.table(notifications);
    }

    // 3. Count notifications by type
    console.log('\n3. Notification Count by Type:');
    const [typeCounts] = await db.query(`
      SELECT tipe, COUNT(*) as count
      FROM notifications
      GROUP BY tipe
    `);
    console.table(typeCounts);

    // 4. Check if there are any rejected offers
    console.log('\n4. Checking for Rejected Offers:');
    const [rejected] = await db.query(`
      SELECT id, nik_penawar, nik_ditawar, status, dibuat_pada
      FROM transaksi_barter 
      WHERE status = 'ditolak'
      ORDER BY dibuat_pada DESC
      LIMIT 3
    `);
    
    if (rejected.length > 0) {
      console.log('Found rejected offers:');
      console.table(rejected);
      
      // Check if notifications were created for these
      for (const offer of rejected) {
        const [notif] = await db.query(`
          SELECT * FROM notifications 
          WHERE JSON_EXTRACT(data, '$.id_barter') = ? 
          AND tipe = 'offer_rejected'
        `, [offer.id]);
        
        if (notif.length === 0) {
          console.log(`❌ NO NOTIFICATION for rejected offer ID ${offer.id}`);
        } else {
          console.log(`✅ Notification exists for offer ID ${offer.id}`);
        }
      }
    } else {
      console.log('No rejected offers found');
    }

    console.log('\n=== DIAGNOSTIC COMPLETE ===');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

debugNotifications();
