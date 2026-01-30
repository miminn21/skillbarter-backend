const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function checkSchemaJson() {
    let localConn, cloudConn;
    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        async function getCounts(conn, dbName) {
            const [views] = await conn.query(`SHOW FULL TABLES FROM \`${dbName}\` WHERE Table_type = 'VIEW'`);
            const [procs] = await conn.query(`SHOW PROCEDURE STATUS WHERE Db = '${dbName}'`);
            const [funcs] = await conn.query(`SHOW FUNCTION STATUS WHERE Db = '${dbName}'`);
            // Triggers need different handling or just SHOW TRIGGERS FROM db
            const [triggers] = await conn.query(`SHOW TRIGGERS FROM \`${dbName}\``);
            
            return {
                views: views.length,
                procedures: procs.length,
                functions: funcs.length,
                triggers: triggers.length
            };
        }

        const localCounts = await getCounts(localConn, 'skillbarter_db');
        const cloudCounts = await getCounts(cloudConn, 'railway');

        console.log(JSON.stringify({ local: localCounts, cloud: cloudCounts }, null, 2));

    } catch (err) {
        console.error(err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
checkSchemaJson();
