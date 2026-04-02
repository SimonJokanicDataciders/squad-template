---
name: "react"
matches: ["react", "reactjs", "react.js"]
version: "19"
updated: "2026-03-30"
status: "verified"
---

# React 19 — Seed

## Critical Rules (LLM MUST follow these)
1. Functional components only — never generate class components.
2. Define all props with TypeScript `interface` (not `type` alias) and apply them explicitly: `function Foo(props: FooProps)` or destructured.
3. Extract reusable logic into custom hooks (`use`-prefixed functions in their own file).
4. Never use `useEffect` for data fetching. Use React Query, SWR, or the React 19 `use()` hook with a promise/context.
5. Every element rendered inside `.map()` must have a stable, unique `key` prop — never use array index as key when the list can reorder.
6. Prefer composition (children, render props, slots) over prop drilling through intermediate components.
7. Co-locate state as close to where it is used as possible; lift only when truly shared.

## Golden Example
```tsx
// hooks/useUsers.ts
import { useQuery } from "@tanstack/react-query";

interface User {
  id: string;
  name: string;
  email: string;
}

export function useUsers(enabled: boolean) {
  return useQuery<User[]>({
    queryKey: ["users"],
    queryFn: () => fetch("/api/users").then((r) => r.json()),
    enabled,
  });
}

// components/UserCard.tsx
interface UserCardProps {
  name: string;
  email: string;
  onSelect: (email: string) => void;
}

function UserCard({ name, email, onSelect }: UserCardProps) {
  return (
    <button
      className="user-card"
      onClick={() => onSelect(email)}
    >
      <h3>{name}</h3>
      <p>{email}</p>
    </button>
  );
}

// components/UserList.tsx
import { useState } from "react";
import { useUsers } from "../hooks/useUsers";
import UserCard from "./UserCard";

function UserList() {
  const [selected, setSelected] = useState<string | null>(null);
  const { data: users, isLoading, error } = useUsers(true);

  if (isLoading) return <p>Loading users...</p>;
  if (error) return <p>Failed to load users.</p>;

  return (
    <ul>
      {users?.map((user) => (
        <li key={user.id}>
          <UserCard
            name={user.name}
            email={user.email}
            onSelect={setSelected}
          />
        </li>
      ))}
    </ul>
  );
}
```

## Common LLM Mistakes
- Using `useEffect` + `setState` to fetch data — causes waterfalls, race conditions, and no caching. Use React Query or `use()`.
- Typing props as `any` or omitting types entirely — eliminates the safety net TypeScript provides.
- Declaring inline arrow functions in JSX event handlers that capture new references every render (e.g., `onClick={() => handleClick(id)}` inside a large list) — causes unnecessary child re-renders. Memoize or move the handler into the child.
- Omitting `key` or using array index as key on reorderable lists — leads to stale state and broken animations.
- Prop drilling through 3+ levels instead of composing with `children` or using context — makes components rigid and hard to refactor.
