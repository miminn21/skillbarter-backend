const mysql = require('mysql2/promise');

const config = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function main() {
    console.log("🔌 Connecting to Railway DB...");
    let conn;
    try {
        conn = await mysql.createConnection(config);
        console.log("✅ Connected! Applying Migration...");
        
        // Add Columns
        // Note: IF NOT EXISTS is not supported for ADD COLUMN in standard MySQL effectively without procedure,
        // so we just run it. If it fails with "Duplicate column", we catch it.
        try {
            await conn.query(`
                ALTER TABLE pengguna
                ADD COLUMN latitude DECIMAL(10, 8) NULL,
                ADD COLUMN longitude DECIMAL(11, 8) NULL,
                ADD COLUMN last_location_update TIMESTAMP NULL
            `);
            console.log("✅ Migration Successful: Columns Added.");
        } catch (err) {
            if (err.code === 'ER_DUP_FIELDNAME') {
                console.log("⚠️ Migration Skipped: Columns already exist.");
            } else {
                throw err;
            }
        }
        
        // Verification
        const [rows] = await conn.query("DESC pengguna");
        console.log("\n🔍 Verified Structure (Tail):");
        console.table(rows.slice(-5)); // Show last 5 columns
        
    } catch (e) {
        console.error("❌ Fatal Error:", e.message);
    } finally {
        if (conn) conn.end();
        console.log("🔌 Connection Closed.");
    }
}

main();
