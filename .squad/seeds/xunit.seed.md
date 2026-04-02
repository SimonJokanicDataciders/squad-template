---
name: "xunit"
matches: ["xunit", "x-unit"]
version: "2.9"
updated: "2026-03-30"
status: "verified"
---

# xUnit — Seed

## Critical Rules (LLM MUST follow these)
1. Use `[Fact]` for single-case tests and `[Theory]` with `[InlineData]` for parameterized tests.
2. Inject shared expensive setup via `IClassFixture<T>` — the fixture is created once per test class.
3. Prefer FluentAssertions (`value.Should().Be(...)`) over raw `Assert.*` for readable, diff-friendly output.
4. Use `WebApplicationFactory<Program>` for integration/API tests against ASP.NET Core endpoints.
5. Use Testcontainers for database tests that need a real engine — avoid in-memory providers for EF Core tests.
6. Constructor injection replaces `[SetUp]`; `IDisposable.Dispose` replaces `[TearDown]` — there are no setup attributes.
7. Keep tests in a project named `<ProjectUnderTest>.Tests` and mirror the source folder structure.
8. Never use `[Collection]` unless tests truly share an expensive resource — it serializes execution.

## Golden Example
```csharp
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net;
using System.Net.Http.Json;
using Xunit;

public class DatabaseFixture : IDisposable
{
    public string ConnectionString { get; }

    public DatabaseFixture()
    {
        ConnectionString = "Host=localhost;Database=test_db;";
        // Seed database or start container here
    }

    public void Dispose()
    {
        // Cleanup database
    }
}

public class OrderServiceTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _db;

    public OrderServiceTests(DatabaseFixture db)
    {
        _db = db;
    }

    [Fact]
    public void CreateOrder_WithValidItems_ReturnsOrder()
    {
        var service = new OrderService(_db.ConnectionString);

        var order = service.CreateOrder("customer-1", new[] { "item-a", "item-b" });

        order.Should().NotBeNull();
        order.Items.Should().HaveCount(2);
        order.CustomerId.Should().Be("customer-1");
    }

    [Theory]
    [InlineData(0, false)]
    [InlineData(1, true)]
    [InlineData(100, true)]
    public void CreateOrder_ItemCountDeterminesValidity(int itemCount, bool shouldSucceed)
    {
        var service = new OrderService(_db.ConnectionString);
        var items = Enumerable.Range(0, itemCount).Select(i => $"item-{i}").ToArray();

        var act = () => service.CreateOrder("customer-1", items);

        if (shouldSucceed)
            act.Should().NotThrow();
        else
            act.Should().Throw<ArgumentException>();
    }
}

public class OrderApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public OrderApiTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetOrder_ReturnsOk()
    {
        var response = await _client.GetAsync("/api/orders/1");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var order = await response.Content.ReadFromJsonAsync<OrderDto>();
        order!.Id.Should().Be(1);
    }
}
```

## Common LLM Mistakes
- **Using MSTest or NUnit attributes.** Generating `[TestMethod]`, `[Test]`, or `[SetUp]` in an xUnit project causes compilation errors. xUnit uses `[Fact]`, `[Theory]`, and constructor injection.
- **Not disposing fixtures.** Forgetting `IDisposable` on class fixtures leaks database connections, containers, or file handles across the test run.
- **Manual object creation instead of fixtures.** Rebuilding expensive dependencies (DB contexts, HTTP clients) inside every test method instead of using `IClassFixture` wastes time and risks inconsistency.
- **Using `Assert.Equal` for everything.** Raw xUnit asserts produce poor error messages for collections and complex objects. FluentAssertions gives structured diffs.
- **Using `EF InMemory` provider for integration tests.** The in-memory provider ignores constraints and SQL behavior. Use Testcontainers with the real database engine.
