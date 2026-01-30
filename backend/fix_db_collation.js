const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function fixDbCollation() {
    console.log('🏗️ ALTER DATABASE DEFAULT COLLATION...');
    const conn = await mysql.createConnection(RAILWAY_CONFIG);
    try {
        await conn.query("ALTER DATABASE railway CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci");
        console.log("✅ Database Default Changed to utf8mb4_general_ci");
        
        // Check it
        const [rows] = await conn.query("SELECT @@character_set_database, @@collation_database");
        console.log("Current DB Settings:", rows[0]);

    } catch (e) {
        console.error("❌ Failed:", e.message);
    } finally {
        conn.end();
    }
}
fixDbCollation();
