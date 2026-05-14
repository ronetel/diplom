const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const targets = [path.join(ROOT, 'backend'), path.join(ROOT, 'lib')];
const exts = ['.js', '.dart'];
let changed = [];

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      // skip node_modules and common generated folders
      if (e.name === 'node_modules' || e.name === 'build' || e.name === '.dart_tool' || e.name === '.git') continue;
      walk(full);
    } else if (e.isFile()) {
      const ext = path.extname(e.name).toLowerCase();
      if (exts.includes(ext)) processFile(full);
    }
  }
}

function processFile(file) {
  try {
    let src = fs.readFileSync(file, 'utf8');
    const original = src;

    // Remove block comments /* ... */
    src = src.replace(/\/\*[\s\S]*?\*\//g, '');

    // Remove line comments //... (naive)
    // This will remove // comments at line ends. It may remove inside strings in rare cases.
    src = src.replace(/(^|[^:\\])\/\/.*$/gm, '$1');

    if (src !== original) {
      // Backup original
      const bak = file + '.bak';
      if (!fs.existsSync(bak)) fs.writeFileSync(bak, original, 'utf8');
      fs.writeFileSync(file, src, 'utf8');
      changed.push(file);
      console.log('Changed:', file);
    }
  } catch (err) {
    console.error('Error processing', file, err.message);
  }
}

for (const t of targets) {
  if (fs.existsSync(t)) walk(t);
}

console.log('\nDone. Files changed:', changed.length);
for (const f of changed) console.log(' -', f);

if (changed.length === 0) process.exit(0);
else process.exit(0);
