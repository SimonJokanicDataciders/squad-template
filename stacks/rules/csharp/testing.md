---
paths:
  - "**/*.cs"
  - "**/*.csproj"
description: C# testing conventions with xUnit, Bogus, and Testcontainers
---

# C# Testing

Extends: [common/testing.md](../common/testing.md)

## Test Stack

| Tool | Purpose |
|------|---------|
| **xUnit** | Test framework |
| **Bogus** | Fake data generation |
| **FluentAssertions** | Readable assertion syntax |
| **NSubstitute** | Mocking |
| **Testcontainers** | Real database for integration tests |
| **WebApplicationFactory** | In-memory API host for integration tests |

## Project Structure

Mirror the `src/` structure under `tests/`:

```
src/
  MyApp/
    Features/
      Orders/
        OrderEndpoints.cs
        OrderRepository.cs
tests/
  MyApp.Tests/
    Features/
      Orders/
        OrderEndpointsTests.cs
        OrderRepositoryTests.cs
  MyApp.IntegrationTests/
    Features/
      Orders/
        OrderEndpointsIntegrationTests.cs
```

## Test Naming Convention

Format: `MethodName_Condition_ExpectedResult`

```csharp
// WRONG
[Fact]
public async Task TestCreateOrder() { }

[Fact]
public async Task ItWorks() { }

// CORRECT
[Fact]
public async Task CreateOrder_WithValidRequest_ReturnsCreatedOrder()

[Fact]
public async Task CreateOrder_WithEmptyItems_ReturnsBadRequest()

[Fact]
public async Task GetById_WhenOrderDoesNotExist_ReturnsNotFound()
```

## Unit Test Example

```csharp
// tests/MyApp.Tests/Features/Orders/OrderServiceTests.cs
namespace MyApp.Tests.Features.Orders;

public sealed class OrderServiceTests
{
    private readonly IOrderRepository _repository = Substitute.For<IOrderRepository>();
    private readonly OrderService _sut;

    private static readonly Faker<CreateOrderRequest> _requestFaker = new Faker<CreateOrderRequest>()
        .RuleFor(r => r.CustomerId, f => f.Random.Int(1, 10000))
        .RuleFor(r => r.Items, f => new Faker<OrderItemRequest>()
            .RuleFor(i => i.ProductId, g => g.Random.Int(1, 500))
            .RuleFor(i => i.Quantity, g => g.Random.Int(1, 10))
            .RuleFor(i => i.UnitPrice, g => g.Finance.Amount(1, 200))
            .Generate(f.Random.Int(1, 5)));

    public OrderServiceTests()
    {
        _sut = new OrderService(_repository);
    }

    [Fact]
    public async Task CreateOrder_WithValidRequest_ReturnsCreatedOrder()
    {
        // Arrange
        var request = _requestFaker.Generate();
        var expectedOrder = new Order
        {
            Id = 42,
            CustomerId = request.CustomerId,
            Items = request.Items.Select(i => new OrderItem
            {
                ProductId = i.ProductId,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice
            }).ToList()
        };

        _repository.CreateAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>())
            .Returns(expectedOrder);

        // Act
        var result = await _sut.CreateOrderAsync(request, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(42);
        result.CustomerId.Should().Be(request.CustomerId);
        result.Items.Should().HaveCount(request.Items.Count);

        await _repository.Received(1)
            .CreateAsync(Arg.Any<Order>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task CreateOrder_WithEmptyItems_ThrowsValidationException()
    {
        // Arrange
        var request = _requestFaker.Generate() with { Items = [] };

        // Act
        var act = () => _sut.CreateOrderAsync(request, CancellationToken.None);

        // Assert
        await act.Should().ThrowAsync<ValidationException>()
            .WithMessage("*at least one item*");
    }
}
```

## Integration Test Example

```csharp
// tests/MyApp.IntegrationTests/Features/Orders/OrderEndpointsIntegrationTests.cs
namespace MyApp.IntegrationTests.Features.Orders;

public sealed class OrderEndpointsIntegrationTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    private static readonly Faker<CreateOrderRequest> _requestFaker = new Faker<CreateOrderRequest>()
        .RuleFor(r => r.CustomerId, f => f.Random.Int(1, 10000))
        .RuleFor(r => r.Items, f => new Faker<OrderItemRequest>()
            .RuleFor(i => i.ProductId, g => g.Random.Int(1, 500))
            .RuleFor(i => i.Quantity, g => g.Random.Int(1, 10))
            .RuleFor(i => i.UnitPrice, g => g.Finance.Amount(1, 200))
            .Generate(f.Random.Int(1, 3)));

    public OrderEndpointsIntegrationTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateOrder_WithValidRequest_Returns201WithOrder()
    {
        // Arrange
        var request = _requestFaker.Generate();

        // Act
        var response = await _client.PostAsJsonAsync("/api/orders", request);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);

        var body = await response.Content.ReadFromJsonAsync<ApiResponse<OrderDto>>();
        body.Should().NotBeNull();
        body!.IsSuccess.Should().BeTrue();
        body.Data!.CustomerId.Should().Be(request.CustomerId);
        body.Data.Items.Should().HaveCount(request.Items.Count);
    }

    [Fact]
    public async Task GetById_WhenOrderDoesNotExist_Returns404()
    {
        // Act
        var response = await _client.GetAsync("/api/orders/999999");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}

// tests/MyApp.IntegrationTests/CustomWebApplicationFactory.cs
public sealed class CustomWebApplicationFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder()
        .WithImage("postgres:16-alpine")
        .Build();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<DbContextOptions<AppDbContext>>();
            services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(_postgres.GetConnectionString()));
        });
    }

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();
    }

    public new async Task DisposeAsync()
    {
        await _postgres.DisposeAsync();
    }
}
```

## Bogus Best Practices

- Define `Faker<T>` instances as `static readonly` fields — they are expensive to construct
- Use `Generate()` in each test to get unique data
- Never share generated instances across tests
- Use `.RuleFor()` for every required property
