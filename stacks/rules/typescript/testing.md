---
paths:
  - "**/*.ts"
  - "**/*.tsx"
description: TypeScript testing conventions with Vitest and Testing Library
---

# TypeScript Testing

Extends: [common/testing.md](../common/testing.md)

## Test Stack

| Tool | Purpose |
|------|---------|
| **Vitest** (preferred) or **Jest** | Test runner and assertions |
| **Testing Library** | Component testing (React/Angular) |
| **MSW (Mock Service Worker)** | API mocking at the network level |
| **Playwright** | End-to-end browser tests |

## Test File Location

Place test files next to the source file with `.test.ts` or `.test.tsx` suffix:

```
src/
  services/
    orderService.ts
    orderService.test.ts
  components/
    OrderList.tsx
    OrderList.test.tsx
  hooks/
    useFetch.ts
    useFetch.test.ts
```

## Test Naming

Use `describe` / `it` blocks with clear behavioral descriptions.

```typescript
// WRONG
describe("OrderList", () => {
  it("works", () => { ... });
  it("test 2", () => { ... });
});

// CORRECT
describe("OrderList", () => {
  it("renders a list of orders when data is loaded", () => { ... });
  it("shows a loading spinner while fetching orders", () => { ... });
  it("displays an error message when the API request fails", () => { ... });
  it("shows an empty state when no orders exist", () => { ... });
});
```

## Mock API Calls, Not Internal Logic

Use MSW to intercept network requests instead of mocking service internals.

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("/api/orders", () => {
    return HttpResponse.json({
      success: true,
      data: [
        { id: 1, customerId: 10, total: 99.99, status: "pending" },
        { id: 2, customerId: 20, total: 149.50, status: "shipped" },
      ],
      errors: [],
    });
  }),

  http.get("/api/orders/:id", ({ params }) => {
    const { id } = params;
    if (id === "999") {
      return HttpResponse.json(
        { success: false, data: null, errors: ["Order not found"] },
        { status: 404 },
      );
    }
    return HttpResponse.json({
      success: true,
      data: { id: Number(id), customerId: 10, total: 99.99, status: "pending" },
      errors: [],
    });
  }),
];
```

## Component Test Example

Test user behavior, not implementation details. Query by role, label, or text — never by CSS class or test ID unless no semantic alternative exists.

```typescript
// src/components/OrderList.test.tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";
import { describe, it, expect, beforeAll, afterAll, afterEach } from "vitest";
import { OrderList } from "./OrderList";

const server = setupServer(
  http.get("/api/orders", () => {
    return HttpResponse.json({
      success: true,
      data: [
        { id: 1, customerId: 10, total: 99.99, status: "pending" },
        { id: 2, customerId: 20, total: 149.50, status: "shipped" },
      ],
      errors: [],
    });
  }),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe("OrderList", () => {
  it("renders a list of orders when data is loaded", async () => {
    render(<OrderList />);

    await waitFor(() => {
      expect(screen.getByText("$99.99")).toBeInTheDocument();
      expect(screen.getByText("$149.50")).toBeInTheDocument();
    });

    const rows = screen.getAllByRole("row");
    expect(rows).toHaveLength(3); // header + 2 data rows
  });

  it("shows a loading spinner while fetching orders", () => {
    render(<OrderList />);
    expect(screen.getByRole("progressbar")).toBeInTheDocument();
  });

  it("displays an error message when the API request fails", async () => {
    server.use(
      http.get("/api/orders", () => {
        return HttpResponse.json(
          { success: false, data: null, errors: ["Internal server error"] },
          { status: 500 },
        );
      }),
    );

    render(<OrderList />);

    await waitFor(() => {
      expect(screen.getByRole("alert")).toHaveTextContent("Internal server error");
    });
  });

  it("filters orders when search text is entered", async () => {
    const user = userEvent.setup();
    render(<OrderList />);

    await waitFor(() => {
      expect(screen.getByText("$99.99")).toBeInTheDocument();
    });

    const searchInput = screen.getByRole("searchbox", { name: /search orders/i });
    await user.type(searchInput, "shipped");

    expect(screen.queryByText("$99.99")).not.toBeInTheDocument();
    expect(screen.getByText("$149.50")).toBeInTheDocument();
  });
});
```

## Service Test Example

```typescript
// src/services/orderService.test.ts
import { describe, it, expect, beforeAll, afterAll, afterEach } from "vitest";
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";
import { orderService } from "./orderService";

const server = setupServer();
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe("orderService.getById", () => {
  it("returns the order when it exists", async () => {
    server.use(
      http.get("/api/orders/1", () => {
        return HttpResponse.json({
          success: true,
          data: { id: 1, customerId: 10, total: 99.99, status: "pending", items: [], createdAt: "2025-01-01T00:00:00Z" },
        });
      }),
    );

    const result = await orderService.getById(1);

    expect(result.success).toBe(true);
    expect(result.data?.id).toBe(1);
    expect(result.data?.total).toBe(99.99);
  });

  it("returns an error when the order does not exist", async () => {
    server.use(
      http.get("/api/orders/999", () => {
        return HttpResponse.json(null, { status: 404 });
      }),
    );

    const result = await orderService.getById(999);

    expect(result.success).toBe(false);
    expect(result.errors).toContain("Order not found");
  });
});
```
