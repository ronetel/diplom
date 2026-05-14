const fs = require('fs');
const path = require('path');
const roots = [path.resolve(__dirname,'..','backend'), path.resolve(__dirname,'..','lib')];
const skipDirs = new Set(['node_modules', '.git', 'build', '.dart_tool']);
let deleted = [];

function walk(dir){
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, {withFileTypes:true});
  for (const e of entries){
    const full = path.join(dir, e.name);
    if (e.isDirectory()){
      if (skipDirs.has(e.name)) continue;
      walk(full);
    } else if (e.isFile()){
      if (full.endsWith('.bak')){
        try {
          fs.unlinkSync(full);
          deleted.push(full);
        } catch(err){
          console.error('Failed to delete', full, err.message);
        }
      }
    }
  }
}

for (const r of roots) walk(r);
console.log('Deleted', deleted.length, '.bak files');
for (const f of deleted) console.log(' -', f);
