import { mkdir, writeFile, access } from 'node:fs/promises';
import { resolve } from 'node:path';
const [slug, ...words] = process.argv.slice(2);
if (!slug || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) { console.error('用法：npm run new -- my-first-post "我的第一篇文章"\n文件夹名只能使用小写英文、数字和连字符。'); process.exit(1); }
const dir=resolve('src/content/blog',slug);
try { await access(dir); console.error('该文章目录已存在，未覆盖任何内容。'); process.exit(1); } catch(error) { if(error.code !== 'ENOENT') throw error; }
const title=words.join(' ')||'新文章';
const now = new Date();
const date = new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Shanghai',year:'numeric',month:'2-digit',day:'2-digit'}).format(now);
await mkdir(dir,{recursive:true});
await writeFile(resolve(dir,'index.md'),`---\ntitle: ${JSON.stringify(title)}\ndescription: "用一两句话说明这篇文章回答什么问题。"\ndate: ${date}\ntags: [写作与整理]\ndraft: true\n---\n\n简要说明问题和适用环境。\n\n## 遇到的问题\n\n记录实际现象。\n\n## 判断过程\n\n说明证据，区分已确认和未确认的部分。\n\n## 处理方法\n\n记录操作及其原因。\n\n## 验证结果\n\n写明如何判断是否成功。\n`,{flag:'wx'});
console.log(`已创建草稿：${dir}/index.md\n图片放在同一目录。本地预览时可临时将 draft 改为 false。`);
