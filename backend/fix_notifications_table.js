const mysql = require('mysql2/promise');

const RAILWAY_CONFIG = {
    host: 'switchyard.proxy.rlwy.net',
    port: 38963,
    user: 'root',
    password: 'fSexsPKyjZtWdhESBvdEFrfBTFSORsfw',
    database: 'railway'
};

const createTableQuery = `
CREATE TABLE IF NOT EXISTS notifications (
  id_notifikasi INT PRIMARY KEY AUTO_INCREMENT,
  nik VARCHAR(16) NOT NULL,
  tipe VARCHAR(50) NOT NULL,
  judul VARCHAR(100) NOT NULL,
  pesan TEXT NOT NULL,
  data JSON,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (nik) REFERENCES pengguna(nik) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

async function fixTable() {
    console.log('🔧 FIXING DATABASE SCHEMA...');
    let connection;
    try {
        connection = await mysql.createConnection(RAILWAY_CONFIG);
        console.log('✅ Connected to Railway DB');

        // Check if table exists
        const [tables] = await connection.query("SHOW TABLES LIKE 'notifications'");
        if (tables.length > 0) {
            console.log('ℹ️ Table notifications already exists.');
        } else {
            console.log('⚠️ Table notifications MISSING. Creating it...');
            await connection.query(createTableQuery);
            console.log('✅ Table notifications CREATED successfully.');
        }

    } catch (error) {
        console.error('❌ Error fixing database:', error);
    } finally {
        if (connection) await connection.end();
    }
}

fixTable();
