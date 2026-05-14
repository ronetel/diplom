const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const targets = [path.join(ROOT, 'backend'), path.join(ROOT, 'lib')];
const exts = ['.js', '.dart'];
const skipDirs = new Set(['node_modules', '.git', 'build', '.dart_tool']);
let files = [];

function walk(dir){
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries){
    const full = path.join(dir, e.name);
    if (e.isDirectory()){
      if (skipDirs.has(e.name)) continue;
      walk(full);
    } else if (e.isFile()){
      const ext = path.extname(e.name).toLowerCase();
      if (exts.includes(ext)) files.push(full);
    }
  }
}
for (const t of targets) walk(t);
files.sort();

function detectLibs(filePath, content){
  const libs = new Set();
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.js'){
    // require('x')
    const reqRe = /require\(['"`]([^'"`]+)['"`]\)/g;
    let m; while((m=reqRe.exec(content))){ libs.add(m[1]); }
    // import ... from 'x' or import 'x'
    const impRe = /import(?:[^'"`]*from)?\s*['"`]([^'"`]+)['"`]/g;
    while((m=impRe.exec(content))){ libs.add(m[1]); }
  } else if (ext === '.dart'){
    const impRe = /import\s+['"]([^'"]+)['"]/g;
    let m; while((m=impRe.exec(content))){ libs.add(m[1]); }
  }
  // Normalize: for packages take top-level name
  const normalized = Array.from(libs).map(s => {
    if (s.startsWith('.') || s.startsWith('..')) return s; // local
    if (s.startsWith('package:')) return s.split(':')[1].split('/')[0];
    // npm modules may be like @scope/name or name/path
    if (s.startsWith('@')) return s.split('/').slice(0,2).join('/');
    return s.split('/')[0];
  }).filter(Boolean);
  return Array.from(new Set(normalized));
}

function findAdditional(filePath){
  const dir = path.dirname(filePath);
  const base = path.basename(filePath, path.extname(filePath));
  const others = fs.readdirSync(dir).filter(f => {
    const b = path.basename(f, path.extname(f));
    return b === base && f !== path.basename(filePath);
  });
  return others;
}

let md = '';
md += '| Файл | Размер (KB) | Используемые библиотеки/модули | Доп. файлы |';
md += '|---|---:|---|---|';

for (const f of files){
  try{
    const rel = path.relative(ROOT, f).replace(/\\/g, '/');
    const stat = fs.statSync(f);
    const sizeKB = (stat.size/1024).toFixed(2);
    const content = fs.readFileSync(f,'utf8');
    const libs = detectLibs(f, content).join(', ');
    const add = findAdditional(f).join(', ');
    md += `| ${rel} | ${sizeKB} | ${libs || '-'} | ${add || '-'} |\n`;
  }catch(err){
    console.error('Error reading', f, err.message);
  }
}

const out = path.join(__dirname, '..', 'scripts', 'file_table.md');
fs.writeFileSync(out, md, 'utf8');
console.log('Wrote', out);
