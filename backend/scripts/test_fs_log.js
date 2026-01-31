const fs = require('fs');
const path = require('path');

const logPath = path.join(__dirname, '../error_logs.txt');
console.log('Attempting to write to:', logPath);

try {
  const timestamp = new Date().toISOString();
  fs.appendFileSync(logPath, `[${timestamp}] TEST LOG ENTRY\n`);
  console.log('✅ Success! Write completed.');
  
  if (fs.existsSync(logPath)) {
      console.log('✅ File exists.');
      console.log('Content:', fs.readFileSync(logPath, 'utf8'));
  } else {
      console.log('❌ File does not exist after write?');
  }
} catch (e) {
  console.error('❌ Failed to write:', e);
}
