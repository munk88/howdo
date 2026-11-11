import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
export default defineConfig({ site: 'https://howdo.icu', output: 'static', trailingSlash: 'always', integrations: [sitemap({ filter: (page) => !['/search/', '/404/', '/404.html'].includes(new URL(page).pathname) })], markdown: { shikiConfig: { theme: 'github-light' } } });
