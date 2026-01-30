const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function verifyJson() {
    let localConn, cloudConn;
    const mismatches = [];

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        const [tables] = await localConn.query("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'");
        const tableNames = tables.map(t => Object.values(t)[0]);

        for (const table of tableNames) {
            const [l] = await localConn.query(`SELECT COUNT(*) as c FROM ${table}`);
            const [c] = await cloudConn.query(`SELECT COUNT(*) as c FROM ${table}`);
            if (l[0].c !== c[0].c) {
                mismatches.push({ table, local: l[0].c, cloud: c[0].c });
            }
        }

        console.log(JSON.stringify(mismatches, null, 2));

    } catch (err) {
        console.error(err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
verifyJson();
