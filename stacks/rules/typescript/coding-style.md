---
paths:
  - "**/*.ts"
  - "**/*.tsx"
description: TypeScript coding conventions and style rules
---

# TypeScript Coding Style

Extends: [common/coding-style.md](../common/coding-style.md)

## Strict Mode Always

Every `tsconfig.json` must enable `"strict": true`. No exceptions.

## No `any` Type

Never use `any`. Use `unknown` with type guards or explicit types.

```typescript
// WRONG
function parseConfig(data: any): any {
  return data.settings;
}

function handleEvent(event: any) {
  console.log(event.target.value);
}

// CORRECT
function parseConfig(data: unknown): AppConfig {
  if (!isAppConfig(data)) {
    throw new ValidationError("Invalid configuration format");
  }
  return data;
}

function isAppConfig(data: unknown): data is AppConfig {
  return (
    typeof data === "object" &&
    data !== null &&
    "settings" in data &&
    typeof (data as Record<string, unknown>).settings === "object"
  );
}
```

## Prefer `const` Over `let`

Use `const` by default. Only use `let` when reassignment is genuinely needed. Never use `var`.

```typescript
// WRONG
let baseUrl = "https://api.example.com";
var items = getItems();
let total = items.reduce((sum, item) => sum + item.price, 0);

// CORRECT
const baseUrl = "https://api.example.com";
const items = getItems();
const total = items.reduce((sum, item) => sum + item.price, 0);
```

## Explicit Return Types on Public Functions

All exported functions and methods must have explicit return types.

```typescript
// WRONG
export function calculateTax(amount: number) {
  return amount * 0.2;
}

// CORRECT
export function calculateTax(amount: number): number {
  return amount * 0.2;
}

export async function fetchUser(id: string): Promise<User | null> {
  const response = await api.get(`/users/${id}`);
  return response.data ?? null;
}
```

## Discriminated Unions Over Enums

Use discriminated unions instead of enums for type safety and tree-shaking.

```typescript
// WRONG
enum Status {
  Pending = "pending",
  Active = "active",
  Inactive = "inactive",
}

function handleStatus(status: Status) { ... }

// CORRECT
type Status = "pending" | "active" | "inactive";

function handleStatus(status: Status): string {
  switch (status) {
    case "pending":
      return "Awaiting activation";
    case "active":
      return "Currently active";
    case "inactive":
      return "Deactivated";
  }
  // TypeScript exhaustiveness check — no default needed
}
```

For complex unions with associated data:

```typescript
type ApiResult<T> =
  | { status: "success"; data: T }
  | { status: "error"; error: string; code: number }
  | { status: "loading" };

function renderResult<T>(result: ApiResult<T>): void {
  switch (result.status) {
    case "success":
      display(result.data);     // TypeScript knows `data` exists
      break;
    case "error":
      showError(result.error);  // TypeScript knows `error` exists
      break;
    case "loading":
      showSpinner();
      break;
  }
}
```

## Readonly by Default

Use `Readonly<T>`, `ReadonlyArray<T>`, and `as const` to prevent mutations.

```typescript
// WRONG
interface AppConfig {
  apiUrl: string;
  features: string[];
}

// CORRECT
interface AppConfig {
  readonly apiUrl: string;
  readonly features: readonly string[];
}

// For constants
const SUPPORTED_LOCALES = ["en", "fr", "de"] as const;
type Locale = (typeof SUPPORTED_LOCALES)[number]; // "en" | "fr" | "de"
```

## Nullish Coalescing and Optional Chaining

Use `??` instead of `||` for defaults, and `?.` for safe access.

```typescript
// WRONG
const name = user.name || "Anonymous";     // falsy: "" becomes "Anonymous"
const city = user && user.address && user.address.city;

// CORRECT
const name = user.name ?? "Anonymous";     // only null/undefined
const city = user?.address?.city;
```

## Interface vs Type

- Use `interface` for object shapes that may be extended
- Use `type` for unions, intersections, and mapped types

```typescript
// Object shapes — use interface
interface UserProfile {
  readonly id: string;
  readonly name: string;
  readonly email: string;
}

// Unions and computed types — use type
type RequestMethod = "GET" | "POST" | "PUT" | "DELETE";
type Nullable<T> = T | null;
type UserKeys = keyof UserProfile;
```
