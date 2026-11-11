import { mkdir, copyFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
const date=new Date().toISOString().replaceAll(':','-').slice(0,19);
await mkdir('release',{recursive:true});
execFileSync('tar',['-czf',`release/howdo-static-${date}.tar.gz`,'-C','dist','.'],{stdio:'inherit'});
execFileSync('tar',['--exclude=./node_modules','--exclude=./.git','--exclude=./.astro','--exclude=./dist','--exclude=./release','--exclude=./backups','--exclude=*.key','--exclude=*.pem','--exclude=./.env','--exclude=./.env.*','--exclude=./.DS_Store','-czf',`release/howdo-source-${date}.tar.gz`,'.'],{stdio:'inherit'});
await copyFile('MIGRATION.md','release/MIGRATION.md');
console.log('源码与静态文件已分别打包到 release/。该目录不会提交到 Git，请另外保存。');
