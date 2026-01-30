const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway', multipleStatements: true, charset: 'utf8mb4_general_ci'
};

async function migrateRoutines() {
    console.log('🧠 MIGRASI PROSEDUR & FUNGSI...');
    
    let localConn, cloudConn;

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        // A. PROCEDURES
        const [procs] = await localConn.query("SHOW PROCEDURE STATUS WHERE Db = 'skillbarter_db'");
        console.log(`\n📋 Ditemukan ${procs.length} Procedure.`);
        
        for (const p of procs) {
            const name = p.Name;
            console.log(`   - Cloning Procedure: ${name}...`);
            const [rows] = await localConn.query(`SHOW CREATE PROCEDURE ${name}`);
            let sql = rows[0]['Create Procedure'];
            
            // Cleanup
            sql = sql.replace(/DEFINER=`.*?`@`.*?` /g, '');
            sql = sql.replace(/`skillbarter_db`\./g, '');
            sql = sql.replace(/skillbarter_db\./g, '');

            try {
                await cloudConn.query(`DROP PROCEDURE IF EXISTS ${name}`);
                await cloudConn.query(sql);
                console.log(`     ✅ Sukses.`);
            } catch (e) {
                console.error(`     ❌ Gagal: ${e.message}`);
            }
        }

        // B. FUNCTIONS
        const [funcs] = await localConn.query("SHOW FUNCTION STATUS WHERE Db = 'skillbarter_db'");
        console.log(`\n📋 Ditemukan ${funcs.length} Function.`);
        
        for (const f of funcs) {
            const name = f.Name;
            console.log(`   - Cloning Function: ${name}...`);
            const [rows] = await localConn.query(`SHOW CREATE FUNCTION ${name}`);
            let sql = rows[0]['Create Function'];
            
            // Cleanup
            sql = sql.replace(/DEFINER=`.*?`@`.*?` /g, '');
            sql = sql.replace(/`skillbarter_db`\./g, '');
            sql = sql.replace(/skillbarter_db\./g, '');

            try {
                await cloudConn.query(`DROP FUNCTION IF EXISTS ${name}`);
                await cloudConn.query(sql);
                console.log(`     ✅ Sukses.`);
            } catch (e) {
                console.error(`     ❌ Gagal: ${e.message}`);
            }
        }
        
        console.log('\n✅ SELESAI MIGRASI LOGIC.');

    } catch (err) {
        console.error(err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
migrateRoutines();
