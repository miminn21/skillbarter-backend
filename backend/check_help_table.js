const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function checkTable() {
    console.log('🔍 CEK STRUKTUR TABEL LAPORAN_PENGGUNA...');
    const conn = await mysql.createConnection(RAILWAY_CONFIG);
    try {
        const [rows] = await conn.query("DESC laporan_pengguna");
        console.log("COLUMNS:");
        rows.forEach(r => console.log(`- ${r.Field} (${r.Type}) NULL: ${r.Null}`));
    } catch (e) {
        console.error("❌ Error:", e.message);
    } finally {
        conn.end();
    }
}
checkTable();
