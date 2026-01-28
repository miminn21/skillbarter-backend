const db = require('../src/config/database');

async function check() {
  try {
    const [cols] = await db.execute("SHOW COLUMNS FROM keahlian LIKE 'gambar_skill'");
    console.log('Column Definition:', cols);
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

check();
