const mysql = require('mysql2/promise');

async function checkLocalData() {
  const conn = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'skillbarter_db'
  });

  console.log('📊 Checking Local Database Stats...\n');

  const tables = ['User', 'Skill', 'Barter', 'Notification', 'SkillCoin_Transaction', 'Review'];

  for (const table of tables) {
    try {
      const [rows] = await conn.query(`SELECT COUNT(*) as count FROM \`${table}\``);
      console.log(`${table.padEnd(25)} : ${rows[0].count} rows`);
    } catch (e) {
      console.log(`${table.padEnd(25)} : ❌ ${e.message}`);
    }
  }

  await conn.end();
  console.log('\n✅ Check complete!');
}

checkLocalData();
