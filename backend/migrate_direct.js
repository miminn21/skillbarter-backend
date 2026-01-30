const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db', multipleStatements: true
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway', multipleStatements: true
};

async function migrateTotalClone() {
    console.log('🚀 MIGRASI TOTAL (STRUKTUR + DATA)');
    console.log('-----------------------------------');
    let localConn, cloudConn;

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        // 1. Matikan Keselamatan (FK Check)
        await cloudConn.query('SET FOREIGN_KEY_CHECKS = 0');

        // 2. Ambil Daftar Tabel Lokal
        const [tables] = await localConn.query("SHOW FULL TABLES WHERE Table_Type = 'BASE TABLE'");
        const tableNames = tables.map(t => Object.values(t)[0]);

        // 3. Loop Cloning
        for (const table of tableNames) {
            console.log(`\n📦 KLONING TABEL: ${table.toUpperCase()}`);

            // A. Ambil CREATE STATEMENT dari Lokal
            // Ini akan memastikan kolom baru (gambar_skill, dll) IKUT TERBAWA
            const [createRows] = await localConn.query(`SHOW CREATE TABLE ${table}`);
            let createSQL = createRows[0]['Create Table'];

            // Bersihkan syntax 'CREATE TABLE' agar kompatibel (timpa IF NOT EXISTS)
            // Hapus AUTO_INCREMENT spesifik agar tidak konflik (opsional, tapi aman)
            // CRITICAL: Hapus nama database lokal (`skillbarter_db`.) agar tidak error di Cloud
            createSQL = createSQL.replace(/AUTO_INCREMENT=\d+ /g, '');
            createSQL = createSQL.replace(/`skillbarter_db`\./g, ''); 
            createSQL = createSQL.replace(/skillbarter_db\./g, '');

            try {
                // B. Re-Create di Cloud
                await cloudConn.query(`DROP TABLE IF EXISTS ${table}`);
                console.log(`   - 🔨 Struktur Lama Dihapus.`);
                
                await cloudConn.query(createSQL);
                console.log(`   - 🏗️ Struktur Baru (Update) Dibuat.`);

                // C. Insert Data
                const [rows] = await localConn.query(`SELECT * FROM ${table}`);
                if (rows.length === 0) {
                    console.log(`   - ⚠️ Data Kosong. Skip.`);
                    continue;
                }

                const keys = Object.keys(rows[0]);
                const columns = keys.map(k => `\`${k}\``).join(', ');
                const placeholders = keys.map(() => '?').join(', ');
                const sqlInsert = `INSERT INTO ${table} (${columns}) VALUES (${placeholders})`;

                let success = 0;
                for (const row of rows) {
                    const values = keys.map(k => row[k]);
                    try {
                        await cloudConn.execute(sqlInsert, values);
                        success++;
                    } catch (err) {
                        console.error(`     ❌ Insert Gagal: ${err.message}`);
                    }
                }
                console.log(`   ✅ Data Tersalin: ${success} Baris.`);

            } catch (err) {
                console.error(`   ❌ GAGAL PROSES TABEL ${table}: ${err.message}`);
            }
        }

        await cloudConn.query('SET FOREIGN_KEY_CHECKS = 1');
        console.log('\n-----------------------------------');
        console.log('🎉 SELESAI! Database Cloud sekarang 100% Identik dengan Laptop.');

    } catch (err) {
        console.error('SERVER ERROR:', err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
migrateTotalClone();
