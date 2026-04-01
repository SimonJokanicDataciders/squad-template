---
description: Universal testing standards and practices
---

# Testing Rules

## Coverage Requirements

| Area | Minimum Coverage |
|------|-----------------|
| General application code | 80% |
| Authentication and authorization | 100% |
| Payment processing | 100% |
| Security-critical paths | 100% |
| Data validation logic | 100% |
| Utility/helper functions | 90% |

## TDD Cycle

Follow RED-GREEN-REFACTOR strictly for new features and bug fixes:

1. **RED** — Write a failing test that describes the expected behavior
2. **GREEN** — Write the minimum code to make the test pass
3. **REFACTOR** — Clean up the implementation without changing behavior; all tests must still pass

Never skip the RED step. If you cannot write a test first, you do not yet understand the requirement.

## Test Naming

Describe WHAT the system does, not HOW it is implemented.

```
WRONG:
  test("should call repository")
  test("returns true")
  test("test1")
  test("it works")

CORRECT:
  test("creates a new user when valid email is provided")
  test("returns 404 when order does not exist")
  test("rejects password shorter than 8 characters")
  test("applies discount for premium tier customers")
```

## One Behavior Per Test

Each test asserts ONE logical behavior. Multiple assertions are fine only when they verify the same behavior.

```
WRONG:
  test("user operations", () => {
    const user = createUser("alice@test.com");
    expect(user.email).toBe("alice@test.com");    // creation
    user.deactivate();
    expect(user.isActive).toBe(false);            // deactivation — different behavior
    const orders = getOrders(user.id);
    expect(orders).toHaveLength(0);               // order query — different behavior
  });

CORRECT:
  test("creates user with the provided email", () => {
    const user = createUser("alice@test.com");
    expect(user.email).toBe("alice@test.com");
    expect(user.isActive).toBe(true);
  });

  test("deactivated user is marked as inactive", () => {
    const user = createUser("alice@test.com");
    user.deactivate();
    expect(user.isActive).toBe(false);
  });
```

## Fix Implementation, Not Tests

When a test fails after a code change:
- The test describes the correct behavior
- The implementation is what broke
- Fix the implementation to satisfy the test
- Only change the test if the REQUIREMENT changed (and document why)

## Three Test Types

### Unit Tests
- Test a single function, method, or class in isolation
- Mock external dependencies (databases, APIs, file system)
- Execute in milliseconds
- Make up 70-80% of all tests

### Integration Tests
- Test multiple components working together
- Use real databases (via containers) and real file systems
- Verify correct wiring, serialization, and query execution
- Make up 15-25% of all tests

### End-to-End Tests
- Test complete user flows through the running application
- Use browser automation or HTTP clients
- Verify critical business paths only (login, checkout, signup)
- Make up 5-10% of all tests

## Test Data

- Use factories or builders to create test data — never hardcode large object literals repeatedly
- Each test should set up its own data — no shared mutable state between tests
- Use realistic but fake data (Bogus, Faker, factory_boy)
- Never use production data in tests

## Test Structure

Every test follows Arrange-Act-Assert (AAA):

```
test("applies 20% discount for premium users", () => {
  // Arrange
  const user = buildUser({ tier: "premium" });
  const order = buildOrder({ subtotal: 100.00 });

  // Act
  const result = calculateTotal(user, order);

  // Assert
  expect(result.total).toBe(80.00);
  expect(result.discountApplied).toBe(0.20);
});
```

## What NOT to Test

- Framework internals (e.g., does React render a div)
- Third-party library behavior
- Private methods directly — test them through public interfaces
- Trivial getters/setters with no logic
