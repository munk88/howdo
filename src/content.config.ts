import { defineCollection } from 'astro:content';
import { z } from 'astro/zod';
import { glob } from 'astro/loaders';
const blog = defineCollection({
  loader: glob({ pattern: '**/index.md', base: './src/content/blog', generateId: ({ entry }) => entry.replace(/\/index\.md$/, '') }),
  schema: z.object({ title: z.string(), description: z.string(), date: z.coerce.date(), updated: z.coerce.date().optional(), tags: z.array(z.string()).default([]), draft: z.boolean().default(false), example: z.boolean().default(false), featured: z.boolean().default(false) }),
});
export const collections = { blog };
