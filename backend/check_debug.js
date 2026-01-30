const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function checkDebug() {
    let localConn, cloudConn;
    const result = { local: {}, cloud: {}, comparison: {} };

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        // 1. Cek User Muhaimin
        const [lUser] = await localConn.query("SELECT rating_rata_rata FROM pengguna WHERE nama_panggilan LIKE '%muhaimin%'");
        const [cUser] = await cloudConn.query("SELECT rating_rata_rata FROM pengguna WHERE nama_panggilan LIKE '%muhaimin%'");
        
        result.local.rating_muhaimin = lUser[0]?.rating_rata_rata || 'Not Found';
        result.cloud.rating_muhaimin = cUser[0]?.rating_rata_rata || 'Not Found';

        // 2. Cek Counts
        const tables = ['keahlian', 'transaksi_barter', 'pengguna'];
        for (const t of tables) {
            const [lC] = await localConn.query(`SELECT COUNT(*) as c FROM ${t}`);
            const [cC] = await cloudConn.query(`SELECT COUNT(*) as c FROM ${t}`);
            result.local[t] = lC[0].c;
            result.cloud[t] = cC[0].c;
        }

        // 3. Cek Error 500 (Kolom)
        try {
            await cloudConn.query("SELECT id_kategori FROM keahlian LIMIT 1");
            result.cloud.column_check = "OK";
        } catch (e) {
            result.cloud.column_check = e.message;
        }

        console.log(JSON.stringify(result, null, 2));

    } catch (err) {
        console.error(err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
checkDebug();
