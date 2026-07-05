import { defineCollection, z } from 'astro:content';

// 博客文章集合
const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    tags: z.array(z.string()).default([]),
    readingTime: z.number().default(5),
    // 可选：是否为草稿，草稿不参与构建
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog };
