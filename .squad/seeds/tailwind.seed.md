---
name: "tailwind"
matches: ["tailwind", "tailwindcss", "tailwind css"]
version: "4"
updated: "2026-03-30"
status: "beta"
---

# Tailwind CSS — Seed

## Critical Rules (LLM MUST follow these)
1. Utility-first: build UI entirely with utility classes. Only write custom CSS when Tailwind genuinely cannot express the style.
2. Mobile-first responsive design: base styles are mobile, then layer `sm:`, `md:`, `lg:`, `xl:` for larger screens.
3. Extract repeated class patterns into components (React/Vue/etc.), not into `@apply` blocks — the component IS the abstraction.
4. Use the `dark:` prefix for dark mode variants; never toggle classes manually with JS.
5. Use a `cn()` helper (e.g., `clsx` + `tailwind-merge`) for conditional and merged class names — never string concatenation.
6. Stick to the default spacing/sizing scale (multiples of 4px: `p-1` = 4px, `p-2` = 8px, etc.) for visual consistency.
7. Group related utilities in a consistent order: layout, sizing, spacing, typography, color, borders, effects, transitions.

## Golden Example
```tsx
import { cn } from "@/lib/utils";

interface CardProps {
  title: string;
  description: string;
  imageUrl: string;
  featured?: boolean;
}

function Card({ title, description, imageUrl, featured = false }: CardProps) {
  return (
    <article
      className={cn(
        "group flex flex-col overflow-hidden rounded-2xl",
        "bg-white shadow-sm ring-1 ring-gray-200",
        "transition-shadow duration-200 hover:shadow-md",
        "dark:bg-gray-900 dark:ring-gray-800",
        featured && "ring-2 ring-blue-500 dark:ring-blue-400"
      )}
    >
      <img
        src={imageUrl}
        alt=""
        className="h-48 w-full object-cover sm:h-56 lg:h-64"
      />
      <div className="flex flex-1 flex-col gap-2 p-4 sm:p-6">
        <h3
          className={cn(
            "text-lg font-semibold text-gray-900",
            "group-hover:text-blue-600",
            "dark:text-gray-100 dark:group-hover:text-blue-400"
          )}
        >
          {title}
        </h3>
        <p className="text-sm leading-relaxed text-gray-600 dark:text-gray-400">
          {description}
        </p>
        <button
          className={cn(
            "mt-auto inline-flex items-center justify-center",
            "rounded-lg px-4 py-2 text-sm font-medium",
            "bg-blue-600 text-white hover:bg-blue-700",
            "dark:bg-blue-500 dark:hover:bg-blue-600",
            "transition-colors duration-150",
            "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
          )}
        >
          Read more
        </button>
      </div>
    </article>
  );
}
```

## Common LLM Mistakes
- Overusing `@apply` to create utility bundles in CSS files — this defeats the purpose of utility-first and reintroduces the maintenance problems Tailwind solves. Extract a component instead.
- Writing custom CSS alongside Tailwind (`styles.module.css` with hand-written rules) — leads to specificity conflicts and two competing styling systems.
- Not designing mobile-first: writing desktop styles as the base and then overriding with `max-*` breakpoints — Tailwind's breakpoints are min-width; base = mobile.
- Using inconsistent spacing values (`p-[13px]`, `mt-[7px]`) instead of the default scale — breaks visual rhythm and makes the design harder to maintain.
- String-concatenating class names (`"p-4 " + (active ? "bg-blue-500" : "")`) instead of using `cn()` / `clsx` — produces bugs with extra spaces and no class deduplication.
