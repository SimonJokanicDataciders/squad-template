---
name: "jest"
matches: ["jest", "jestjs"]
version: "29.7"
updated: "2026-03-30"
status: "verified"
---

# Jest — Seed

## Critical Rules (LLM MUST follow these)
1. Use `describe` blocks to group related tests and `it` (or `test`) blocks for individual cases.
2. Each `it` block should focus on a single assertion or closely related assertions — one behavior per test.
3. Use `jest.fn()` to create mock functions; never hand-roll stub objects when a mock will do.
4. Place shared setup in `beforeEach`, not at the top of `describe` — ensures isolation between tests.
5. Tests must be independent: no test may rely on state produced by another test.
6. Always `await` async operations and return the promise or use `async/await` — never fire-and-forget.
7. Use `supertest` (or similar) for HTTP/API integration tests against an Express/Koa app.
8. Call `jest.clearAllMocks()` in `afterEach` (or set `clearMocks: true` in config) to prevent mock leakage.

## Golden Example
```typescript
import { UserService } from "../services/user.service";
import { UserRepository } from "../repositories/user.repository";

describe("UserService", () => {
  let service: UserService;
  let mockRepo: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepo = {
      findById: jest.fn(),
      save: jest.fn(),
    } as unknown as jest.Mocked<UserRepository>;

    service = new UserService(mockRepo);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it("should return a user when found", async () => {
    mockRepo.findById.mockResolvedValue({ id: "1", name: "Alice" });

    const user = await service.getUser("1");

    expect(user).toEqual({ id: "1", name: "Alice" });
    expect(mockRepo.findById).toHaveBeenCalledWith("1");
  });

  it("should throw when user is not found", async () => {
    mockRepo.findById.mockResolvedValue(null);

    await expect(service.getUser("999")).rejects.toThrow("User not found");
  });

  it("should save a new user and return it", async () => {
    const newUser = { id: "2", name: "Bob" };
    mockRepo.save.mockResolvedValue(newUser);

    const result = await service.createUser("Bob");

    expect(result).toEqual(newUser);
    expect(mockRepo.save).toHaveBeenCalledTimes(1);
  });
});
```

## Common LLM Mistakes
- **Tests depending on execution order.** Each `it` block must set up its own state via `beforeEach` or inline setup. Shared mutable state across tests causes flaky failures.
- **Not resetting mocks between tests.** Forgetting `jest.clearAllMocks()` means call counts and return values leak between tests, producing false positives.
- **Testing implementation details.** Asserting on internal method calls or private state instead of observable behavior makes tests brittle to refactors.
- **Missing `await` on async tests.** An `it` block that calls an async function without `await` will pass even if the assertion inside would fail, because Jest never sees the rejected promise.
- **Using `toBe` for object equality.** `toBe` checks reference identity; use `toEqual` for deep structural comparison of objects and arrays.
