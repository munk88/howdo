import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import rehypeSlug from 'rehype-slug';

// site：你的真实域名
export default defineConfig({
  site: 'https://howdo.icu',
  trailingSlash: 'ignore',
  integrations: [sitemap()],
  markdown: {
    rehypePlugins: [rehypeSlug]
  }
});
