const db = require('./src/config/database');

async function debugNotificationIssue() {
  try {
    console.log('=== DEBUGGING NOTIFICATION DISPLAY ISSUE ===\n');

    // 1. Check all notifications in database
    console.log('1. All Notifications in Database:');
    const [allNotifs] = await db.query(`
      SELECT id_notifikasi, nik, tipe, judul, created_at
      FROM notifications 
      ORDER BY created_at DESC 
      LIMIT 10
    `);
    console.table(allNotifs);

    // 2. Get unique NIKs from notifications
    console.log('\n2. Unique NIKs in Notifications:');
    const [uniqueNiks] = await db.query(`
      SELECT DISTINCT nik, COUNT(*) as count
      FROM notifications
      GROUP BY nik
    `);
    console.table(uniqueNiks);

    // 3. Check if these NIKs exist in pengguna table
    console.log('\n3. Checking if NIKs exist in pengguna table:');
    for (const row of uniqueNiks) {
      const [user] = await db.query(`
        SELECT nik, nama, email
        FROM pengguna
        WHERE nik = ?
      `, [row.nik]);
      
      if (user.length > 0) {
        console.log(`✅ NIK ${row.nik} exists: ${user[0].nama} (${user[0].email})`);
      } else {
        console.log(`❌ NIK ${row.nik} NOT FOUND in pengguna table!`);
      }
    }

    // 4. Test query that frontend uses
    console.log('\n4. Testing Frontend Query (for each NIK):');
    for (const row of uniqueNiks) {
      const [testResult] = await db.query(`
        SELECT * FROM notifications 
        WHERE nik = ? 
        ORDER BY created_at DESC 
        LIMIT 10
      `, [row.nik]);
      
      console.log(`\nNIK ${row.nik}: Found ${testResult.length} notifications`);
      if (testResult.length > 0) {
        console.log('Sample:', {
          id: testResult[0].id_notifikasi,
          tipe: testResult[0].tipe,
          judul: testResult[0].judul
        });
      }
    }

    // 5. Check for SQL errors in query
    console.log('\n5. Testing Query with LIMIT and OFFSET:');
    try {
      const testNik = uniqueNiks[0]?.nik;
      if (testNik) {
        const [result] = await db.execute(`
          SELECT * FROM notifications 
          WHERE nik = ? 
          ORDER BY created_at DESC 
          LIMIT ? OFFSET ?
        `, [testNik, 50, 0]);
        
        console.log(`✅ Query successful! Found ${result.length} notifications`);
      }
    } catch (queryError) {
      console.log('❌ Query failed:', queryError.message);
      console.log('SQL State:', queryError.sqlState);
    }

    console.log('\n=== DIAGNOSTIC COMPLETE ===');
    console.log('\n📋 SUMMARY:');
    console.log(`- Total notifications: ${allNotifs.length}`);
    console.log(`- Unique users with notifications: ${uniqueNiks.length}`);
    console.log('\n💡 NEXT STEPS:');
    console.log('1. Login to app with one of the NIKs above');
    console.log('2. Check if notifications appear');
    console.log('3. If not, check backend console for [DEBUG NOTIF] logs');
    
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

debugNotificationIssue();
