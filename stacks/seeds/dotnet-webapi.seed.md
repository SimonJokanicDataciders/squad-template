---
name: "dotnet-webapi"
matches: ["dotnet", ".net", "asp.net", "aspnet", "c#", "csharp", "webapi"]
version: "9.x"
updated: "2026-03-30"
status: "verified"
---

# ASP.NET Core Web API — Seed

## Critical Rules (LLM MUST follow these)
1. Pick ONE pattern per project — Minimal APIs or Controllers — never mix them.
2. Use `record` types for DTOs and request/response models — they are immutable and concise.
3. Mark concrete classes `sealed` unless inheritance is explicitly needed.
4. Return `Results` / `TypedResults` (Minimal API) or `ActionResult<T>` (Controllers) — never return raw objects.
5. Register services via DI in `Program.cs` — never `new` up a service inside a handler or controller.
6. Group Minimal API endpoints with `MapGroup()` or use `[ApiController]` + route grouping for controllers.
7. Use FluentValidation or `IValidatableObject` for input validation — do not validate manually in handlers.

## Golden Example
```csharp
// Features/Products/ProductEndpoints.cs  (Minimal API pattern)
using Microsoft.AspNetCore.Http.HttpResults;

public sealed record CreateProductRequest(string Name, decimal Price);
public sealed record ProductResponse(int Id, string Name, decimal Price);

public static class ProductEndpoints
{
    public static RouteGroupBuilder MapProducts(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/products").WithTags("Products");

        group.MapGet("/", async (IProductService svc) =>
        {
            var products = await svc.ListAllAsync();
            return TypedResults.Ok(products);
        });

        group.MapGet("/{id:int}", async Task<Results<Ok<ProductResponse>, NotFound>> (int id, IProductService svc) =>
        {
            var product = await svc.GetByIdAsync(id);
            return product is not null
                ? TypedResults.Ok(product)
                : TypedResults.NotFound();
        });

        group.MapPost("/", async Task<Created<ProductResponse>> (CreateProductRequest req, IProductService svc) =>
        {
            var product = await svc.CreateAsync(req);
            return TypedResults.Created($"/products/{product.Id}", product);
        });

        return group;
    }
}

// Program.cs (registration)
// builder.Services.AddScoped<IProductService, ProductService>();
// app.MapProducts();
```

## Common LLM Mistakes
- Mixing Minimal API `app.MapGet()` calls and `[ApiController]` controllers in the same project — confuses conventions and routing.
- Using mutable `class` DTOs with public setters — allows accidental mutation; use `record` instead.
- Returning raw objects from handlers instead of `TypedResults` / `Results` — loses OpenAPI metadata and compile-time safety.
- Instantiating services with `new ProductService()` inside handlers — breaks DI, testability, and lifetime management.
- Forgetting `sealed` on concrete classes — leaves them open to unintended inheritance and prevents JIT optimizations.
