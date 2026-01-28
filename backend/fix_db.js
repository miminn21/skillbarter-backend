const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function fixDatabase() {
  console.log('🔄 Fixing database stored procedure...');
  
  let connection;
  try {
    // Connect to database
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'skillbarter_db',
      multipleStatements: true
    });
    
    console.log('✅ Connected to database');
    
    // Read the fixed SQL file
    const sqlPath = path.join(__dirname, 'migrations', 'create_transfer_skillcoin_procedure.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Execute the SQL
    await connection.query(sql);
    
    console.log('✅ Stored Procedure verified and updated successfully!');
    console.log('🚀 You can now restart your backend and test the transaction.');
    
  } catch (error) {
    console.error('❌ Error fixing database:', error.message);
  } finally {
    if (connection) await connection.end();
  }
}

fixDatabase();
