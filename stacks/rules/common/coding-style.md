---
description: Universal coding style conventions for all languages
---

# Universal Coding Style

## Immutability First

Prefer `const`, `readonly`, `final`, or equivalent in every language. Mutable state is the #1 source of bugs in production systems.

- Declare variables as immutable by default
- Only use mutable variables when mutation is genuinely required (e.g., accumulators in loops)
- Return new objects instead of modifying existing ones

## File Size Limits

| Metric | Ideal | Maximum |
|--------|-------|---------|
| Lines per file | 200-400 | 800 |
| Lines per function | 10-30 | 50 |
| Parameters per function | 1-3 | 5 |
| Nesting depth | 1-2 | 3 |

If a file exceeds 800 lines, split it. No exceptions.

## Naming Conventions

Use meaningful, pronounceable names. Never abbreviate.

```
WRONG:
  usr, mgr, svc, btn, ctx, req, res, cb, fn, val, tmp, idx

CORRECT:
  user, manager, service, button, context, request, response, callback, handler, value, temporary, index
```

### Naming Patterns

- **Boolean variables**: prefix with `is`, `has`, `should`, `can` — e.g., `isActive`, `hasPermission`
- **Functions**: start with a verb — e.g., `createUser`, `validateInput`, `fetchOrders`
- **Collections**: use plural nouns — e.g., `users`, `orderItems`, `validationErrors`
- **Constants**: UPPER_SNAKE_CASE — e.g., `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_MS`

## Error Handling

Handle errors at system boundaries. Do not swallow exceptions silently.

```
WRONG:
  try {
    riskyOperation();
  } catch (error) {
    // silently ignore
  }

CORRECT:
  try {
    riskyOperation();
  } catch (error) {
    logger.error("Operation failed", { error, context: operationId });
    throw new DomainError("Unable to complete operation", { cause: error });
  }
```

## Input Validation

Validate ALL external input at entry points — API controllers, CLI handlers, message consumers, file parsers.

```
WRONG:
  function processOrder(data) {
    const total = data.items.reduce((sum, i) => sum + i.price, 0);
    return total;
  }

CORRECT:
  function processOrder(data: OrderInput): number {
    if (!data?.items?.length) {
      throw new ValidationError("Order must contain at least one item");
    }
    for (const item of data.items) {
      if (typeof item.price !== "number" || item.price < 0) {
        throw new ValidationError(`Invalid price for item: ${item.id}`);
      }
    }
    return data.items.reduce((sum, item) => sum + item.price, 0);
  }
```

## Early Returns

Reduce nesting by returning early for error/edge cases.

```
WRONG:
  function getDiscount(user) {
    if (user) {
      if (user.isActive) {
        if (user.tier === "premium") {
          return 0.2;
        } else {
          return 0.1;
        }
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }

CORRECT:
  function getDiscount(user: User | null): number {
    if (!user) return 0;
    if (!user.isActive) return 0;
    if (user.tier === "premium") return 0.2;
    return 0.1;
  }
```

## Comments

- Do NOT comment WHAT the code does — the code should be self-documenting
- DO comment WHY a non-obvious decision was made
- Document public APIs with doc comments (JSDoc, XML docs, docstrings)
- Remove commented-out code — that is what version control is for

## Magic Numbers and Strings

Extract all magic values into named constants.

```
WRONG:
  if (retryCount > 3) { ... }
  if (status === "ACT") { ... }

CORRECT:
  const MAX_RETRIES = 3;
  const STATUS_ACTIVE = "active";

  if (retryCount > MAX_RETRIES) { ... }
  if (status === STATUS_ACTIVE) { ... }
```
