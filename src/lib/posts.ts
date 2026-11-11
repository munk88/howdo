import { getCollection, type CollectionEntry } from 'astro:content';
export type Post = CollectionEntry<'blog'>;
export async function posts() { return (await getCollection('blog', ({ data }) => !data.draft)).sort((a,b) => b.data.date.valueOf() - a.data.date.valueOf() || a.id.localeCompare(b.id)); }
export const dateLabel = (date: Date) => date.toISOString().slice(0,10).replaceAll('-', '.');
export const readingTime = (body = '') => Math.max(1, Math.ceil((body.match(/[\u3400-\u9fff]/g)?.length ?? 0) / 350 + (body.match(/[a-zA-Z]+/g)?.length ?? 0) / 200));
export const articleUrl = (post: Post) => `/articles/${post.id}/`;
export const tagUrl = (tag: string) => `/topics/${encodeURIComponent(tag)}/`;
