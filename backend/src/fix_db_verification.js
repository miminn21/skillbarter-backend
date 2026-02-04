const db = require('./config/database');

async function fixDatabase() {
  console.log('Starting Database Fix...');

  try {
    // 1. Check if column exists
    console.log('Checking keahlian table columns...');
    const [columns] = await db.execute("SHOW COLUMNS FROM keahlian LIKE 'diperbarui_pada'");
    
    if (columns.length > 0) {
      console.log('Column diperbarui_pada ALREADY EXISTS.');
    } else {
      console.log('Column diperbarui_pada is MISSING. Adding it now...');
      await db.execute("ALTER TABLE keahlian ADD COLUMN diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");
      console.log('SUCCESS: Column diperbarui_pada added.');
    }

    // 2. Check Triggers (Just for info)
    console.log('Checking Triggers on keahlian...');
    const [triggers] = await db.execute("SHOW TRIGGERS WHERE `Table` = 'keahlian'");
    if (triggers.length > 0) {
        console.log('Found Triggers:');
        triggers.forEach(t => console.log(`- ${t.Trigger}`));
    } else {
        console.log('No triggers found (This is strange if you are getting that error, unless it is a Stored Procedure call remaining?)');
    }

    console.log('Database Fix Completed successfully.');
    process.exit(0);
  } catch (err) {
    console.error('FIX FAILED:', err.message);
    process.exit(1);
  }
}

fixDatabase();
