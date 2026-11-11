import { readdir, readFile, access } from 'node:fs/promises';
import { join, resolve, extname } from 'node:path';
import { load } from 'cheerio';
const root=resolve('dist'); let pages=0, links=0; const failures=[]; const documents=new Map();
async function walk(dir){const files=[];for(const entry of await readdir(dir,{withFileTypes:true})){const path=join(dir,entry.name); if(entry.isDirectory())files.push(...await walk(path));else files.push(path);}return files;}
for(const file of (await walk(root)).filter(p=>p.endsWith('.html'))){documents.set(file,load(await readFile(file,'utf8')));}
for(const [file,$] of documents){pages++;const route=file.slice(root.length).replace(/index\.html$/,'');
const check=(condition,message)=>{if(!condition)failures.push(`${route}: ${message}`);};
check($('title').text().length>0,'缺少标题');check($('meta[name="description"]').attr('content'),'缺少描述');check($('h1').length===1,'必须有且只有一个 H1');check($('link[rel="canonical"]').attr('href')===new URL(route,'https://howdo.icu').href,'canonical 与 howdo.icu 路径不符');
$('script[type="application/ld+json"]').each((_,el)=>{try{JSON.parse($(el).html());}catch{failures.push(`${route}: 无效 JSON-LD`);}});
$('img').each((_,el)=>{check(Boolean($(el).attr('alt')),'图片缺少说明');check($(el).attr('width')&&$(el).attr('height'),'图片缺少尺寸');});
for(const el of $('a[href],img[src],link[href],script[src]').toArray()){
 const raw=$(el).attr('href')??$(el).attr('src'); if(!raw||/^(mailto:|tel:|data:|javascript:)/.test(raw))continue;
 const url=new URL(raw,`https://howdo.icu${route}`);if(url.origin!=='https://howdo.icu')continue;
 links++;let target=resolve(root,decodeURIComponent(url.pathname).replace(/^\//,'')); if(!target.startsWith(root+'/')&&target!==root){failures.push(`${route}: 路径越界 ${raw}`);continue;}
 if(!extname(target))target=join(target,'index.html');
 try{await access(target);}catch{failures.push(`${route}: 链接或资源不存在 ${raw}`);continue;}
 if(url.hash && documents.has(target)){const id=decodeURIComponent(url.hash.slice(1));const found=documents.get(target)('[id]').toArray().some(el=>documents.get(target)(el).attr('id')===id);check(found,`锚点不存在 ${raw}`);}
}
}
for(const file of ['rss.xml','sitemap-index.xml','robots.txt','search-index.json','404.html']){try{await access(join(root,file));}catch{failures.push(`缺少 ${file}`);}}
const index=JSON.parse(await readFile(join(root,'search-index.json'),'utf8'));if(!Array.isArray(index))failures.push('搜索索引格式不正确');
if(failures.length){console.error(failures.join('\n'));process.exit(1);}console.log(`PASS: ${pages} 个页面，${links} 个站内链接与资源；标题、描述、canonical、图片尺寸、目录锚点、JSON-LD、RSS、Sitemap。`);
