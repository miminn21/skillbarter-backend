const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost', user: 'root', password: '', database: 'skillbarter_db'
};
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net', port: 38963, user: 'root', password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw', database: 'railway'
};

async function checkHistory() {
    console.log('🕵️‍♂️ CEK DATA RIWAYAT (HISTORY)...');
    let localConn, cloudConn;

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        const tables = ['transaksi_barter', 'log_transaksi', 'transaksi_skillcoin'];
        
        console.log('\n1. PERBANDINGAN JUMLAH BARIS:');
        for (const t of tables) {
            const [l] = await localConn.query(`SELECT COUNT(*) as c FROM ${t}`);
            const [c] = await cloudConn.query(`SELECT COUNT(*) as c FROM ${t}`);
            console.log(`   - ${t.padEnd(20)}: Lokal=${l[0].c}, Cloud=${c[0].c} ${l[0].c == c[0].c ? '✅' : '❌'}`);
        }

        console.log('\n2. CEK DETAIL STATUS TRANSAKSI (Cloud):');
        const [statuses] = await cloudConn.query("SELECT status, COUNT(*) as jumlah FROM transaksi_barter GROUP BY status");
        statuses.forEach(s => console.log(`   - Status '${s.status}': ${s.jumlah} item`));

        console.log('\n3. CEK USER MUHAIMIN (Cloud):');
        // Cari ID user muhaimin
        const [u] = await cloudConn.query("SELECT nik FROM pengguna WHERE nama_panggilan LIKE '%muhaimin%' LIMIT 1");
        if (u.length > 0) {
            const nik = u[0].nik;
            const [myTrans] = await cloudConn.query(`SELECT COUNT(*) as c FROM transaksi_barter WHERE nik_penawar='${nik}' OR nik_ditawar='${nik}'`);
            console.log(`   - User 'muhaimin' punya ${myTrans[0].c} transaksi.`);
        } else {
            console.log("   - User muhaimin tidak ditemukan!");
        }

    } catch (err) {
        console.error(err);
    } finally {
        if (localConn) localConn.end();
        if (cloudConn) cloudConn.end();
    }
}
checkHistory();
