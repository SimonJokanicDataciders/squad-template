---
paths:
  - "**/*.cs"
  - "**/*.csproj"
description: C# coding conventions and style rules
---

# C# Coding Style

Extends: [common/coding-style.md](../common/coding-style.md)

## Sealed by Default

All classes are `sealed` unless they are explicitly designed for inheritance (`abstract`). This prevents unintended subclassing and enables compiler optimizations.

```csharp
// WRONG
public class UserService
{
    public string GetDisplayName(User user) => $"{user.FirstName} {user.LastName}";
}

// CORRECT
public sealed class UserService
{
    public string GetDisplayName(User user) => $"{user.FirstName} {user.LastName}";
}
```

## Immutable DTOs

Use `sealed record` with `init` properties for all data transfer objects. Never use mutable classes for DTOs.

```csharp
// WRONG — mutable class with setters
public class UserDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
}

// CORRECT — immutable sealed record
public sealed record UserDto
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Email { get; init; }
}
```

## Null Checking

Use pattern matching for null checks. Never use `== null` or `!= null`.

```csharp
// WRONG
if (user == null) throw new ArgumentNullException(nameof(user));
if (user != null) { ... }

// CORRECT
if (user is null) throw new ArgumentNullException(nameof(user));
if (user is not null) { ... }
```

## File-Scoped Namespaces

Always use file-scoped namespaces to reduce indentation.

```csharp
// WRONG
namespace MyApp.Features.Users
{
    public sealed class UserService
    {
        // ...
    }
}

// CORRECT
namespace MyApp.Features.Users;

public sealed class UserService
{
    // ...
}
```

## Pattern Matching and Early Returns

Use pattern matching with `switch` expressions and guard clauses for early returns.

```csharp
// WRONG
public string GetStatusLabel(OrderStatus status)
{
    if (status == OrderStatus.Pending) return "Awaiting payment";
    else if (status == OrderStatus.Shipped) return "On the way";
    else if (status == OrderStatus.Delivered) return "Complete";
    else return "Unknown";
}

// CORRECT
public string GetStatusLabel(OrderStatus status) => status switch
{
    OrderStatus.Pending => "Awaiting payment",
    OrderStatus.Shipped => "On the way",
    OrderStatus.Delivered => "Complete",
    _ => throw new ArgumentOutOfRangeException(nameof(status), status, "Unhandled order status")
};
```

## Async/Await with CancellationToken

Every async method that performs I/O must accept and pass through a `CancellationToken`.

```csharp
// WRONG — no cancellation support
public async Task<User> GetUserAsync(int id)
{
    return await _dbContext.Users.FindAsync(id);
}

// CORRECT — CancellationToken passed through
public async Task<User?> GetUserAsync(int id, CancellationToken cancellationToken = default)
{
    return await _dbContext.Users
        .AsNoTracking()
        .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
}
```

## XML Documentation

All public APIs must have XML doc comments. Include `<param>`, `<returns>`, and `<exception>` tags.

```csharp
/// <summary>
/// Creates a new order for the specified customer.
/// </summary>
/// <param name="request">The order creation request containing line items.</param>
/// <param name="cancellationToken">Cancellation token for the operation.</param>
/// <returns>The created order with a generated ID.</returns>
/// <exception cref="ValidationException">Thrown when the request contains invalid data.</exception>
public async Task<OrderDto> CreateOrderAsync(
    CreateOrderRequest request,
    CancellationToken cancellationToken = default)
{
    // implementation
}
```

## Collection Expressions

Use collection expressions (C# 12+) where applicable.

```csharp
// WRONG
var items = new List<string> { "a", "b", "c" };
var empty = Array.Empty<int>();

// CORRECT
List<string> items = ["a", "b", "c"];
int[] empty = [];
```

## String Handling

Use raw string literals for multi-line strings and string interpolation for simple concatenation.

```csharp
// WRONG
var query = "SELECT *\n" +
            "FROM Users\n" +
            "WHERE Active = 1";

// CORRECT
var query = """
    SELECT *
    FROM Users
    WHERE Active = 1
    """;
```
