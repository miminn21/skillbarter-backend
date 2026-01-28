const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkProc() {
  console.log('🔍 Checking stored procedure definition...');
  
  let connection;
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'skillbarter_db'
    });
    
    const [rows] = await connection.query("SHOW CREATE PROCEDURE proses_transaksi_barter");
    
    if (rows.length > 0) {
      console.log('📜 Procedure Source Code:');
      console.log('---------------------------------------------------');
      console.log(rows[0]['Create Procedure']);
      console.log('---------------------------------------------------');
      
      const src = rows[0]['Create Procedure'];
      if (src.includes('tambah_skillcoin') && src.includes('Reward Barter')) {
        console.log('✅ VERIFIED: Procedure is using REWARD logic.');
      } else if (src.includes('transfer_skillcoin')) {
        console.log('❌ FATAL: Procedure is still using TRANSFER/SWAP logic!');
      } else {
        console.log('⚠️  UNKNOWN: Logic unclear. Check output.');
      }
    } else {
      console.log('❌ Procedure not found!');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (connection) await connection.end();
  }
}

checkProc();
