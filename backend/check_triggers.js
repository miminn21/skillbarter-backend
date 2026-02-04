const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function checkTriggers() {
    console.log('🔍 CHECKING DATABASE TRIGGERS...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        
        // Show all triggers
        const [rows] = await connection.query("SHOW TRIGGERS");
        
        if (rows.length === 0) {
            console.log('No triggers found.');
        } else {
            console.log(`Found ${rows.length} triggers:`);
            rows.forEach(row => {
               console.log(`- Trigger: ${row.Trigger}, Event: ${row.Event}, Table: ${row.Table}`);
               console.log(`  Statement: ${row.Statement}`);
               console.log('---');
            });
        }

    } catch (error) {
        console.error('❌ Error checking triggers:', error);
    } finally {
        if (connection) await connection.end();
    }
}

checkTriggers();
