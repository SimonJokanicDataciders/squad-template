---
name: "cap-template-role-backend-core"
description: "Core day-to-day conventions for Fenster — load first for every backend task"
domain: "backend"
confidence: "high"
source: "manual"
---

## Context

Use this bundle for ALL backend tasks in CAP.Template. It covers the essential conventions that apply to every implementation task. Load on-demand modules below only when the task requires them.

Primary sources (already embedded below):

- `.github/sdlc-phase-agents/agents/implement.md`
- `.github/sdlc-phase-agents/agents/database.md`
- `.github/sdlc-phase-agents/agents/api-contract.md`
- `.github/agents/senior-dotnet-developer.md`
- `.github/instructions/csharp.instructions.md`

---

## Load on Demand

| Module | When to load |
|--------|-------------|
| `cap-template-role-backend-auth.md` | Task involves authentication, JWT, login, register, or user management |
| `cap-template-role-backend-entities.md` | Task involves creating new entities, FK relationships, or multi-entity features |
| `cap-template-failure-patterns.md` | Any code review or analysis task |

---

## 1. C# Language Conventions

All code must use latest stable C# (currently C# 14).

### Sealed by Default

Every class MUST be `sealed` unless it is an abstract base class explicitly designed for inheritance. If intentionally unsealed, include an XML doc comment explaining the inheritance design intent.

### Immutable Records for DTOs

Use `sealed record` types with positional parameters or `init` properties. Never use mutable classes for DTOs, API models, or configuration objects.

### Read-Only Collections

Use `IReadOnlyList<T>`, `IReadOnlyCollection<T>`, or `ImmutableArray<T>` instead of mutable `List<T>` in public signatures.

### Null Checking

- Always use `is null` / `is not null`. NEVER use `== null` / `!= null`.
- Declare variables non-nullable; check for null at entry points.
- Trust C# null annotations — do not add redundant null checks.

### Formatting and Style

- File-scoped namespace declarations.
- NO newline before opening curly brace (K&R style).
- Use `nameof()` instead of string literals for member names.
- Prefer pattern matching and switch expressions.
- Prefer early returns over deep nesting.
- Apply `.editorconfig` formatting rules.

### XML Documentation

All public APIs MUST have XML doc comments. Include `<example>` and `<code>` blocks when applicable.

### Naming Conventions

- PascalCase for types, methods, public members.
- camelCase for private fields and local variables.
- Prefix interfaces with `I` (e.g., `IUserService`).

---

## 2. Entity Pattern Summary

Entities implement `IAggregateRoot` marker, use `init` properties for immutability, and always include `RowVersion` for optimistic concurrency.

**Rules:**
- Entity is `sealed` with `IAggregateRoot` marker.
- All properties use `init` except business-required mutations.
- `RowVersion` property ALWAYS present for optimistic concurrency.
- FluentAPI configuration in a SEPARATE `IEntityTypeConfiguration<T>` file.
- Reference implementation: `src/Paso.Cap.Domain/WeatherForecasts/`

---

## 3. Service Pattern Summary

Services are `sealed` classes. Do NOT create interfaces for single-implementation services — this is an explicit CAP.Template convention.

- Use static `Expression<Func<TEntity, TDto>> MapDto` properties for compiled query mapping.
- Use `EF.CompileAsyncQuery` for read-heavy operations.
- All write operations MUST use `ExecutionStrategy` for transaction support.
- Catch `DbUpdateConcurrencyException` and wrap as `ConcurrencyException`.
- Register in `DomainServiceExtensions.cs` behind feature flags from `Features.cs`.

---

## 4. Endpoint Pattern Summary

All endpoints extend `EndpointGroupBase` (`src/Paso.Cap.Web/Infrastructure/EndpointGroupBase.cs`). All endpoints are under the `/api` group via `app.MapGroup("/api").MapEndpoints()`.

- Resource names are plural, lowercase (`/api/orders`, NOT `/api/Order`).
- Route parameters use type constraints (`{id:guid}`).
- `.WithDefaultMetadata()` called on ALL endpoints.
- Typed results: `Created` for POST, `NoContent` for PATCH/DELETE.
- `JsonPatchDocument<T>` for partial updates.
- All methods accept `CancellationToken`; services injected via `[FromServices]`.
- Reference implementation: `src/Paso.Cap.Web/Endpoints/WeatherForecast.cs`

---

## 5. EF Core Key Rules

- `ApplicationDbContext` uses `ApplyConfigurationsFromAssembly` for auto-discovering FluentAPI configurations.
- NEVER use method groups or helper methods inside `.Select()` on `IQueryable<T>` — EF Core cannot translate them.
- Inline `new` expressions or static `Expression<Func<TEntity, TDto>>` properties only.
- Dual-DB GUID: `Guid.NewGuid()` for MSSQL, `Guid.CreateVersion7()` for PostgreSQL.
- Migration `Down()` MUST have proper rollback logic — never empty.
- Do NOT edit `ApplicationDbContextModelSnapshot.cs` manually.
- Do NOT use `FromSqlRaw` with string interpolation.

---

## 6. Testing Standards

- **Framework:** xUnit
- **Naming:** `MethodName_Condition_ExpectedResult`
- **No AAA comments** (no `// Arrange`, `// Act`, `// Assert`)
- Copy existing style in nearby test files.

