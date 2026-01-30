const fs = require('fs');
const mysql = require('mysql2/promise');
const path = require('path');

// KONFIGURASI RAILWAY (DARI BAPAK)
const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway', 
    multipleStatements: true 
};

// Parser Sederhana untuk menangani DELIMITER
function parseSqlFile(content) {
    const queries = [];
    const lines = content.split('\n');
    
    let delimiter = ';';
    let buffer = '';
    
    for (let i = 0; i < lines.length; i++) {
        let line = lines[i].trim();
        
        // Skip comment lines (-- or # at start)
        if (line.startsWith('--') || line.startsWith('#')) continue;
        if (!line) continue;

        // Cek perubahan DELIMITER
        if (line.toUpperCase().startsWith('DELIMITER ')) {
            delimiter = line.split(' ')[1];
            continue; // Jangan masukkan baris DELIMITER ke buffer
        }

        // Tambah baris ke buffer (pakai spasi agar aman)
        buffer += lines[i] + '\n';
        
        // Cek apakah buffer berakhir dengan delimiter saat ini
        const trimmedBuffer = buffer.trim();
        if (trimmedBuffer.endsWith(delimiter)) {
            // Hapus delimiter dari akhir query
            let sql = trimmedBuffer.substring(0, trimmedBuffer.length - delimiter.length);
            
            // Hapus command CREATE DB / USE DB yang dilarang
            if (!sql.toUpperCase().includes('CREATE DATABASE') && !sql.toUpperCase().includes('USE SKILLBARTER_DB')) {
                 if (sql.trim()) queries.push(sql);
            }
            
            buffer = ''; // Reset buffer
        }
    }
    
    return queries;
}

async function uploadDatabase() {
    console.log('🚀 MEMULAI UPLOAD DATABASE KE RAILWAY (V2 - SMART PARSER)...');
    
    let connection;
    try {
        const sqlPath = path.join(__dirname, 'skillbarter_db.sql');
        const sqlContent = fs.readFileSync(sqlPath, 'utf8');
        
        console.log('🧠 Memparsing file SQL...');
        const queries = parseSqlFile(sqlContent);
        console.log(`📝 Ditemukan ${queries.length} perintah SQL yang siap dijalankan.`);

        console.log('🔌 Menghubungkan ke Railway...');
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        console.log('✅ Terhubung!');

        console.log('📤 Mengirim data satu per satu...');
        for (let i = 0; i < queries.length; i++) {
            try {
                process.stdout.write(`\r⏳ Memproses Query ${i + 1}/${queries.length}...`);
                await connection.query(queries[i]);
            } catch (qErr) {
                console.warn(`\n⚠️ Warning pada Query ${i+1}: ${qErr.message}`);
                // Lanjut terus meski error kecil (misal drop table if exists gagal)
            }
        }
        
        console.log('\n\n----------------------------------------');
        console.log('🎉 SUKSES BESAR! Database sudah online di Railway.');
        console.log('----------------------------------------');
        
    } catch (err) {
        console.error('\n❌ ERROR FATAL:', err.message);
    } finally {
        if (connection) await connection.end();
    }
}

uploadDatabase();
