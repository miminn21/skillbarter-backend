const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function checkTransSchema() {
    console.log('🔍 CHECKING TRANSAKSI_BARTER SCHEMA...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        const [rows] = await connection.query("DESCRIBE transaksi_barter");
        console.log(JSON.stringify(rows, null, 2));
    } catch (error) {
        console.error('❌ Error checking schema:', error);
    } finally {
        if (connection) await connection.end();
    }
}

checkTransSchema();
