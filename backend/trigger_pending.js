const mysql = require('mysql2/promise');
require('dotenv').config();

async function triggerPending() {
  console.log('🔍 Checking for stuck transactions (Both Confirmed but Status != Terkonfirmasi)...');
  
  let connection;
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'skillbarter_db'
    });
    
    // Find stuck transactions
    const [rows] = await connection.execute(`
      SELECT t.id, t.kode_transaksi, t.status,
             (SELECT COUNT(*) FROM barter_confirmations WHERE id_barter = t.id AND konfirmasi_selesai = 1) as conf_count
      FROM transaksi_barter t
      WHERE t.status IN ('berlangsung', 'selesai')
      HAVING conf_count = 2
    `);
    
    if (rows.length > 0) {
      console.log(`⚠️ Found ${rows.length} stuck transactions. Triggering SP...`);
      
      for (const tx of rows) {
        console.log(`👉 Processing ${tx.kode_transaksi} (ID: ${tx.id})...`);
        await connection.execute('CALL proses_transaksi_barter(?)', [tx.id]);
        console.log('   ✅ Triggered successfully.');
      }
      console.log('🎉 All pending transactions have been pushed!');
    } else {
      console.log('✅ No stuck transactions found.');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (connection) await connection.end();
  }
}

triggerPending();
