const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway', charset: 'utf8mb4_general_ci'
};

async function triggerManual() {
    console.log('⚡ MANUAL TRIGGER PROCEDURE (ID: 28)...');
    const conn = await mysql.createConnection(RAILWAY_CONFIG);
    try {
        // Cek dulu statusnya
        const [rows] = await conn.query("SELECT * FROM transaksi_barter WHERE id=28");
        console.log(`STATUS AWAL: ${rows[0].status}`);

        // Panggil Procedure
        console.log("Calling 'proses_transaksi_barter(28)'...");
        await conn.query("CALL proses_transaksi_barter(28)");
        
        console.log("✅ PROCEDURE EXECUTED SUCCESSFULLY!");
        
        // Cek lagi statusnya
        const [rowsAfter] = await conn.query("SELECT * FROM transaksi_barter WHERE id=28");
        console.log(`STATUS AKHIR: ${rowsAfter[0].status}`);

    } catch (e) {
        console.error("❌ ERROR SAAT EKSEKUSI PROCEDURE:");
        console.error(e.message);
        if (e.sqlState) console.error(`SQL State: ${e.sqlState}`);
    } finally {
        conn.end();
    }
}
triggerManual();
