const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function migrateMissingClone() {
    console.log('🚑 PERBAIKAN STRUKTUR + DATA (CLONE)...');
    const targetTables = ['log_transaksi', 'transaksi_skillcoin'];
    
    let localConn, cloudConn;

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        await cloudConn.query('SET FOREIGN_KEY_CHECKS = 0');

        for (const table of targetTables) {
            console.log(`\n📦 FIXING TOTAL: ${table}`);
            
            // 1. Ambil Create Statement
            const [createRows] = await localConn.query(`SHOW CREATE TABLE ${table}`);
            let createSQL = createRows[0]['Create Table'];
            createSQL = createSQL.replace(/AUTO_INCREMENT=\d+ /g, '');
            createSQL = createSQL.replace(/`skillbarter_db`\./g, '');
            // SAFETY: Paksa 'aksi' jadi VARCHAR biar gak rewel soal ENUM
            createSQL = createSQL.replace(/`aksi` enum\(.*?\)/gi, '`aksi` varchar(100)');
            
            // 2. Drop & Re-Create
            await cloudConn.query("SET SESSION sql_mode=''"); // Disable Strict Mode
            await cloudConn.query(`DROP TABLE IF EXISTS ${table}`);
            await cloudConn.query(createSQL);
            console.log(`   - 🔨 Struktur Baru Dibuat.`);

            // 3. Insert Data
            const [rows] = await localConn.query(`SELECT * FROM ${table}`);
            if (rows.length > 0) {
                const keys = Object.keys(rows[0]);
                const columns = keys.map(k => `\`${k}\``).join(', ');
                const placeholders = keys.map(() => '?').join(', ');
                const sqlInsert = `INSERT INTO ${table} (${columns}) VALUES (${placeholders})`;

                let success = 0;
                for (const row of rows) {
                    const values = keys.map(k => row[k]);
                    await cloudConn.execute(sqlInsert, values);
                    success++;
                }
                console.log(`   ✅ Berhasil Insert: ${success}/${rows.length}`);
            }
        }
        
    } catch (err) {
        console.error(err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
migrateMissingClone();
