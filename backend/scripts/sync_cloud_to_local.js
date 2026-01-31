const mysql = require('mysql2/promise');

// Cloud Database (Railway)
const cloudConfig = {
  host: 'junction.proxy.rlwy.net',
  port: 17890,
  user: 'root',
  password: 'GrqVJBWvvPCVPXIwLOqBQNmLMNLDCxFp',
  database: 'railway',
  connectTimeout: 30000,
  waitForConnections: true,
  connectionLimit: 1
};

// Local Database (XAMPP)
const localConfig = {
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '',
  database: 'skillbarter_db',
  multipleStatements: true
};

async function syncDatabase() {
  let cloudPool, localConn;
  
  try {
    console.log('🔌 Creating connection pool to Railway...');
    cloudPool = mysql.createPool(cloudConfig);
    
    console.log('🔌 Connecting to Local XAMPP...');
    localConn = await mysql.createConnection(localConfig);
    console.log('✅ Connected to Local Database\n');

    // Test cloud connection
    console.log('🧪 Testing Railway connection...');
    const [testResult] = await cloudPool.query('SELECT 1 as test');
    console.log('✅ Railway connection OK\n');

    // Get table list
    console.log('📋 Fetching table list from Railway...');
    const [tables] = await cloudPool.query('SHOW TABLES');
    const tableNames = tables.map(row => Object.values(row)[0]);
    console.log(`✅ Found ${tableNames.length} tables\n`);

    // Disable foreign key checks
    await localConn.query('SET FOREIGN_KEY_CHECKS = 0');
    console.log('🔓 Foreign key checks disabled\n');

    // Sync each table
    let successCount = 0;
    for (const tableName of tableNames) {
      try {
        console.log(`🔄 Syncing: ${tableName}`);
        
        // Get table structure
        const [createTable] = await cloudPool.query(`SHOW CREATE TABLE \`${tableName}\``);
        const createTableSQL = createTable[0]['Create Table'];
        
        // Drop and recreate
        await localConn.query(`DROP TABLE IF EXISTS \`${tableName}\``);
        await localConn.query(createTableSQL);
        
        // Get row count first
        const [countResult] = await cloudPool.query(`SELECT COUNT(*) as count FROM \`${tableName}\``);
        const rowCount = countResult[0].count;
        
        if (rowCount > 0) {
          // Fetch all data
          const [rows] = await cloudPool.query(`SELECT * FROM \`${tableName}\``);
          
          // Insert in batches
          const batchSize = 50;
          for (let i = 0; i < rows.length; i += batchSize) {
            const batch = rows.slice(i, i + batchSize);
            const columns = Object.keys(batch[0]);
            const values = batch.map(row => 
              `(${columns.map(col => localConn.escape(row[col])).join(', ')})`
            ).join(', ');
            
            await localConn.query(
              `INSERT INTO \`${tableName}\` (\`${columns.join('`, `')}\`) VALUES ${values}`
            );
          }
          console.log(`  ✅ ${rowCount} rows synced`);
        } else {
          console.log(`  ℹ️  Empty table`);
        }
        
        successCount++;
      } catch (tableError) {
        console.error(`  ❌ Failed: ${tableError.message}`);
      }
    }

    // Re-enable foreign key checks
    await localConn.query('SET FOREIGN_KEY_CHECKS = 1');

    console.log('\n' + '='.repeat(50));
    console.log(`✅ SYNC COMPLETE: ${successCount}/${tableNames.length} tables`);
    console.log('='.repeat(50));

  } catch (error) {
    console.error('\n❌ FATAL ERROR:', error.message);
    throw error;
  } finally {
    if (cloudPool) await cloudPool.end();
    if (localConn) await localConn.end();
  }
}

syncDatabase().catch(err => {
  console.error('Script failed:', err);
  process.exit(1);
});
