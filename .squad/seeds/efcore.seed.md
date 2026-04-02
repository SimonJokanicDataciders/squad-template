---
name: "efcore"
matches: ["ef core", "efcore", "entity framework", "entityframework", "ef"]
version: "10.x"
updated: "2026-03-30"
status: "verified"
---

# Entity Framework Core 10 — Seed

## Critical Rules (LLM MUST follow these)
1. Place every entity configuration in its own `IEntityTypeConfiguration<T>` file — never inline Fluent API calls in `OnModelCreating`.
2. Use compiled queries via `EF.CompileAsyncQuery` for all hot-path reads — never rely on ad-hoc LINQ for performance-critical queries.
3. Wrap all write operations in an `ExecutionStrategy` — never call `SaveChangesAsync` outside a resilient execution block.
4. Use `init` properties on entities — never expose public setters that allow uncontrolled mutation.
5. Add a `RowVersion` (`[Timestamp]`) property to every aggregate root for optimistic concurrency — never rely on last-write-wins.
6. NEVER manually edit files under `Migrations/` or the `ModelSnapshot` — always use `dotnet ef migrations add` to generate them.
7. Every new entity property MUST have a corresponding migration — never deploy schema changes without a migration.

## Golden Example
```csharp
// Domain/Entities/Product.cs
public interface IAggregateRoot { }

public class Product : IAggregateRoot
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public decimal Price { get; init; }
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;

    [Timestamp]
    public byte[] RowVersion { get; init; } = null!;
}

// Infrastructure/Configurations/ProductConfiguration.cs
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products");
        builder.HasKey(p => p.Id);
        builder.Property(p => p.Name).HasMaxLength(200).IsRequired();
        builder.Property(p => p.Price).HasPrecision(18, 2);
        builder.Property(p => p.RowVersion).IsRowVersion();
    }
}

// Infrastructure/AppDbContext.cs
using Microsoft.EntityFrameworkCore;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Product> Products => Set<Product>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}

// Infrastructure/Queries/ProductQueries.cs
using Microsoft.EntityFrameworkCore;

public static class ProductQueries
{
    public static readonly Func<AppDbContext, Guid, Task<Product?>> GetById =
        EF.CompileAsyncQuery(
            (AppDbContext db, Guid id) =>
                db.Products.AsNoTracking().FirstOrDefault(p => p.Id == id));

    public static readonly Func<AppDbContext, IAsyncEnumerable<Product>> GetAll =
        EF.CompileAsyncQuery(
            (AppDbContext db) =>
                db.Products.AsNoTracking().OrderBy(p => p.Name));
}

// Infrastructure/Services/ProductService.cs
using Microsoft.EntityFrameworkCore;

public class ProductService
{
    private readonly AppDbContext _db;
    private readonly IExecutionStrategy _strategy;

    public ProductService(AppDbContext db)
    {
        _db = db;
        _strategy = db.Database.CreateExecutionStrategy();
    }

    public async Task<Product> CreateAsync(string name, decimal price)
    {
        return await _strategy.ExecuteAsync(async () =>
        {
            var product = new Product
            {
                Id = Guid.NewGuid(),
                Name = name,
                Price = price,
            };

            _db.Products.Add(product);
            await _db.SaveChangesAsync();
            return product;
        });
    }
}
```

## Common LLM Mistakes
- Manually editing migration files or the `ModelSnapshot` — causes schema drift and broken migrations on other environments.
- Adding new entity properties without running `dotnet ef migrations add` — the database schema silently falls out of sync.
- Calling `SaveChangesAsync` without wrapping in an `ExecutionStrategy` — transient database failures crash the application instead of retrying.
- Relying on lazy loading without explicit `.Include()` — triggers N+1 queries and unpredictable performance.
- Using mutable `set` properties on entities instead of `init` — allows uncontrolled state changes that bypass domain invariants.
