---
name: "nextjs"
matches: ["next", "nextjs", "next.js"]
version: "15"
updated: "2026-03-30"
status: "verified"
---

# Next.js 15 App Router — Seed

## Critical Rules (LLM MUST follow these)
1. Always use the App Router (`app/` directory) — never generate Pages Router (`pages/`) code.
2. Components are Server Components by default. Only add `'use client'` when the component needs browser APIs, hooks, or event handlers.
3. Use Server Actions (`'use server'`) for form submissions and data mutations — not API route handlers.
4. Every route segment should include `loading.tsx` and `error.tsx` for proper Suspense/Error boundaries.
5. Export `metadata` (or `generateMetadata`) from `page.tsx` and `layout.tsx` for SEO.
6. Fetch data directly in Server Components using `async/await` — no need for `getServerSideProps` or `useEffect`.
7. Use `next/image`, `next/link`, and `next/font` — never raw `<img>`, `<a>` for internal links, or manual font loading.

## Golden Example
```tsx
// app/posts/layout.tsx
import type { ReactNode } from "react";

export const metadata = {
  title: "Blog Posts",
  description: "Browse all published posts.",
};

export default function PostsLayout({ children }: { children: ReactNode }) {
  return (
    <section className="mx-auto max-w-3xl px-4 py-8">
      {children}
    </section>
  );
}

// app/posts/loading.tsx
export default function Loading() {
  return <p className="animate-pulse">Loading posts...</p>;
}

// app/posts/error.tsx
"use client";
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <p>Something went wrong: {error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}

// app/posts/page.tsx
import { db } from "@/lib/db";
import { CreatePostForm } from "./create-post-form";

export default async function PostsPage() {
  const posts = await db.post.findMany({ orderBy: { createdAt: "desc" } });

  return (
    <div>
      <h1>Posts</h1>
      <CreatePostForm />
      <ul>
        {posts.map((post) => (
          <li key={post.id}>{post.title}</li>
        ))}
      </ul>
    </div>
  );
}

// app/posts/actions.ts
"use server";
import { revalidatePath } from "next/cache";
import { db } from "@/lib/db";

export async function createPost(formData: FormData) {
  const title = formData.get("title") as string;
  await db.post.create({ data: { title } });
  revalidatePath("/posts");
}

// app/posts/create-post-form.tsx
"use client";
import { createPost } from "./actions";

export function CreatePostForm() {
  return (
    <form action={createPost}>
      <input name="title" placeholder="Post title" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

## Common LLM Mistakes
- Marking every component `'use client'` — destroys the Server Component advantage (smaller bundles, direct DB access, zero client JS).
- Creating `/api/` route handlers for form mutations instead of Server Actions — adds unnecessary network round-trips and boilerplate.
- Forgetting `loading.tsx` / `error.tsx` — users see a blank screen or an unhandled crash instead of a graceful fallback.
- Fetching data in Client Components with `useEffect` when the same data could be fetched on the server with zero client JS.
- Using `getServerSideProps` or `getStaticProps` — these belong to Pages Router and do not exist in App Router.
