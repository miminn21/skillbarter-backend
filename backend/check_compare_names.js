const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function listNames() {
    console.log('📋 DAFTAR ABSEN DATABASE CLOUD');
    const conn = await mysql.createConnection(RAILWAY_CONFIG);
    try {
        const [tables] = await conn.query("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'");
        const [views] = await conn.query("SHOW FULL TABLES WHERE Table_type = 'VIEW'");
        const [procs] = await conn.query("SHOW PROCEDURE STATUS WHERE Db = 'railway'");
        const [funcs] = await conn.query("SHOW FUNCTION STATUS WHERE Db = 'railway'");
        const [trigs] = await conn.query("SHOW TRIGGERS");

        console.log('\n--- TABEL (Harus 25) ---');
        console.log(tables.map(t => t[`Tables_in_railway`]).sort().join(', '));

        console.log('\n--- VIEW (Harus 8) ---');
        console.log(views.map(t => t[`Tables_in_railway`]).sort().join(', '));

        console.log('\n--- STORED PROCEDURE (Harus 10) ---');
        console.log(procs.map(p => p.Name).sort().join('\n'));

        console.log('\n--- FUNCTION (Harus 4) ---');
        console.log(funcs.map(f => f.Name).sort().join(', '));

        console.log('\n--- TRIGGER (Harus 5) ---');
        console.log(trigs.map(t => t.Trigger).sort().join('\n'));

    } catch (e) {
        console.error(e);
    } finally {
        conn.end();
    }
}
listNames();
