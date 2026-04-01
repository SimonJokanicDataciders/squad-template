---
paths:
  - "**/*.ts"
  - "**/*.tsx"
description: TypeScript architectural patterns and conventions
---

# TypeScript Patterns

## Generic ApiResponse Interface

Use a single response wrapper for all API communication.

```typescript
interface ApiResponse<T> {
  readonly success: boolean;
  readonly data: T | null;
  readonly errors: readonly string[];
  readonly meta?: {
    readonly page: number;
    readonly pageSize: number;
    readonly totalCount: number;
  };
}

function createSuccess<T>(data: T): ApiResponse<T> {
  return { success: true, data, errors: [] };
}

function createError<T = never>(errors: string[]): ApiResponse<T> {
  return { success: false, data: null, errors };
}
```

## Service Layer Pattern

Encapsulate all API calls in typed service modules. Never call `fetch` directly from components.

```typescript
// src/services/orderService.ts
import { z } from "zod";

const OrderSchema = z.object({
  id: z.number(),
  customerId: z.number(),
  items: z.array(z.object({
    productId: z.number(),
    quantity: z.number().min(1),
    unitPrice: z.number().positive(),
  })),
  total: z.number(),
  status: z.enum(["pending", "shipped", "delivered", "cancelled"]),
  createdAt: z.string().datetime(),
});

type Order = z.infer<typeof OrderSchema>;

const CreateOrderRequestSchema = z.object({
  customerId: z.number().positive(),
  items: z.array(z.object({
    productId: z.number().positive(),
    quantity: z.number().int().min(1).max(1000),
    unitPrice: z.number().positive(),
  })).min(1, "Order must contain at least one item"),
});

type CreateOrderRequest = z.infer<typeof CreateOrderRequestSchema>;

const BASE_URL = "/api/orders";

export const orderService = {
  async getAll(): Promise<ApiResponse<readonly Order[]>> {
    const response = await fetch(BASE_URL);
    const json = await response.json();
    const parsed = z.array(OrderSchema).safeParse(json.data);
    if (!parsed.success) {
      return createError(parsed.error.issues.map((i) => i.message));
    }
    return createSuccess(parsed.data);
  },

  async getById(id: number): Promise<ApiResponse<Order>> {
    const response = await fetch(`${BASE_URL}/${id}`);
    if (response.status === 404) {
      return createError(["Order not found"]);
    }
    const json = await response.json();
    const parsed = OrderSchema.safeParse(json.data);
    if (!parsed.success) {
      return createError(parsed.error.issues.map((i) => i.message));
    }
    return createSuccess(parsed.data);
  },

  async create(request: CreateOrderRequest): Promise<ApiResponse<Order>> {
    const validation = CreateOrderRequestSchema.safeParse(request);
    if (!validation.success) {
      return createError(validation.error.issues.map((i) => i.message));
    }
    const response = await fetch(BASE_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(validation.data),
    });
    const json = await response.json();
    return createSuccess(OrderSchema.parse(json.data));
  },
} as const;
```

## Custom Hooks Pattern

Extract reusable logic into custom hooks with clear naming.

```typescript
// src/hooks/useDebounce.ts
import { useEffect, useState } from "react";

export function useDebounce<T>(value: T, delayMs: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debouncedValue;
}

// src/hooks/useFetch.ts
import { useCallback, useEffect, useState } from "react";

interface UseFetchResult<T> {
  readonly data: T | null;
  readonly error: string | null;
  readonly isLoading: boolean;
  readonly refetch: () => void;
}

export function useFetch<T>(url: string): UseFetchResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [fetchCount, setFetchCount] = useState<number>(0);

  const refetch = useCallback(() => setFetchCount((c) => c + 1), []);

  useEffect(() => {
    const controller = new AbortController();
    setIsLoading(true);
    setError(null);

    fetch(url, { signal: controller.signal })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((json: T) => setData(json))
      .catch((err: Error) => {
        if (err.name !== "AbortError") setError(err.message);
      })
      .finally(() => setIsLoading(false));

    return () => controller.abort();
  }, [url, fetchCount]);

  return { data, error, isLoading, refetch };
}
```

## Zod for Runtime Validation

Always validate data at system boundaries (API responses, form submissions, URL params).

```typescript
import { z } from "zod";

// Define the schema once — derive the type from it
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(["admin", "editor", "viewer"]),
  createdAt: z.string().datetime(),
});

type User = z.infer<typeof UserSchema>;

// Validate at boundaries
function parseUserResponse(data: unknown): User {
  return UserSchema.parse(data); // throws ZodError if invalid
}

// Safe parsing for UI
function tryParseUser(data: unknown): User | null {
  const result = UserSchema.safeParse(data);
  return result.success ? result.data : null;
}
```