---

## 7. Project Structure and Commands

**Key paths:**
- `src/Paso.Cap.Web/` — API host, endpoints, DI composition
- `src/Paso.Cap.Domain/` — DbContext, entities, services, configurations
- `src/Paso.Cap.Web/Infrastructure/EndpointGroupBase.cs` — Endpoint base class
- `src/Paso.Cap.Web/Endpoints/WeatherForecast.cs` — Reference endpoint
- `src/Paso.Cap.Domain/WeatherForecasts/` — Reference entity, service, DTOs

**Commands:**
```bash
dotnet build                                     # Verify compilation
dotnet test                                      # Run all tests
dotnet test --filter "FullyQualifiedName~TestClass.TestMethod"  # Run specific test
dotnet run --project src/Paso.Cap.Web            # Run API locally
dotnet run --project src/Paso.Cap.AppHost        # Run with Aspire (all services)
./build.cmd Compile                              # NUKE compile
./build.cmd Test                                 # NUKE test
./build.cmd Pack                                 # NUKE pack
```

**Package management:** Central package management via `Directory.Packages.props`.

---

## 8. Artifact Handoff (SDLC Phase Integration)

### Input: What Fenster Requires

Fenster expects a completed plan with `plan.tasks` — a structured list of implementation tasks produced by the planning phase. Each task should specify:
- Which entity/service/endpoint to create or modify
- Expected DTOs and contract shapes
- Database schema changes needed
- Feature flag name

### Output: What Fenster Produces

After implementation, Fenster produces `implementation.summary` containing:
- Files created or modified (with paths)
- New endpoints and their routes
- Database migrations created
- DI registrations added
- Feature flags introduced
- Known test gaps or downstream impacts

---

## 9. Implementation Checklist

Before considering any feature complete, verify:

- [ ] Entity is `sealed` with `IAggregateRoot` marker
- [ ] All properties use `init` (except business-required mutations)
- [ ] `RowVersion` property for optimistic concurrency
- [ ] FluentAPI configuration in separate `IEntityTypeConfiguration<T>` file
- [ ] DTOs are `sealed record` types with `IReadOnlyList<T>` for collections
- [ ] Service is `sealed` class — no interface unless multiple implementations exist
- [ ] Read queries use compiled queries or inline `.Select()` projections
- [ ] Write operations use `ExecutionStrategy` for transaction support
- [ ] `ConcurrencyException` caught from `DbUpdateConcurrencyException`
- [ ] Endpoint uses `EndpointGroupBase` with `.WithDefaultMetadata()`
- [ ] All methods accept `CancellationToken`
- [ ] Feature flag registered in `Features.cs`
- [ ] Service registered in `DomainServiceExtensions.cs` behind feature flag
- [ ] `DbSet<T>` added to `ApplicationDbContext`
- [ ] XML docs on all public API methods
- [ ] Migration `Down()` has proper rollback logic
- [ ] Dual-DB GUID strategy considered
- [ ] No `FromSqlRaw` with string interpolation
- [ ] Snapshot file not manually edited

---

## 10. Boundaries

**Always do:**
- Use `sealed`, `init`, `record`, compiled queries, execution strategies, `CancellationToken`
- Use `is null`/`is not null`, `nameof()`, pattern matching, early returns
- Use file-scoped namespaces
- Write XML docs for all public APIs
- Use `EndpointGroupBase`, typed results, JSON Patch for updates
- Use FluentAPI in separate config files, implement `Down()` rollbacks, test locally first
- Run tests before committing
- Use Conventional Commits: `type(scope): description`

**Ask first:**
- Adding new NuGet packages
- Creating abstract base classes
- Cross-feature service calls
- Breaking API changes
- Adding new HTTP verbs (PUT, HEAD, OPTIONS), query filters, pagination
- Dropping columns/tables, changing PK types, adding indexes on large tables

**Never do:**
- Use `== null` or `!= null` (use `is null`, `is not null`)
- Create interfaces for single-implementation services
- Use method groups in `.Select()` on `IQueryable`
- Skip `RowVersion`
- Use `Task.Result` or `.Wait()` in async code
- Use controllers (this template uses minimal APIs)
- Return raw strings from endpoints
- Skip `.WithDefaultMetadata()`
- Edit the snapshot manually
- Use `FromSqlRaw` with string interpolation
- Leave migration `Down()` empty
- Commit secrets or connection strings

---

## 11. Squad Collaboration

- Route test impact to `Hockney`.
- Route user-visible or setup impact to `Scribe`.
- Route build, deploy, security, or monitoring impact to `Ralph`.

**Common pairings:**
- `Fenster + Hockney` for implementation plus validation
- `Fenster + Dallas` for contract-sensitive UI work
- `Fenster + Ralph` for backend changes that affect build, auth, or deploy behavior

---

## 12. Anti-Patterns

- Do not invent CAP.Template patterns when the WeatherForecasts reference already shows the intended structure.
- Do not add interfaces for services that only have one implementation.
- Do not ship backend changes without explicitly considering test and documentation impact.
- Do not use helper methods or method groups in EF Core `.Select()` projections.
- Do not leave `Down()` migration methods empty.
- Do not skip execution strategies for write operations.
