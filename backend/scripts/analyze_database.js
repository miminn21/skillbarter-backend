const mysql = require('mysql2/promise');

async function analyzeDatabase() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'skillbarter_db'
  });

  console.log('═══════════════════════════════════════════════════════');
  console.log('📊 ANALISA LENGKAP DATABASE LOKAL vs BACKEND CODE');
  console.log('═══════════════════════════════════════════════════════\n');

  try {
    // 1. Check Notifications Table
    console.log('1️⃣  TABEL NOTIFICATIONS (Sistem Notifikasi)');
    console.log('─────────────────────────────────────────────────────');
    
    try {
      const [notifColumns] = await conn.query('DESCRIBE notifications');
      console.log('✅ Tabel "notifications" ditemukan');
      console.log('   Kolom:', notifColumns.map(c => c.Field).join(', '));
      
      const [notifCount] = await conn.query('SELECT COUNT(*) as count FROM notifications');
      console.log(`   Jumlah data: ${notifCount[0].count} notifikasi`);
      
      if (notifCount[0].count > 0) {
        const [sample] = await conn.query('SELECT * FROM notifications LIMIT 3');
        console.log('   Sample data:');
        sample.forEach((n, i) => {
          console.log(`     ${i+1}. ID: ${n.id}, Tipe: ${n.tipe}, Untuk: ${n.nik_penerima}`);
        });
      }
    } catch (e) {
      console.log('❌ Tabel "notifications" TIDAK DITEMUKAN!');
      console.log('   Error:', e.message);
    }

    // 2. Check User/Pengguna Table
    console.log('\n2️⃣  TABEL USER/PENGGUNA (Data Pengguna)');
    console.log('─────────────────────────────────────────────────────');
    
    const userTables = ['pengguna', 'dashboard_pengguna'];
    for (const tableName of userTables) {
      try {
        const [cols] = await conn.query(`DESCRIBE ${tableName}`);
        console.log(`✅ Tabel "${tableName}" ditemukan`);
        console.log(`   Kolom:`, cols.map(c => c.Field).join(', '));
        
        const [count] = await conn.query(`SELECT COUNT(*) as count FROM ${tableName}`);
        console.log(`   Jumlah data: ${count[0].count} user`);
        
        // Check if has skillcoin column
        const skillcoinCol = cols.find(c => c.Field.toLowerCase().includes('skillcoin'));
        if (skillcoinCol) {
          console.log(`   ✅ Kolom SkillCoin: "${skillcoinCol.Field}"`);
          
          const [top3] = await conn.query(`
            SELECT nik, nama_panggilan, ${skillcoinCol.Field}
            FROM ${tableName}
            ORDER BY ${skillcoinCol.Field} DESC
            LIMIT 3
          `);
          console.log('   Top 3 Leaderboard:');
          top3.forEach((u, i) => {
            console.log(`     ${i+1}. ${u.nama_panggilan} - ${u[skillcoinCol.Field]} coins`);
          });
        } else {
          console.log('   ⚠️  Tidak ada kolom SkillCoin');
        }
      } catch (e) {
        console.log(`❌ Tabel "${tableName}" tidak ditemukan`);
      }
    }

    // 3. Check Barter Table
    console.log('\n3️⃣  TABEL BARTER/TRANSAKSI_BARTER (Transaksi Barter)');
    console.log('─────────────────────────────────────────────────────');
    
    const barterTables = ['transaksi_barter', 'barter', 'Barter'];
    for (const tableName of barterTables) {
      try {
        const [cols] = await conn.query(`DESCRIBE ${tableName}`);
        console.log(`✅ Tabel "${tableName}" ditemukan`);
        
        const [count] = await conn.query(`SELECT COUNT(*) as count FROM ${tableName}`);
        console.log(`   Jumlah data: ${count[0].count} transaksi`);
        
        // Check status column
        const statusCol = cols.find(c => c.Field.toLowerCase().includes('status'));
        if (statusCol) {
          const [statuses] = await conn.query(`
            SELECT ${statusCol.Field}, COUNT(*) as count 
            FROM ${tableName} 
            GROUP BY ${statusCol.Field}
          `);
          console.log('   Status breakdown:');
          statuses.forEach(s => {
            console.log(`     - ${s[statusCol.Field]}: ${s.count}`);
          });
        }
        break;
      } catch (e) {
        // Continue to next table name
      }
    }

    // 4. Check Triggers
    console.log('\n4️⃣  TRIGGERS (Otomasi Database)');
    console.log('─────────────────────────────────────────────────────');
    
    const [triggers] = await conn.query('SHOW TRIGGERS');
    if (triggers.length > 0) {
      console.log(`✅ Ditemukan ${triggers.length} triggers:`);
      triggers.forEach(t => {
        console.log(`   - ${t.Trigger}: ${t.Event} on ${t.Table}`);
      });
    } else {
      console.log('❌ Tidak ada triggers ditemukan!');
    }

    // 5. Check Procedures
    console.log('\n5️⃣  STORED PROCEDURES (Fungsi Database)');
    console.log('─────────────────────────────────────────────────────');
    
    const [procs] = await conn.query('SHOW PROCEDURE STATUS WHERE Db = "skillbarter_db"');
    if (procs.length > 0) {
      console.log(`✅ Ditemukan ${procs.length} procedures:`);
      procs.forEach(p => {
        console.log(`   - ${p.Name}`);
      });
    } else {
      console.log('❌ Tidak ada procedures ditemukan!');
    }

    // 6. Backend Code Expectations
    console.log('\n6️⃣  EKSPEKTASI BACKEND CODE');
    console.log('─────────────────────────────────────────────────────');
    console.log('Backend code mengharapkan:');
    console.log('   Tabel: User, Skill, Barter, Notification, SkillCoin_Transaction');
    console.log('   Kolom User: nik, nama_panggilan, total_skillcoin, rating');
    console.log('   Kolom Notification: id, nik_penerima, tipe, judul, pesan, data_json, dibaca, created_at');
    console.log('   Triggers: Untuk auto-create notifications saat barter');

    console.log('\n═══════════════════════════════════════════════════════');
    console.log('📋 KESIMPULAN');
    console.log('═══════════════════════════════════════════════════════');
    console.log('Database lokal menggunakan NAMA INDONESIA (pengguna, transaksi_barter)');
    console.log('Backend code menggunakan NAMA INGGRIS (User, Barter, Notification)');
    console.log('\n⚠️  KETIDAKCOCOKAN: Backend tidak akan bisa membaca database lokal!');
    console.log('✅ SOLUSI: Gunakan database Cloud (Railway) yang sudah sesuai struktur.');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
  } finally {
    await conn.end();
  }
}

analyzeDatabase();
