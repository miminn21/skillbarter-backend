require('dotenv').config({ path: '../.env' });
const mysql = require('mysql2/promise');

async function debugStatus() {
  try {
    const db = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME
    });

    console.log('Connected to database.');

    // Check System Time and DB Time
    const [timeRows] = await db.execute('SELECT NOW() as db_time, @@global.time_zone, @@session.time_zone');
    console.log('DB Time Info:', timeRows[0]);
    console.log('App (Node) Time:', new Date().toString());

    // Check Users
    const query = `
      SELECT 
        nik, 
        nama_lengkap, 
        status_online, 
        terakhir_login,
        terakhir_aktif
      FROM pengguna
      WHERE nama_lengkap LIKE '%Ujang%'
    `;

    const [rows] = await db.execute(query);
    console.log('\nUser Statuses (JSON):');
    console.log(JSON.stringify(rows, null, 2));

    await db.end();
  } catch (err) {
    console.error('Error:', err);
  }
}

debugStatus();
