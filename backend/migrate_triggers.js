const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway', multipleStatements: true
};

async function migrateTriggers() {
    console.log('⚡ MIGRASI TRIGGERS...');
    
    let localConn, cloudConn;

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        // 1. Ambil List Trigger
        const [triggers] = await localConn.query("SHOW TRIGGERS");
        console.log(`Ditemukan ${triggers.length} Trigger di Lokal.`);

        for (const trig of triggers) {
            const triggerName = trig.Trigger;
            console.log(`   - Cloning ${triggerName}...`);

            // 2. Ambil Syntax Create
            const [createRows] = await localConn.query(`SHOW CREATE TRIGGER ${triggerName}`);
            let createSQL = createRows[0]['SQL Original Statement'];
            
            // CLEANUP: 
            // DEFINER often causes issues (different users). Remove it.
            // Format: CREATE DEFINER=`root`@`localhost` TRIGGER ...
            createSQL = createSQL.replace(/DEFINER=`.*?`@`.*?` /g, '');
            createSQL = createSQL.replace(/DEFINER=`.*?`/g, '');
            
            // Hapus nama db lokal
            createSQL = createSQL.replace(/`skillbarter_db`\./g, '');
            createSQL = createSQL.replace(/skillbarter_db\./g, '');

            // 3. Pasang di Cloud
            try {
                await cloudConn.query(`DROP TRIGGER IF EXISTS ${triggerName}`);
                await cloudConn.query(createSQL);
                console.log(`     ✅ Sukses.`);
            } catch (e) {
                console.error(`     ❌ Gagal: ${e.message}`);
                // Fallback attempt: maybe syntax error?
            }
        }
        
        console.log('\n✅ SELESAI MIGRASI TRIGGERS.');

    } catch (err) {
        console.error(err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
migrateTriggers();
