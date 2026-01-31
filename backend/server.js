const app = require('./src/app');

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log('================================================');
  console.log('!!! KODE BARU SUDAH AKTIF (UPDATED CODE ACTIVE) !!!');
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
  console.log('================================================');

  // PROOF OF LIFE LOG
  try {
    const fs = require('fs');
    const path = require('path');
    fs.writeFileSync(path.join(__dirname, 'startup_log.txt'), 'Server Started at ' + new Date().toISOString());
  } catch(e) { console.error(e); }
});
