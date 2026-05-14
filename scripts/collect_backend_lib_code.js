const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const targets = [path.join(ROOT, 'backend'), path.join(ROOT, 'lib')];
const exts = ['.js', '.dart'];
const outPath = path.join(__dirname, '..', 'scripts', 'collected_code.txt');
const skipDirs = new Set(['node_modules', '.git', 'build', '.dart_tool']);

let files = [];

function walk(dir) {
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (skipDirs.has(e.name)) continue;
      walk(full);
    } else if (e.isFile()) {
      if (full.endsWith('.bak')) continue;
      const ext = path.extname(e.name).toLowerCase();
      if (exts.includes(ext)) files.push(full);
    }
  }
}

for (const t of targets) walk(t);

files.sort();

let out = '';
for (const f of files) {
  const rel = path.relative(ROOT, f).replace(/\\/g, '/');
  out += `\n=== FILE: ${rel} ===\n`;
  try {
    const src = fs.readFileSync(f, 'utf8');
    out += src;
  } catch (err) {
    out += `\n<ERROR READ FILE: ${err.message}>\n`;
  }
}

fs.writeFileSync(outPath, out, 'utf8');
console.log('Collected', files.length, 'files to', outPath);
