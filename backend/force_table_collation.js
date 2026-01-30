const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function forceCollation() {
    console.log('☢️ NUKE OPTION: MENYAMAKAN SEMUA COLLATION TABEL...');
    const conn = await mysql.createConnection(RAILWAY_CONFIG);
    
    try {
        const [tables] = await conn.query("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'");
        
        for (const t of tables) {
            const table = Object.values(t)[0];
            console.log(`   - Converting ${table}...`);
            await conn.query(`ALTER TABLE ${table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci`);
        }
        
        console.log("✅ SEMUA TABEL SUDAH SERAGAM (utf8mb4_general_ci).");
        
        // Coba lagi trigger manual
        console.log("⚡ Retrying Manual Trigger (ID 28)...");
        await conn.query("CALL proses_transaksi_barter(28)");
        console.log("🎉 BERHASIL EKSEKUSI PROCEDURE!");

    } catch (e) {
        console.error("❌ MASIH GAGAL:", e.message);
    } finally {
        conn.end();
    }
}
forceCollation();
