const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function fixEnum() {
    console.log('🔧 FIXING NOTIFICATIONS COLUMN...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        
        // Change 'tipe' from ENUM to VARCHAR to allow any string
        await connection.query("ALTER TABLE notifications MODIFY COLUMN tipe VARCHAR(50) NOT NULL");
        
        console.log('✅ Column `tipe` modified to VARCHAR(50) successfully.');

    } catch (error) {
        console.error('❌ Error fixing column:', error);
    } finally {
        if (connection) await connection.end();
    }
}

fixEnum();
