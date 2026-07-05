import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  site: 'https://howdo.icu',
  // 构建产物输出到 ./dist，部署时整体同步到 VPS
  output: 'static',
  build: {
    // 内联小 CSS，减少请求数
    inlineStylesheets: 'auto',
  },
});
