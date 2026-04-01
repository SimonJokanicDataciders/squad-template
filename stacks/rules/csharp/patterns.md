---
paths:
  - "**/*.cs"
  - "**/*.csproj"
description: C# architectural patterns and conventions
---

# C# Patterns

## EndpointGroupBase Pattern

Use the `EndpointGroupBase` pattern for minimal API endpoints. Each feature gets its own endpoint group.

```csharp
// src/Features/Orders/OrderEndpoints.cs
namespace MyApp.Features.Orders;

public sealed class OrderEndpoints : EndpointGroupBase
{
    public override void Map(WebApplication app)
    {
        var group = app.MapGroup("/api/orders")
            .WithTags("Orders")
            .RequireAuthorization();

        group.MapGet("/", GetAll);
        group.MapGet("/{id:int}", GetById);
        group.MapPost("/", Create);
        group.MapPut("/{id:int}", Update);
        group.MapDelete("/{id:int}", Delete);
    }

    private static async Task<IResult> GetAll(
        IOrderRepository repository,
        CancellationToken cancellationToken)
    {
        var orders = await repository.GetAllAsync(cancellationToken);
        return TypedResults.Ok(ApiResponse<IReadOnlyList<OrderDto>>.Success(orders));
    }

    private static async Task<IResult> GetById(
        int id,
        IOrderRepository repository,
        CancellationToken cancellationToken)
    {
        var order = await repository.GetByIdAsync(id, cancellationToken);
        if (order is null)
        {
            return TypedResults.NotFound(ApiResponse<OrderDto>.Fail("Order not found"));
        }
        return TypedResults.Ok(ApiResponse<OrderDto>.Success(order));
    }

    private static async Task<IResult> Create(
        CreateOrderRequest request,
        IValidator<CreateOrderRequest> validator,
        IOrderRepository repository,
        CancellationToken cancellationToken)
    {
        var validation = await validator.ValidateAsync(request, cancellationToken);
        if (!validation.IsValid)
        {
            return TypedResults.BadRequest(
                ApiResponse<OrderDto>.Fail(validation.Errors.Select(e => e.ErrorMessage)));
        }

        var order = await repository.CreateAsync(request.ToOrder(), cancellationToken);
        return TypedResults.Created($"/api/orders/{order.Id}", ApiResponse<OrderDto>.Success(order.ToDto()));
    }
}
```

## Generic ApiResponse

Use a single consistent response wrapper for all API responses.

```csharp
// src/Common/ApiResponse.cs
namespace MyApp.Common;

public sealed record ApiResponse<T>
{
    public required bool IsSuccess { get; init; }
    public T? Data { get; init; }
    public IReadOnlyList<string> Errors { get; init; } = [];

    public static ApiResponse<T> Success(T data) => new()
    {
        IsSuccess = true,
        Data = data
    };

    public static ApiResponse<T> Fail(string error) => new()
    {
        IsSuccess = false,
        Errors = [error]
    };

    public static ApiResponse<T> Fail(IEnumerable<string> errors) => new()
    {
        IsSuccess = false,
        Errors = errors.ToList()
    };
}
```

## Generic Repository Interface

```csharp
// src/Common/IRepository.cs
namespace MyApp.Common;

public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<T>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<T> CreateAsync(T entity, CancellationToken cancellationToken = default);
    Task<T> UpdateAsync(T entity, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
```

## Options Pattern for Configuration

Bind configuration sections to strongly typed objects using `IOptions<T>`.

```csharp
// src/Common/Options/EmailOptions.cs
namespace MyApp.Common.Options;

public sealed class EmailOptions
{
    public const string SectionName = "Email";

    public required string SmtpHost { get; init; }
    public required int SmtpPort { get; init; }
    public required string FromAddress { get; init; }
    public bool UseSsl { get; init; } = true;
}

// Registration in Program.cs
builder.Services.Configure<EmailOptions>(
    builder.Configuration.GetSection(EmailOptions.SectionName));

// Usage in a service
public sealed class EmailService(IOptions<EmailOptions> options)
{
    private readonly EmailOptions _options = options.Value;

    public async Task SendAsync(string to, string subject, string body)
    {
        using var client = new SmtpClient(_options.SmtpHost, _options.SmtpPort);
        // ...
    }
}
```

## Dependency Injection Lifetimes

| Lifetime | Use For | Examples |
|----------|---------|----------|
| **Singleton** | Stateless services, caches, configuration | `HttpClient` factory, `IMemoryCache`, options monitors |
| **Scoped** | Per-request state, database contexts | `DbContext`, `IRepository<T>`, unit of work |
| **Transient** | Lightweight, stateless, short-lived | Validators, mappers, command handlers |

```csharp
// Program.cs — DI registration
builder.Services.AddSingleton<ICacheService, RedisCacheService>();
builder.Services.AddScoped<AppDbContext>();
builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddTransient<IValidator<CreateOrderRequest>, CreateOrderValidator>();
```

## FluentValidation Pattern

```csharp
// src/Features/Orders/CreateOrderValidator.cs
namespace MyApp.Features.Orders;

public sealed class CreateOrderValidator : AbstractValidator<CreateOrderRequest>
{
    public CreateOrderValidator()
    {
        RuleFor(x => x.CustomerId)
            .GreaterThan(0)
            .WithMessage("Customer ID must be a positive integer");

        RuleFor(x => x.Items)
            .NotEmpty()
            .WithMessage("Order must contain at least one item");

        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.ProductId).GreaterThan(0);
            item.RuleFor(i => i.Quantity).InclusiveBetween(1, 1000);
            item.RuleFor(i => i.UnitPrice).GreaterThan(0);
        });
    }
}
```
