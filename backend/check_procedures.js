const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function checkProcedures() {
    console.log('🔍 CHECKING PROCEDURES...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        const [rows1] = await connection.query("SHOW CREATE PROCEDURE tambah_skillcoin");
        console.log('--- PROCEDURE: tambah_skillcoin ---');
        console.log(rows1[0]['Create Procedure']);
        
        const [rows2] = await connection.query("SHOW CREATE PROCEDURE kurangi_skillcoin");
        console.log('\n--- PROCEDURE: kurangi_skillcoin ---');
        console.log(rows2[0]['Create Procedure']);

    } catch (error) {
        console.error('❌ Error checking procedures:', error);
    } finally {
        if (connection) await connection.end();
    }
}

checkProcedures();
