const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

async function syncDatabase() {
  console.log('🔄 Starting Database Sync from Railway to Local...\n');

  // Railway Database Credentials
  const RAILWAY_HOST = 'junction.proxy.rlwy.net';
  const RAILWAY_PORT = '17890';
  const RAILWAY_USER = 'root';
  const RAILWAY_PASS = 'GrqVJBWvvPCVPXIwLOqBQNmLMNLDCxFp';
  const RAILWAY_DB = 'railway';

  // Local Database Credentials
  const LOCAL_USER = 'root';
  const LOCAL_PASS = '';
  const LOCAL_DB = 'skillbarter_db';

  const dumpFile = 'railway_dump.sql';

  try {
    // Step 1: Export from Railway
    console.log('📥 Step 1: Exporting database from Railway...');
    const dumpCmd = `mysqldump -h ${RAILWAY_HOST} -P ${RAILWAY_PORT} -u ${RAILWAY_USER} -p${RAILWAY_PASS} ${RAILWAY_DB} > ${dumpFile}`;
    
    await execPromise(dumpCmd);
    console.log('✅ Export completed!\n');

    // Step 2: Import to Local
    console.log('📤 Step 2: Importing to local XAMPP...');
    const importCmd = LOCAL_PASS 
      ? `mysql -u ${LOCAL_USER} -p${LOCAL_PASS} ${LOCAL_DB} < ${dumpFile}`
      : `mysql -u ${LOCAL_USER} ${LOCAL_DB} < ${dumpFile}`;
    
    await execPromise(importCmd);
    console.log('✅ Import completed!\n');

    console.log('🎉 DATABASE SYNC SUCCESSFUL! 🎉');
    console.log('Local database now matches Railway database.');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\n💡 Alternative: Manual sync via phpMyAdmin');
    console.error('1. Go to Railway Dashboard → Database → Connect');
    console.error('2. Use phpMyAdmin or MySQL Workbench to export');
    console.error('3. Import the .sql file to local XAMPP');
  }
}

syncDatabase();
