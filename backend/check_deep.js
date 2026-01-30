const mysql = require('mysql2/promise');

const LOCAL_CONFIG = {
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'skillbarter_db'
};

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function checkDeep() {
    console.log('🕵️‍♂️ DIAGNOSA DATA & STRUKTUR: LOKAL vs CLOUD');
    const tablesToCheck = ['pengguna', 'keahlian', 'transaksi_barter', 'transaksi_skillcoin', 'notifikasi', 'pesan'];
    
    let localConn, cloudConn;

    try {
        localConn = await mysql.createConnection(LOCAL_CONFIG);
        cloudConn = await mysql.createConnection(RAILWAY_CONFIG);

        console.log('\n1. PERBANDINGAN JUMLAH DATA:');
        console.log('--------------------------------------------------');
        console.log('| Table Name           | Local Rows | Cloud Rows | Status   |');
        console.log('--------------------------------------------------');

        for (const table of tablesToCheck) {
            const [localRows] = await localConn.query(`SELECT COUNT(*) as c FROM ${table}`);
            const [cloudRows] = await cloudConn.query(`SELECT COUNT(*) as c FROM ${table}`);
            
            const l = localRows[0].c;
            const c = cloudRows[0].c;
            const status = (l === c) ? '✅ OK' : '❌ BEDA';
            
            console.log(`| ${table.padEnd(18)} | ${String(l).padEnd(10)} | ${String(c).padEnd(10)} | ${status.padEnd(8)} |`);
        }
        console.log('--------------------------------------------------');

        console.log('\n2. CEK KOLOM KRUSIAL (Penyebab Error 500):');
        // Cek apakah kolom-kolom baru ada di Cloud
        const krusial = [
            {table: 'transaksi_barter', col: 'tipe_transaksi'},
            {table: 'pengguna', col: 'status_online'},
            {table: 'keahlian', col: 'id_kategori'}
        ];

        for (const item of krusial) {
            try {
                // Query enteng untuk cek kolom
                await cloudConn.query(`SELECT ${item.col} FROM ${item.table} LIMIT 1`);
                console.log(`✅ Kolom '${item.col}' di tabel '${item.table}': ADA`);
            } catch (err) {
                console.log(`❌ Kolom '${item.col}' di tabel '${item.table}': HILANG! (${err.code})`);
            }
        }

    } catch (err) {
        console.error('ERROR UTAMA:', err.message);
    } finally {
        if (localConn) await localConn.end();
        if (cloudConn) await cloudConn.end();
    }
}

checkDeep();
