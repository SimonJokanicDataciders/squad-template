---
name: "cap-template-role-qa-core"
description: "Core lint, test structure, review, and quality gate rules for Hockney — always loaded"
domain: "testing"
confidence: "high"
source: "manual"
---

## Context

Use this bundle when `Hockney` is validating changes through linting, unit tests, integration tests, or review.

Primary sources:
- `.github/sdlc-phase-agents/agents/lint.md`
- `.github/sdlc-phase-agents/agents/test.md`
- `.github/sdlc-phase-agents/agents/integration-test.md`
- `.github/sdlc-phase-agents/agents/review.md`
- `.github/agents/qa-engineer.md`
- `.github/instructions/csharp.instructions.md`
- `.github/universal-sdlc-agents/CEREMONIES.md`

## Load on Demand

| Module | When to load |
|--------|-------------|
| `cap-template-role-qa-auth-tests.md` | Task involves authenticated endpoints or concurrency testing |
| `cap-template-role-qa-angular-tests.md` | Task involves writing or reviewing Angular component tests |
| `cap-template-failure-patterns.md` | Any code review or analysis task |

## Artifact Protocol

| Phase | Input | Output |
|-------|-------|--------|
| Lint | `implementation.summary` (changed files + intent) | `lint.report` (pass/fail, violations list) |
| Unit Test | `implementation.summary` | `test.report` (pass/fail, coverage, failures) |
| Integration Test | `implementation.summary` | `integration-test.report` (pass/fail, endpoints tested, Docker status) |
| Review | `implementation.summary` + all prior reports | `review.verdict` (approve / request-changes, findings list) |

---

## Phase 1: Lint & Code Quality

### C# Mandatory Lint Rules

Source of truth: `.editorconfig` + `.github/instructions/csharp.instructions.md`

| Rule | Check | Fix |
|------|-------|-----|
| All classes `sealed` | No `public class` without `sealed`/`abstract` | Add `sealed` keyword |
| Immutable DTOs | DTOs must be `record` with `init` properties | Convert `class` to `record`, `set` to `init` |
| Null checks | Use `is null`/`is not null` | Replace `== null`/`!= null` |
| XML docs | All public APIs documented | Add `/// <summary>` |
| File-scoped namespaces | `namespace Foo;` not `namespace Foo { }` | Convert to file-scoped |
| No brace newline | `if (...) {` not `if (...)\n{` | Remove newline before `{` |
| Explicit types | `int x = 5` not `var x = 5` for built-in types | Replace `var` with explicit type |
| Early returns | No deep nesting | Refactor to guard clauses |
| Pattern matching | Use `switch` expressions | Replace `if-else` chains |
| `nameof()` | No string literals for member names | Use `nameof(property)` |
| Read-only collections | `IReadOnlyList<T>` not `List<T>` in DTOs | Change collection types |
| EF Core projections | Inline `new` in `.Select()` | No method groups or helpers |
| Test naming | `MethodName_Condition_ExpectedResult` | Rename tests |
| No AAA comments | No `// Arrange`, `// Act`, `// Assert` | Remove comments |

### Angular Mandatory Lint Rules

| Rule | Check |
|------|-------|
| Standalone components | No module-based components |
| OnPush change detection | `ChangeDetectionStrategy.OnPush` on all components |
| `inject()` function | Not constructor injection |
| No `any` type | Proper TypeScript types everywhere |
| No `innerHTML` with user input | XSS prevention |
| Lazy-loaded routes | `loadChildren`/`loadComponent` in routes |
| Nx project boundaries | No circular imports between libs |

### Lint Commands

```bash
# C# formatting
dotnet format                           # Auto-fix
dotnet format --verify-no-changes       # CI/check mode
dotnet format --severity info           # With severity

# Angular
cd src/Paso.Cap.Angular
npx nx lint                             # ESLint
npx nx format:check                     # Prettier check
npx nx format:write                     # Prettier fix
```

### Lint Boundaries

- ALWAYS run `dotnet format` and `nx lint` before committing.
- ALWAYS fix all issues before moving to the Test phase.
- ASK FIRST before changing `.editorconfig` rules or adding new Roslyn analyzers.
- NEVER disable lint rules with `#pragma warning disable` or commit with format violations.

---

## Phase 2: Unit Testing

### Test Project Structure

```
tests/
├── Paso.Cap.UnitTests/               -> Fast, isolated, mock dependencies
│   └── {Feature}/
│       └── {Service}Tests.cs
└── Paso.Cap.IntegrationTests/         -> Real database via Testcontainers
    ├── ApplicationFactory.cs          -> Custom WebApplicationFactory
    ├── DatabaseFactory.cs             -> Testcontainers DB setup
    └── {Feature}/
        └── {Feature}ApiTests.cs
```

### Frameworks

