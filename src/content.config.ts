import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// 文章内容集合：src/content/posts/ 下的每个 .md 文件即一篇文章
const posts = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/posts' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    // 最后更新时间（可选）：有重大修改时在 frontmatter 里加 updated: 2026-09-04
    updated: z.coerce.date().optional(),
    category: z.string(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false)
  })
});

export const collections = { posts };
