import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import { siteConfig } from '../site.config';

export async function GET(context) {
  const posts = (await getCollection('posts'))
    .filter((p) => !p.data.draft)
    .sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf());

  return rss({
    title: siteConfig.name,
    description: siteConfig.tagline,
    site: context.site,
    items: posts.map((p) => ({
      title: p.data.title,
      description: p.data.description,
      pubDate: p.data.date,
      link: `/posts/${p.id}/`
    }))
  });
}