| Package | Version | Purpose |
|---------|---------|---------|
| xunit.v3 | 3.2.2 | Test framework |
| Bogus | 35.6.5 | Fake data generation |
| Testcontainers | 4.11.0 | Dockerized SQL Server / PostgreSQL |
| Microsoft.AspNetCore.TestHost | — | In-memory HTTP testing |
| coverlet.collector | 8.0.1 | Code coverage |

### Unit Test Naming Convention

Pattern: `MethodName_Condition_ExpectedResult`

```csharp
public void GetById_ItemExists_ReturnsItem() { }
public void Create_InvalidTemperature_ThrowsArgumentException(int temperature) { }
```

### Unit Test Commands

```bash
dotnet test                                                 # All tests
dotnet test tests/Paso.Cap.UnitTests                        # Unit tests only
dotnet test --filter "FullyQualifiedName~OrderServiceTests" # Specific class
dotnet test --collect:"XPlat Code Coverage"                 # With coverage
```

### Unit Test Checklist

- [ ] Unit tests cover all service methods
- [ ] Test names follow `MethodName_Condition_ExpectedResult`
- [ ] No `// Arrange / Act / Assert` comments
- [ ] Bogus used for test data generation (not hardcoded values)
- [ ] `using` or `IAsyncDisposable` for all disposable resources
- [ ] All tests pass: `dotnet test` exits with code 0
- [ ] Test classes are `sealed`

---

## Phase 3: Integration Testing

### Integration Test Project Structure

```
tests/Paso.Cap.IntegrationTests/
├── ApplicationFactory.cs          -> Custom WebApplicationFactory
├── DatabaseFactory.cs             -> Testcontainers DB setup (SQL Server or PostgreSQL)
└── {Feature}/
    └── {Feature}ApiTests.cs       -> IAsyncLifetime test classes
```

Frameworks: xunit.v3 3.2.2, Testcontainers 4.11.0, Bogus 35.6.5, Microsoft.AspNetCore.TestHost

### Integration Test Commands

```bash
dotnet test tests/Paso.Cap.IntegrationTests                                       # All integration tests
dotnet test tests/Paso.Cap.IntegrationTests --filter "FullyQualifiedName~ApiTests" # Specific class
dotnet test tests/Paso.Cap.IntegrationTests -v detailed                            # Verbose (container logs)
```

### Integration Test Boundaries

- ALWAYS use `IAsyncLifetime`, one `ApplicationFactory` per test class, validate status codes AND response bodies.
- ASK FIRST before sharing database state between tests or using custom Testcontainers images.
- NEVER depend on test execution order, use real production databases, or skip `DisposeAsync`.
- If Docker/Testcontainers is unavailable, report a REAL BLOCKER — do not treat integration tests as passed.

---

## Phase 4: Code Review

### PR Review Checklist

#### 1. Conventional Commits
- [ ] PR title follows `type(scope): description`
- [ ] Valid types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `style`, `ci`
- [ ] Scope is meaningful (e.g., `feat(orders): add order creation endpoint`)

#### 2. C# Code Quality
- [ ] All new classes are `sealed` (unless abstract with documented reason)
- [ ] DTOs are immutable `record` types with `init`/`required` properties
- [ ] Collections are `IReadOnlyList<T>` or `IReadOnlyCollection<T>`
- [ ] Null checks use `is null` / `is not null` (not `== null`)
- [ ] XML docs on all public APIs with `<summary>`
- [ ] File-scoped namespaces
- [ ] No newline before opening brace
- [ ] Early returns instead of deep nesting
- [ ] `nameof()` instead of string literals for member names
- [ ] Pattern matching and switch expressions where applicable

#### 3. EF Core & Database
- [ ] `.Select()` projections use inline `new` (not method groups)
- [ ] Read-only queries use `AsNoTracking()` or compiled queries
- [ ] Write operations use `ExecutionStrategy` for transaction safety
- [ ] `RowVersion` on all aggregate roots
- [ ] Migration `Down()` has proper rollback logic (not empty)
- [ ] No `FromSqlRaw` with string interpolation (SQL injection risk)
- [ ] Dual-DB considered (MSSQL + PostgreSQL GUID strategy)

#### 4. API Design
- [ ] Endpoints use `EndpointGroupBase` pattern
- [ ] `.WithDefaultMetadata()` on all route mappings
- [ ] Proper HTTP status codes (201 Created, 204 NoContent, etc.)
- [ ] `CancellationToken` on all async methods
- [ ] Services injected via `[FromServices]`
- [ ] JSON Patch used for partial updates

#### 5. Security
- [ ] No hardcoded secrets, connection strings, or API keys
- [ ] No `bypassSecurityTrust*` in Angular
- [ ] No `innerHTML` with user input
- [ ] Exception handling does not leak internal details
- [ ] `[Authorize]` on protected endpoints (if auth is configured)
- [ ] CORS not set to `AllowAnyOrigin` with credentials

