---
description: 'Guidelines for building C# applications'
applyTo: '**/*.cs'
---

# C# Development

## C# Instructions
- Always use the latest version C#, currently C# 14 features.
- Write clear and concise comments for each function.

## General Instructions
- Make only high confidence suggestions when reviewing code changes.
- Write code with good maintainability practices, including comments on why certain design decisions were made.
- Handle edge cases and write clear exception handling.
- For libraries or external dependencies, mention their usage and purpose in comments.

## Naming Conventions

- Follow PascalCase for component names, method names, and public members.
- Use camelCase for private fields and local variables.
- Prefix interface names with "I" (e.g., IUserService).

## Formatting

- Apply code-formatting style defined in `.editorconfig`.
- Prefer file-scoped namespace declarations and single-line using directives.
- DO NOT Insert a newline before the opening curly brace of any code block (e.g., after `if`, `for`, `while`, `foreach`, `using`, `try`, etc.).
- Ensure that the final return statement of a method is on its own line.
- Use pattern matching and switch expressions wherever possible.
- Use `nameof` instead of string literals when referring to member names.
- Prefer early returns instead of deep nesting to improve readability and reduce complexity.
- Ensure that XML doc comments are created for any public APIs. When applicable, include `<example>` and `<code>` documentation in the comments.
- **All classes must be sealed** unless explicitly designed for inheritance (base classes or abstract classes). When intentionally unsealed, include XML doc comment explaining the inheritance design intent.
- **Prefer immutable records** to mutable classes for data containers (DTOs, API models, configuration objects). Use `record` types with `init` properties or positional parameters.
- **Use read-only collections** (`IReadOnlyList<T>`, `IReadOnlyCollection<T>`, `ImmutableArray<T>`) instead of mutable collections for true immutability.

## Project Setup and Structure

- Guide users through creating a new .NET project with the appropriate templates.
- Explain the purpose of each generated file and folder to build understanding of the project structure.
- Demonstrate how to organize code using feature folders or domain-driven design principles.
- Show proper separation of concerns with models, services, and data access layers.
- Explain the Program.cs and configuration system in ASP.NET Core including environment-specific settings.

## Nullable Reference Types

- Declare variables non-nullable, and check for `null` at entry points.
- Always use `is null` or `is not null` instead of `== null` or `!= null`.
- Trust the C# null annotations and don't add null checks when the type system says a value cannot be null.

## Data Access Patterns

- Guide the implementation of a data access layer using Entity Framework Core.
- Explain different options (PostgreSQL for production, Testcontainers for integration tests).
- Demonstrate repository pattern implementation and when it's beneficial.
- Show how to implement database migrations and data seeding.
- Explain efficient query patterns to avoid common performance issues.

## Entity Framework Core Query Projections

**CRITICAL**: Never use method groups or helper methods inside `.Select()` on EF Core `IQueryable<T>`.

```csharp
// ❌ Bad - EF Core cannot translate ToDto() into SQL
var results = await _dbContext.Items
    .Where(x => x.ProjectId == projectId)
    .Select(x => ToDto(x))
    .ToListAsync(cancellationToken);

// ✅ Good - Inline new-expression is fully translatable to SQL
var results = await _dbContext.Items
    .Where(x => x.ProjectId == projectId)
    .Select(x => new ItemDto(x.Id, x.Name, x.CreatedAt))
    .ToListAsync(cancellationToken);
```

## Authentication and Authorization

- Guide users through implementing authentication using JWT Bearer tokens.
- Explain OAuth 2.0 and OpenID Connect concepts as they relate to ASP.NET Core.
- Show how to implement role-based and policy-based authorization.
- Demonstrate integration with Microsoft Entra ID (formerly Azure AD).

## Validation and Error Handling

- Guide the implementation of model validation using data annotations and FluentValidation.
- Demonstrate a global exception handling strategy using middleware.
- Show how to create consistent error responses across the API.
- Explain problem details (RFC 7807) implementation for standardized error responses.

## Testing

- Always include test cases for critical paths of the application.
- Guide users through creating unit tests.
- Do not emit "Act", "Arrange" or "Assert" comments.
- Copy existing style in nearby files for test method names and capitalization.
- Follow the `MethodName_Condition_ExpectedResult()` test naming pattern.
- Demonstrate how to mock dependencies for effective testing.

## Sealed Classes and Inheritance

**Rule**: All classes must be `sealed` unless explicitly designed for inheritance.

```csharp
// ✅ Good - Sealed by default
public sealed class OrderService : IOrderService {
    // Implementation
}

// ✅ Good - Abstract class for inheritance
/// <summary>
/// Base class for all handlers.
/// Designed for inheritance - override Process() in derived classes.
/// </summary>
public abstract class BaseHandler {
    public abstract Task Process();
}

// ❌ Bad - Unsealed without reason
public class OrderService {  // Should be sealed!
    // Implementation
}
```

## Immutability and Records

```csharp
// ✅ Good - Immutable record with read-only collection
public sealed record UserDto(
    Guid Id,
    string Name,
    IReadOnlyList<string> Roles
);

// ✅ Good - Immutable record with init properties
public sealed record OrderDto {
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required IReadOnlyList<OrderLineDto> Lines { get; init; }
}

// ❌ Bad - Mutable class
public class UserDto {
    public Guid Id { get; set; }
    public List<string> Roles { get; set; }
}
```

## CRITICAL REMINDERS

**YOU MUST ALWAYS:**

* Provide a brief rationale or self-check summary before implementing changes to confirm alignment with these guidelines.
* Explicitly validate against these guidelines.
* Follow the `MethodName_Condition_ExpectedResult()` test naming pattern.
* Stop and ask for clarification if any guideline is unclear.

Rigorous adherence to these guidelines and code standards is expected.
