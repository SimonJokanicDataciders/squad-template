---
name: "express"
matches: ["express", "express.js", "expressjs"]
version: "5.x"
updated: "2026-03-30"
status: "verified"
---

# Express.js 5.x — Seed

## Critical Rules (LLM MUST follow these)
1. Group routes using `Router()` — never attach handlers directly to `app`.
2. Use a shared `asyncHandler` wrapper — never use try/catch inside individual route handlers.
3. Validate all request bodies and params with Zod schemas before touching business logic.
4. Every JSON response MUST use the shape `{ data, error }` — `data` is `null` on error, `error` is `null` on success.
5. Use correct HTTP status codes: 201 for creation, 204 for deletion, 400 for validation, 404 for not found, 500 for server errors.
6. Keep route files thin — delegate business logic to a service layer.
7. Register a centralized async error middleware as the last middleware in the chain.

## Golden Example
```ts
// src/routes/products.router.ts
import { Router, Request, Response } from "express";
import { z } from "zod";
import { asyncHandler } from "../middleware/asyncHandler";
import * as productService from "../services/product.service";

const router = Router();

const CreateProductSchema = z.object({
  name: z.string().min(1).max(120),
  price: z.number().positive(),
});

router.get(
  "/",
  asyncHandler(async (_req: Request, res: Response) => {
    const products = await productService.listAll();
    res.json({ data: products, error: null });
  })
);

router.post(
  "/",
  asyncHandler(async (req: Request, res: Response) => {
    const body = CreateProductSchema.parse(req.body);
    const product = await productService.create(body);
    res.status(201).json({ data: product, error: null });
  })
);

export default router;

// src/middleware/asyncHandler.ts
import { Request, Response, NextFunction } from "express";

export const asyncHandler =
  (fn: (req: Request, res: Response, next: NextFunction) => Promise<void>) =>
  (req: Request, res: Response, next: NextFunction) =>
    Promise.resolve(fn(req, res, next)).catch(next);

// src/middleware/errorHandler.ts  (register LAST)
import { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    res.status(400).json({ data: null, error: err.flatten().fieldErrors });
    return;
  }
  res.status(500).json({ data: null, error: "Internal server error" });
}
```

## Common LLM Mistakes
- Wrapping every handler in its own try/catch — duplicates error logic and misses the centralized error middleware pattern.
- Using `app.get()` / `app.post()` directly instead of `Router()` — leads to an unorganizable monolith.
- Returning raw objects without the `{ data, error }` envelope — breaks client-side parsing contracts.
- Skipping Zod validation and trusting `req.body` — allows malformed data into the service layer.
- Forgetting to call `next(err)` or not registering the error middleware last — errors silently disappear.