#### 6. Performance
- [ ] No N+1 queries (check for `.Include()` or compiled queries)
- [ ] No `Task.Result`, `.Wait()`, or `.GetAwaiter().GetResult()` in async context
- [ ] No blocking calls on hot paths
- [ ] Compiled queries for frequently-called read operations
- [ ] `AsNoTracking()` for read-only queries

#### 7. Testing
- [ ] New logic has unit tests
- [ ] Test names: `MethodName_Condition_ExpectedResult`
- [ ] No AAA comments
- [ ] Integration tests for new endpoints (with Testcontainers)
- [ ] `IDisposable` resources properly disposed in tests

#### 8. Angular (if frontend changes)
- [ ] Standalone components with `OnPush`
- [ ] `inject()` for DI (not constructor)
- [ ] Signals or async pipe for reactive data
- [ ] Lazy-loaded routes
- [ ] No `any` types
- [ ] Nx project boundaries respected

#### 9. Infrastructure
- [ ] `Directory.Packages.props` used for NuGet versions (not in .csproj)
- [ ] Feature flag added to `Features.cs`
- [ ] Service registered in `DomainServiceExtensions.cs`
- [ ] Conditional compilation guards maintained for dual-DB/UI variants

### Review Decision Matrix

| Finding | Action |
|---------|--------|
| Sealed class missing | **Block** — must fix |
| Mutable DTO | **Block** — convert to record |
| Missing XML docs | **Block** — add docs |
| Missing tests | **Block** — add tests |
| Empty migration `Down()` | **Block** — add rollback |
| Performance suggestion | **Comment** — non-blocking |
| Style nit (formatting) | **Skip** — let `dotnet format` handle it |

### Review Ceremony Triggers

Trigger a formal review ceremony when ANY of these thresholds are met:

| Trigger | Threshold |
|---------|-----------|
| File count | 10+ files changed |
| Line count | 400+ lines changed (additions + deletions) |
| Security-sensitive paths | Any change touching auth, CORS, secrets, `[Authorize]`, connection strings |
| Database migrations | Any new migration file |
| Infrastructure changes | CI/CD pipelines, Dockerfile, deployment configs |
| New external dependency | New NuGet package or npm package |

When a ceremony is triggered, the review must:
1. Produce a structured `review.verdict` artifact.
2. List every finding with severity (blocker / warning / info).
3. Explicitly state merge readiness: approve or request-changes.

### Reviewer Lockout Protocol

1. **First rejection:** Reviewer identifies blocking issues. The original implementing agent fixes them.
2. **Second rejection:** If the fix is also rejected, a different agent must handle the revision. The original implementer is locked out.
3. **Cascading lockout:** If the second agent's revision is also rejected, escalate to another agent or to the human.
4. **Full lockout:** If all relevant agents have been locked out (maximum 3 rounds), escalate to a human reviewer with full context.

The lockout is per-finding, not per-PR. Log each lockout event as a decision.

---

## Pre-Commit Validation Sequence

Run these checks in order before every commit:

```bash
# 1. C# formatting
dotnet format --verify-no-changes

# 2. C# build
dotnet build --no-restore

# 3. C# unit tests
dotnet test tests/Paso.Cap.UnitTests --no-build

# 4. C# integration tests (requires Docker)
dotnet test tests/Paso.Cap.IntegrationTests --no-build

# 5. Angular lint + format
cd src/Paso.Cap.Angular && npx nx lint && npx nx format:check

# 6. Angular build
cd src/Paso.Cap.Angular && npx nx build

# 7. Angular tests
cd src/Paso.Cap.Angular && npx nx test
```

---

## Patterns

- Validate the smallest safe scope first, then broaden: static checks -> unit tests -> integration tests -> review gate.
- Follow CAP.Template testing conventions exactly as documented above.
- Report clear evidence: files reviewed, commands run, exact blockers.
- If integration tests depend on unavailable local prerequisites such as Docker/Testcontainers, report a real blocker instead of treating the tests as passed.
- Trigger or recommend PR review ceremony when change size or sensitivity crosses the ceremony thresholds.

## Anti-Patterns

- Do not claim confidence without evidence.
- Do not hide blocked integration coverage behind generic wording.
- Do not collapse review findings into style-only noise when there are real risks to surface.
- Do not approve without checking sealed/immutable/XML docs rules.
- Do not nitpick formatting that `dotnet format` would handle automatically.

## Examples

- Good fit: unit and integration test strategy, gap analysis for changed code, review findings with severity, evidence-driven merge readiness
- Common pairings: `Hockney + Fenster` for implementation plus validation; `Hockney + Ralph` for release or security-sensitive review
