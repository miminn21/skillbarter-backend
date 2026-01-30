const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway', multipleStatements: true
};

async function fixCollation() {
    console.log('🔧 FIXING COLLATION MISMATCH ON PROCEDURE...');
    let localConn, cloudConn;

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        // Penting: Set charset di koneksi Cloud biar konsisten
        cloudConn = await mysql.createConnection({
            ...RAILWAY_CONFIG,
            charset: 'utf8mb4_general_ci'
        });

        // 1. Ambil Source Code Procedure dari Local
        const [rows] = await localConn.query("SHOW CREATE PROCEDURE proses_transaksi_barter");
        let sql = rows[0]['Create Procedure'];

        // 2. Bersihkan syntax
        sql = sql.replace(/DEFINER=`.*?`@`.*?` /g, '');
        sql = sql.replace(/`skillbarter_db`\./g, '');
        sql = sql.replace(/skillbarter_db\./g, '');

        // 3. Force Re-Create di Cloud dengan Session Collation yang Benar
        await cloudConn.query("SET NAMES 'utf8mb4' COLLATE 'utf8mb4_general_ci'");
        await cloudConn.query("DROP PROCEDURE IF EXISTS proses_transaksi_barter");
        await cloudConn.query(sql);

        console.log("✅ Procedure re-created with utf8mb4_general_ci context.");

        // 4. Test Trigger lagi (ID 28)
        console.log("⚡ Retrying Manual Trigger (ID 28)...");
        await cloudConn.query("CALL proses_transaksi_barter(28)");
        console.log("🎉 SUCCESS! No Collation Error.");

    } catch (e) {
        console.error("❌ MASIH ERROR:");
        console.error(e.message);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
fixCollation();
