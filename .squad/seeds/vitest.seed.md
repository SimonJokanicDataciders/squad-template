---
name: "vitest"
matches: ["vitest"]
version: "3.1"
updated: "2026-03-30"
status: "verified"
---

# Vitest — Seed

## Critical Rules (LLM MUST follow these)
1. Vitest shares Jest's API surface (`describe`, `it`, `expect`) but use `vi` — never `jest` — for mocking utilities.
2. Use `vi.fn()` for function mocks, `vi.mock()` for module mocks, and `vi.spyOn()` for spies.
3. Call `vi.clearAllMocks()` in `afterEach` to prevent mock state leaking between tests.
4. Use `test.each` (or `it.each`) for parameterized / data-driven tests instead of loops.
5. Prefer MSW (Mock Service Worker) for intercepting HTTP calls — avoid mocking `fetch` or `axios` directly.
6. Always `await` async operations; Vitest will not catch unawaited assertion failures.
7. Keep `vitest.config.ts` separate or merge into `vite.config.ts` under `test` — never mix Jest config files.
8. Use in-source testing (`if (import.meta.vitest)`) only for small utility functions, not for application logic.

## Golden Example
```typescript
import { describe, it, expect, vi, afterEach } from "vitest";
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";
import { fetchUsers } from "../api/users";

const server = setupServer(
  http.get("https://api.example.com/users", () => {
    return HttpResponse.json([
      { id: 1, name: "Alice" },
      { id: 2, name: "Bob" },
    ]);
  })
);

beforeAll(() => server.listen());
afterEach(() => {
  server.resetHandlers();
  vi.clearAllMocks();
});
afterAll(() => server.close());

describe("fetchUsers", () => {
  it("should return a list of users", async () => {
    const users = await fetchUsers();

    expect(users).toHaveLength(2);
    expect(users[0]).toEqual({ id: 1, name: "Alice" });
  });

  it("should throw on server error", async () => {
    server.use(
      http.get("https://api.example.com/users", () => {
        return new HttpResponse(null, { status: 500 });
      })
    );

    await expect(fetchUsers()).rejects.toThrow("Failed to fetch users");
  });

  it.each([
    { role: "admin", expected: 5 },
    { role: "viewer", expected: 2 },
  ])("should return $expected users for role $role", async ({ role, expected }) => {
    server.use(
      http.get("https://api.example.com/users", ({ request }) => {
        const url = new URL(request.url);
        const count = url.searchParams.get("role") === "admin" ? 5 : 2;
        return HttpResponse.json(Array.from({ length: count }, (_, i) => ({ id: i })));
      })
    );

    const users = await fetchUsers(role);
    expect(users).toHaveLength(expected);
  });
});
```

## Common LLM Mistakes
- **Using `jest.fn()` or `jest.mock()` instead of `vi.fn()` / `vi.mock()`.** Vitest does not expose Jest globals; `jest` will be undefined at runtime.
- **Forgetting `vi.clearAllMocks()` in `afterEach`.** Mock call counts and implementations persist across tests, causing false positives and flaky results.
- **Synchronous assertions on async code.** Writing `expect(fetchData()).toEqual(...)` without `await` silently passes because it compares a Promise object, not the resolved value.
- **Mocking `fetch` directly instead of using MSW.** Direct mocking is fragile and skips request serialization; MSW intercepts at the network level and tests the real code path.
- **Importing from `@jest/globals`.** This package does not exist in a Vitest project. Import from `vitest` instead.
