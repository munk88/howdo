import { posts, articleUrl } from '../lib/posts';
export async function GET() { return Response.json((await posts()).map(post=>({title:post.data.title,description:post.data.description,tags:post.data.tags,text:post.body??'',url:articleUrl(post),example:post.data.example}))); }
