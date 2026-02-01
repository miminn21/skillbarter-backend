require('dotenv').config();
const mysql = require('mysql2/promise');

// Local database config
const localConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'skillbarter_db'
};

// Railway database config (from environment variables)
const railwayConfig = {
  host: process.env.RAILWAY_DB_HOST,
  user: process.env.RAILWAY_DB_USER,
  password: process.env.RAILWAY_DB_PASSWORD,
  database: process.env.RAILWAY_DB_NAME,
  port: process.env.RAILWAY_DB_PORT || 3306
};

async function compareTableStructure(localConn, railwayConn, tableName) {
  console.log(`\n📋 Comparing table: ${tableName}`);
  console.log('─'.repeat(80));

  try {
    // Get local table structure
    const [localColumns] = await localConn.query(`DESCRIBE ${tableName}`);
    
    // Get railway table structure
    const [railwayColumns] = await railwayConn.query(`DESCRIBE ${tableName}`);

    // Compare
    if (localColumns.length !== railwayColumns.length) {
      console.log(`⚠️  Column count mismatch!`);
      console.log(`   Local: ${localColumns.length} columns`);
      console.log(`   Railway: ${railwayColumns.length} columns`);
    } else {
      console.log(`✅ Column count matches: ${localColumns.length} columns`);
    }

    // Check each column
    const localColMap = new Map(localColumns.map(c => [c.Field, c]));
    const railwayColMap = new Map(railwayColumns.map(c => [c.Field, c]));

    let differences = 0;

    // Check columns in local that are missing or different in railway
    for (const [colName, localCol] of localColMap) {
      const railwayCol = railwayColMap.get(colName);
      
      if (!railwayCol) {
        console.log(`❌ Column "${colName}" exists in LOCAL but NOT in RAILWAY`);
        differences++;
      } else if (localCol.Type !== railwayCol.Type) {
        console.log(`⚠️  Column "${colName}" type mismatch:`);
        console.log(`   Local: ${localCol.Type}`);
        console.log(`   Railway: ${railwayCol.Type}`);
        differences++;
      }
    }

    // Check columns in railway that are missing in local
    for (const [colName] of railwayColMap) {
      if (!localColMap.has(colName)) {
        console.log(`❌ Column "${colName}" exists in RAILWAY but NOT in LOCAL`);
        differences++;
      }
    }

    if (differences === 0) {
      console.log(`✅ All columns match perfectly!`);
    } else {
      console.log(`\n⚠️  Found ${differences} difference(s)`);
    }

    return differences === 0;

  } catch (error) {
    console.log(`❌ Error comparing table: ${error.message}`);
    return false;
  }
}

async function compareDatabases() {
  let localConn, railwayConn;

  try {
    console.log('╔════════════════════════════════════════════════════════════════╗');
    console.log('║     DATABASE STRUCTURE COMPARISON: LOCAL vs RAILWAY           ║');
    console.log('╚════════════════════════════════════════════════════════════════╝\n');

    // Connect to local database
    console.log('🔌 Connecting to LOCAL database...');
    localConn = await mysql.createConnection(localConfig);
    console.log('✅ Connected to LOCAL database\n');

    // Connect to railway database
    console.log('🔌 Connecting to RAILWAY database...');
    if (!railwayConfig.host) {
      console.log('❌ Railway database credentials not found in .env!');
      console.log('   Please add: RAILWAY_DB_HOST, RAILWAY_DB_USER, RAILWAY_DB_PASSWORD, RAILWAY_DB_NAME');
      process.exit(1);
    }
    railwayConn = await mysql.createConnection(railwayConfig);
    console.log('✅ Connected to RAILWAY database\n');

    // Tables to compare
    const tablesToCompare = [
      'transaksi_barter',
      'notifications',
      'pengguna',
      'keahlian',
      'barter_confirmations',
      'ulasan_dan_rating'
    ];

    console.log('📊 Tables to compare:', tablesToCompare.join(', '));
    console.log('═'.repeat(80));

    let allMatch = true;

    for (const table of tablesToCompare) {
      const matches = await compareTableStructure(localConn, railwayConn, table);
      if (!matches) allMatch = false;
    }

    console.log('\n' + '═'.repeat(80));
    if (allMatch) {
      console.log('✅ ALL TABLES MATCH! Local and Railway databases are in sync.');
    } else {
      console.log('⚠️  DIFFERENCES FOUND! Local and Railway databases are NOT in sync.');
      console.log('   You may need to run migrations on Railway.');
    }
    console.log('═'.repeat(80));

  } catch (error) {
    console.error('❌ Fatal error:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    if (localConn) await localConn.end();
    if (railwayConn) await railwayConn.end();
    process.exit(0);
  }
}

compareDatabases();
