const db = require('../src/config/database');

async function check() {
  try {
    const [cols] = await db.execute("SHOW COLUMNS FROM notifications");
    console.log('Notifications Columns:', cols.map(c => c.Field));
    
    const [userCols] = await db.execute("SHOW COLUMNS FROM pengguna LIKE 'status_online'");
    console.log('User Status Online Column:', userCols);
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

check();
