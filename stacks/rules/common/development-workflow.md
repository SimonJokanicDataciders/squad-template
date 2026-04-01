---
description: Five-phase development workflow for implementing features
---

# Development Workflow

## Five-Phase Feature Pipeline

Every feature, bug fix, or improvement follows these five phases in order. Do not skip phases.

### Phase 1: Research and Reuse

Before writing ANY code, search for existing solutions:

1. **Project codebase** — search for similar patterns already implemented
   - Look for existing utilities, helpers, and base classes
   - Check if another module solved the same problem
   - Identify shared components that can be extended

2. **Package registries** — check for maintained libraries
   - npm / NuGet / PyPI for the relevant stack
   - Evaluate: maintenance status, download count, license, bundle size
   - Prefer well-maintained packages over custom implementations for non-core logic

3. **Internal documentation** — check wikis, ADRs, and READMEs
   - Previous architectural decisions may already address your use case
   - Existing conventions may dictate the approach

```
WRONG:
  Immediately start coding a date parsing utility.

CORRECT:
  1. Search the codebase: "Do we already have date utilities?"
  2. Check packages: "Does date-fns or Luxon already solve this?"
  3. Check docs: "Is there a standard for date handling in this project?"
  4. Only then: implement if nothing exists.
```

### Phase 2: Plan First

Define the implementation plan BEFORE writing code:

1. **File paths** — list every file you will create or modify
2. **Interfaces** — define the public contracts (function signatures, types, API shapes)
3. **Dependencies** — identify what you need from other modules and what they need from you
4. **Edge cases** — list known edge cases and how you will handle them
5. **Risks** — what could go wrong, what is the rollback plan

```
Example Plan:
  Files:
    - src/features/orders/CreateOrderEndpoint.cs (new)
    - src/features/orders/CreateOrderRequest.cs (new)
    - src/features/orders/IOrderRepository.cs (modify — add CreateAsync)
    - tests/features/orders/CreateOrderEndpointTests.cs (new)

  Interfaces:
    - POST /api/orders → CreateOrderRequest → ApiResponse<OrderDto>
    - IOrderRepository.CreateAsync(Order) → Order

  Edge Cases:
    - Empty cart → return 400
    - Out-of-stock item → return 409
    - Concurrent duplicate submission → idempotency key
```

### Phase 3: Implement

Follow reference implementation patterns exactly:

1. **Match existing patterns** — if the project uses a specific folder structure, endpoint pattern, or naming convention, follow it identically
2. **One concern per file** — each file has a single responsibility
3. **Compile/lint after every change** — do not batch up multiple changes before verifying
4. **Commit at logical checkpoints** — each commit should compile and pass existing tests

```
WRONG:
  Write 500 lines across 8 files, then try to compile.

CORRECT:
  1. Create the request/response types → compile → commit
  2. Create the repository method → compile → commit
  3. Create the endpoint → compile → commit
  4. Wire up DI registration → compile → commit
```

### Phase 4: Test

Write tests alongside implementation, not after:

1. Write the test for the next behavior before implementing it (TDD)
2. Cover the happy path first, then edge cases, then error cases
3. Run the full test suite before moving to Phase 5
4. If coverage is below the threshold, add tests before proceeding

### Phase 5: Review and Document

Self-review before creating a PR:

1. **Re-read every changed file** — look for leftover debug code, TODO comments, and dead code
2. **Run the linter and formatter** — no warnings allowed
3. **Update documentation** if the change affects:
   - API contracts (OpenAPI/Swagger)
   - Configuration options
   - Environment variables
   - Deployment steps
4. **Write the PR description** — explain WHY, not WHAT

## Decision Records

When you make a non-obvious technical decision, document it:

```markdown
## Decision: Use Redis for session storage

**Context**: We need session storage that survives app restarts.
**Options considered**: In-memory, SQL database, Redis.
**Decision**: Redis — fast reads, built-in expiry, horizontally scalable.
**Consequences**: Adds Redis as an infrastructure dependency.
```
