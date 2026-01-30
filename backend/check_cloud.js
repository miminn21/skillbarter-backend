const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

async function checkCloudData() {
    console.log('📡 CEK DATA FINAL RAILWAY...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        const [users] = await connection.query('SELECT COUNT(*) as total FROM pengguna');
        console.log(`👤 JUMLAH PENGGUNA: ${users[0].total} Orang`);
        
        const [sampleUsers] = await connection.query('SELECT nama_lengkap FROM pengguna LIMIT 8');
        console.log('   Daftar Nama:');
        sampleUsers.forEach(u => console.log(`   - ${u.nama_lengkap}`));
        
    } catch (err) {
        console.error('❌ ERROR:', err.message);
    } finally {
        if (connection) await connection.end();
    }
}

checkCloudData();
