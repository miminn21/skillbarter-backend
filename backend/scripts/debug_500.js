require('dotenv').config({ path: '../.env' });
const db = require('../src/config/database');
const Notification = require('../src/models/Notification');
const User = require('../src/models/User');

async function runDebug() {
  console.log('--- Starting Debug 500 Error ---');

  try {
    // 1. Check User.updateOnlineStatus (Executed on Login/Heartbeat)
    console.log('\nTesting User.updateOnlineStatus...');
    // Use a NIK that likely doesn't exist but query structure is tested
    await User.updateOnlineStatus('DEBUG_USER', 'online'); 
    console.log('✅ User.updateOnlineStatus successful (or at least valid SQL)');
  } catch (err) {
    console.error('❌ User.updateOnlineStatus FAILED:', err.message);
  }

  try {
    // 2. Check Notification.getByUser (Executed on Dashboard)
    console.log('\nTesting Notification.getByUser...');
    // We need a valid NIK to get data, but even with invalid NIK it should run SQL
    // Let's try to get ONE user first to be safe
    const [users] = await db.execute('SELECT nik FROM pengguna LIMIT 1');
    if (users.length > 0) {
      const nik = users[0].nik;
      console.log(`Using NIK: ${nik}`);
      
      const notifs = await Notification.getByUser(nik, 5, 0);
      console.log(`✅ Notification.getByUser successful. Got ${notifs.length} notifications.`);
      
      // Check JSON parsing if any data exists
      notifs.forEach((n, i) => {
        try {
          if (n.data && typeof n.data === 'string') {
             JSON.parse(n.data);
          }
        } catch (e) {
             console.error(`❌ JSON Parse Error at index ${i}:`, e.message);
        }
      });

    } else {
       console.log('⚠️ No users found to test Notification.');
    }

  } catch (err) {
    console.error('❌ Notification.getByUser FAILED:', err.message);
  }

  console.log('\n--- Debug Completed ---');
  process.exit();
}

runDebug();
