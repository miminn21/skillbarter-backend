const mysql = require('mysql2');
require('dotenv').config();

// Create connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || process.env.MYSQLHOST || 'localhost',
  user: process.env.DB_USER || process.env.MYSQLUSER || 'root',
  password: process.env.DB_PASSWORD || process.env.MYSQLPASSWORD || '',
  database: process.env.DB_NAME || process.env.MYSQLDATABASE || 'skillbarter_db',
  // Railway often passes port as a string, parse it to int to avoid errors
  port: parseInt(process.env.DB_PORT || process.env.MYSQLPORT || '3306'),
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  connectTimeout: 30000 // 30 second timeout for Railway
});

// Get promise-based pool
const promisePool = pool.promise();

// Test connection without using process.exit(1) which crashes the server
function testConnection(retryCount = 0) {
  pool.getConnection((err, connection) => {
    if (err) {
      console.error(`❌ Database connection failed (attempt ${retryCount + 1}):`, err.message);
      if (retryCount < 5) {
        const delay = Math.min(5000 * (retryCount + 1), 30000);
        console.log(`⏳ Retrying in ${delay / 1000}s...`);
        setTimeout(() => testConnection(retryCount + 1), delay);
      } else {
        console.error('❌ Max DB connection retries reached. Server continues running, but DB is missing.');
        console.log('   Check Railway variables: MYSQLHOST, MYSQLUSER, MYSQLPASSWORD, MYSQLDATABASE, MYSQLPORT');
      }
      return;
    }
    console.log('✅ Database connected successfully');
    connection.release();
  });
}

testConnection();

module.exports = promisePool;
