import rss from '@astrojs/rss';
import { posts, articleUrl } from '../lib/posts';
import { site } from '../config';
export async function GET() { return rss({title:site.name,description:site.description,site:site.url,customData:'<language>zh-CN</language>',items:(await posts()).map(post=>({title:post.data.title,description:post.data.description,pubDate:post.data.date,link:articleUrl(post),categories:post.data.tags}))}); }
