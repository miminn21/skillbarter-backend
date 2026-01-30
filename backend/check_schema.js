const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function checkSchema() {
    console.log('📡 MEMERIKSA KELENGKAPAN "OTAK" DATABASE (TRIGGER/VIEW/PROCEDURE)...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        
        // 1. Cek User (Data Dasar)
        const [users] = await connection.query("SELECT COUNT(*) as total FROM pengguna");
        console.log(`\n✅ DATA PENGGUNA: ${users[0].total} (Aman)`);

        // 2. Cek Views (Mata Cerdas)
        const [views] = await connection.query("SHOW FULL TABLES WHERE Table_type = 'VIEW'");
        console.log(`\n👀 VIEW (Tabel Pintar): ${views.length} ditemukan`);
        views.forEach(v => console.log(`   - ${Object.values(v)[0]}`));

        // 3. Cek Procedures (Mesin Otomatis)
        const [procs] = await connection.query("SHOW PROCEDURE STATUS WHERE Db = 'railway'");
        console.log(`\n⚙️  PROCEDURE (Prosess Otomatis): ${procs.length} ditemukan`);
        procs.forEach(p => console.log(`   - ${p.Name}`));

        // 4. Cek Functions (Rumus Pintar)
        const [funcs] = await connection.query("SHOW FUNCTION STATUS WHERE Db = 'railway'");
        console.log(`\n🧮 FUNCTION: ${funcs.length} ditemukan`);
        funcs.forEach(f => console.log(`   - ${f.Name}`));

        // 5. Cek Triggers (Pemicu Reaksi)
        const [triggers] = await connection.query("SHOW TRIGGERS");
        console.log(`\n🔫 TRIGGER: ${triggers.length} ditemukan`);
        triggers.forEach(t => console.log(`   - ${t.Trigger}`));

        console.log('\n----------------------------------------');
        if (views.length > 0 && procs.length > 0 && triggers.length > 0) {
             console.log('KESIMPULAN: LENGKAP! Semua fitur canggih sudah terpasang.');
        } else {
             console.log('KESIMPULAN: BELUM LENGKAP! Ada bagian "otak" yang hilang.');
        }

    } catch (err) {
        console.error('❌ ERROR:', err.message);
    } finally {
        if (connection) await connection.end();
    }
}

checkSchema();
