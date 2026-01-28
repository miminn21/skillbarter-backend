const mysql = require('mysql2/promise');
require('dotenv').config();

async function checkTransaction() {
  console.log('🔍 Checking transaction BR-20260123-007...');
  
  let connection;
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'skillbarter_db'
    });
    
    // 1. Find Transaction ID
    const [rows] = await connection.execute(
      "SELECT id, nik_penawar, nik_ditawar, status, durasi_jam, id_keahlian_penawar, id_keahlian_diminta FROM transaksi_barter WHERE kode_transaksi = 'BR-20260123-007'"
    );
    
    if (rows.length === 0) {
      console.log('❌ Transaction not found!');
      return;
    }
    
    const tx = rows[0];
    console.log('📄 Transaction Found:', tx);
    
    // 2. Check Skill Prices
    if (tx.id_keahlian_penawar) {
      const [k1] = await connection.execute("SELECT id, nama_keahlian, harga_per_jam FROM keahlian WHERE id = ?", [tx.id_keahlian_penawar]);
      console.log('   Skill Penawar:', k1[0]);
    }
    if (tx.id_keahlian_diminta) {
      const [k2] = await connection.execute("SELECT id, nama_keahlian, harga_per_jam FROM keahlian WHERE id = ?", [tx.id_keahlian_diminta]);
      console.log('   Skill Diminta:', k2[0]);
    }

    // 3. Check SkillCoin History (Logs)
    // Note: transaksi_skillcoin doesn't have id_transaksi column usually? Based on schema I saw earlier it does?
    // Let's check schema/history
    const [history] = await connection.execute(
        "SELECT * FROM transaksi_skillcoin ORDER BY id DESC LIMIT 10"
    );
    console.log('💰 Recent SkillCoin Transactions:');
    history.forEach(h => console.log(`   [${h.id}] User: ${h.nik_pengguna} Amount: ${h.jumlah} Type: ${h.jenis} Balance: ${h.saldo_sesudah} Desc: ${h.keterangan}`));

    // 4. Check Users
    const [u1] = await connection.execute("SELECT nik, nama_lengkap, saldo_skillcoin FROM pengguna WHERE nik = ?", [tx.nik_penawar]);
    const [u2] = await connection.execute("SELECT nik, nama_lengkap, saldo_skillcoin FROM pengguna WHERE nik = ?", [tx.nik_ditawar]);
    
    console.log('Title: Users Status');
    console.log('   User 1 (Penawar):', u1[0]);
    console.log('   User 2 (Ditawar):', u2[0]);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    if (connection) await connection.end();
  }
}

checkTransaction();
