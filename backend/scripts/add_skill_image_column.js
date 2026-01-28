const db = require('../src/config/database');

async function run() {
  try {
    console.log('Adding gambar_skill columns to keahlian table...');
    
    // Check if column exists
    const [columns] = await db.execute("SHOW COLUMNS FROM keahlian LIKE 'gambar_skill'");
    
    if (columns.length === 0) {
      await db.execute("ALTER TABLE keahlian ADD COLUMN gambar_skill MEDIUMBLOB AFTER link_portofolio");
      console.log('✅ Added gambar_skill column');
    } else {
      console.log('ℹ️ gambar_skill column already exists');
    }

    const [typeColumns] = await db.execute("SHOW COLUMNS FROM keahlian LIKE 'jenis_gambar_skill'");
    if (typeColumns.length === 0) {
      await db.execute("ALTER TABLE keahlian ADD COLUMN jenis_gambar_skill VARCHAR(10) AFTER gambar_skill");
      console.log('✅ Added jenis_gambar_skill column');
    } else {
      console.log('ℹ️ jenis_gambar_skill column already exists');
    }

    console.log('Migration completed successfully');
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  }
}

run();
