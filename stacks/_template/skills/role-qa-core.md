---
name: "role-qa-core"
description: "Core QA/testing conventions — load first for every testing task"
domain: "testing"
confidence: "medium"
source: "manual"
---

# QA / Tester — Core Skill Bundle

## Test Project Structure

<!-- Replace with YOUR project's actual test layout. Example: -->
```
tests/
├── unit/                    # Fast, isolated tests (mocked dependencies)
│   ├── {Feature}Tests.cs    # One file per service/component
│   └── Generators/          # Test data generators (Bogus/Faker)
├── integration/             # Real database/API tests
│   ├── {Feature}ApiTests.cs # Full API workflow tests
│   ├── ApplicationFactory.cs  # WebApplicationFactory setup
│   └── DatabaseFactory.cs   # Testcontainer setup
└── e2e/                     # Browser tests (Playwright/Cypress)
    └── {feature}.spec.ts
```

## Testing Frameworks

<!-- Replace with YOUR actual frameworks and versions. Example: -->
| Framework | Version | Purpose |
|-----------|---------|---------|
| xUnit / Vitest / pytest | latest | Unit + integration test runner |
| Bogus / Faker | latest | Fake data generation |
| Testcontainers | latest | Database integration tests with real DB |
| Playwright | latest | End-to-end browser testing |

## Unit Test Conventions

<!-- Replace with YOUR unit test patterns. Example: -->

**Naming:** `MethodName_Condition_ExpectedResult`
```
// Example: GetById_WithValidId_ReturnsItem
// Example: Create_WithMissingTitle_ThrowsValidationException
```

**Structure:**
- One assertion focus per test — test one behavior at a time
- No AAA comments (Arrange/Act/Assert) — the code should be self-evident
- Use test data generators for realistic data, not magic strings
- Test both happy paths AND error/edge cases

**What to test:**
- Service methods: CRUD operations, validation, edge cases
- Error handling: missing resources, invalid input, authorization failures
- Business rules: domain logic, state transitions, calculations

## Integration Test Conventions

<!-- Replace with YOUR integration test patterns. Example: -->

**Naming:** `{Feature}_{Action}_{ExpectedResult}`
```
// Example: TaskItems_CreateAndRetrieve_ReturnsCreatedItem
// Example: TaskItems_DeleteNonExistent_Returns404
```

**Structure:**
- Use a real database (Testcontainers) — no mocking the data layer
- Test full API workflows: create → list → get by ID → update → delete
- Verify HTTP status codes, response bodies, and side effects
- Clean up test data after each test (fresh database per test class)

## Code Review Checklist

When reviewing implementation work, check:

### Correctness
- [ ] Code does what the task description asked for
- [ ] Edge cases handled (null, empty, not found, duplicate)
- [ ] Error responses use correct HTTP status codes
- [ ] No off-by-one errors in pagination/filtering

### Conventions
- [ ] Follows project naming conventions (files, classes, methods)
- [ ] Follows project structure conventions (file placement)
- [ ] Follows project code style (formatting, immutability, access modifiers)
- [ ] New dependencies justified and version-pinned

### Security
- [ ] No hardcoded secrets or credentials
- [ ] User input validated and sanitized
- [ ] No SQL injection or XSS vulnerabilities
- [ ] Auth/authorization properly enforced

### Testing
- [ ] New features have unit tests
- [ ] Integration tests cover the API workflow
- [ ] Tests actually assert meaningful behavior (not just "it doesn't crash")
- [ ] Test naming follows project conventions

### Documentation
- [ ] Public APIs documented (XML docs, JSDoc, docstrings)
- [ ] Breaking changes noted
- [ ] README updated if setup changed

## QA Checklist (Pre-Handoff)

- [ ] All existing tests still pass (no regressions)
- [ ] New tests pass
- [ ] Coverage meets project threshold
- [ ] Build compiles with zero errors
- [ ] Lint passes with zero warnings
- [ ] No `any` types introduced (TypeScript projects)
