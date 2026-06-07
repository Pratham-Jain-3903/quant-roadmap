const db = require('./db');
const fs = require('fs');
const path = require('path');

async function run() {
  try {
    const sql = fs.readFileSync(path.join(__dirname, 'migration-v2.sql'), 'utf8');
    await db.query(sql);
    console.log('Migration v2 applied successfully');
  } catch (err) {
    console.error('Migration error:', err.message);
  }
  process.exit(0);
}
run();