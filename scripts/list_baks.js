const fs = require('fs');
const path = require('path');
const roots = [path.resolve(__dirname,'..','backend'), path.resolve(__dirname,'..','lib')];
let found = [];
function walk(dir){
  if (!fs.existsSync(dir)) return;
  const entries = fs.readdirSync(dir, {withFileTypes:true});
  for (const e of entries){
    const full = path.join(dir, e.name);
    if (e.isDirectory()){
      if (e.name === 'node_modules' || e.name === '.git' || e.name === 'build' || e.name === '.dart_tool') continue;
      walk(full);
    } else if (e.isFile()){
      if (full.endsWith('.bak')) found.push(full);
    }
  }
}
for (const r of roots) walk(r);
console.log('Found', found.length, '.bak files');
for (const f of found) console.log(f);
