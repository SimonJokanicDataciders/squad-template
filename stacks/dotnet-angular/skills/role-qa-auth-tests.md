---
name: "cap-template-role-qa-auth-tests"
description: "Auth-aware and concurrency test patterns for Hockney — load on demand"
domain: "testing"
confidence: "high"
source: "manual"
---

Load this module when testing authenticated endpoints or concurrency behavior.

---

## Auth-Aware Integration Test Patterns

### Overview

When auth middleware (`AddAuthentication`, `AddAuthorization`, JWT bearer) is wired into the application, every test that hits a protected endpoint must supply a valid token. The `ApplicationFactory` + `ApplicationFactoryOptions` pattern already supports `ConfigureServices` and `ConfigureApplicationBuilder` hooks that are used to register auth for the test host.

### Test User Creation Helper

Create a helper that registers a test user via `UserManager<ApplicationUser>` and issues a JWT. This should live in a shared file such as `tests/Paso.Cap.IntegrationTests/Auth/AuthTestHelper.cs`.

```csharp
// File: tests/Paso.Cap.IntegrationTests/Auth/AuthTestHelper.cs
namespace Paso.Cap.Auth;

public static class AuthTestHelper {
    /// <summary>Registers a throwaway user and returns a signed JWT for integration tests.</summary>
    public static async Task<string> CreateTestUserAndGetTokenAsync(IServiceProvider services) {
        await using var scope = services.CreateAsyncScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var jwtService  = scope.ServiceProvider.GetRequiredService<IJwtTokenService>();

        var user = new ApplicationUser {
            UserName = $"test-{Guid.NewGuid():N}@example.com",
            Email    = $"test-{Guid.NewGuid():N}@example.com"
        };
        var result = await userManager.CreateAsync(user, "P@ssw0rd!");
        if (!result.Succeeded) {
            throw new InvalidOperationException($"Test user creation failed: {string.Join(", ", result.Errors.Select(e => e.Description))}");
        }
        return jwtService.GenerateToken(user);
    }
}
```

### Authenticated HttpClient Factory

Add an extension on `IHost` to create an `HttpClient` pre-loaded with a Bearer token:

```csharp
// File: tests/Paso.Cap.IntegrationTests/Auth/AuthHttpClientExtensions.cs
namespace Paso.Cap.Auth;

public static class AuthHttpClientExtensions {
    /// <summary>Creates a TestClient with a valid Bearer token attached.</summary>
    public static async Task<HttpClient> CreateAuthenticatedClientAsync(this IHost host) {
        var token  = await AuthTestHelper.CreateTestUserAndGetTokenAsync(host.Services);
        var client = host.GetTestClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
        return client;
    }
}
```

### Auth Test Patterns (Valid / Missing / Expired / Invalid JWT)

```csharp
// File: tests/Paso.Cap.IntegrationTests/WeatherForecasts/WeatherForecastAuthApiTests.cs
namespace Paso.Cap.WeatherForecasts;

[Collection(nameof(SharedCollection))]
public sealed class WeatherForecastAuthApiTests : IAsyncLifetime {
    private readonly ITestOutputHelper _testOutputHelper;
    private readonly DatabaseFactory   _databaseFactory;

    private IHost     _host          = null!;
    private HttpClient _authClient   = null!;
    private HttpClient _anonClient   = null!;

    public WeatherForecastAuthApiTests(ITestOutputHelper testOutputHelper, DatabaseFactory databaseFactory) {
        _testOutputHelper = testOutputHelper;
        _databaseFactory  = databaseFactory;
    }

    public async ValueTask InitializeAsync() {
        _host = await ApplicationFactory.CreateHostAsync(new ApplicationFactoryOptions {
            DatabaseFactory          = _databaseFactory,
            ConfigureApplicationBuilder = x => x.AddWebApi(),
            ConfigureApplication     = x => x.MapWebApi(),
            Seeder                   = WeatherForecastOptions.Seeder()
        });
        _authClient = await _host.CreateAuthenticatedClientAsync();
        _anonClient = _host.GetTestClient();
    }

    // --- Happy path ---
    [Fact]
    public async Task GetForecastById_WithValidToken_ReturnsSuccess() {
        var response = await _authClient.GetAsync("/api/weatherforecast/b988378b-5e80-e096-c4d9-077c47d421db");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // --- Unauthenticated ---
    [Fact]
    public async Task GetForecastById_WithoutToken_Returns401() {
        var response = await _anonClient.GetAsync("/api/weatherforecast/b988378b-5e80-e096-c4d9-077c47d421db");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // --- Expired token ---
    [Fact]
    public async Task GetForecastById_WithExpiredToken_Returns401() {
        var expiredClient = _host.GetTestClient();
        expiredClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0IiwiZXhwIjoxfQ.expired");

        var response = await expiredClient.GetAsync("/api/weatherforecast/b988378b-5e80-e096-c4d9-077c47d421db");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // --- Malformed token ---
    [Fact]
    public async Task GetForecastById_WithInvalidToken_Returns401() {
        var badClient = _host.GetTestClient();
        badClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", "not.a.valid.jwt");

        var response = await badClient.GetAsync("/api/weatherforecast/b988378b-5e80-e096-c4d9-077c47d421db");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    public async ValueTask DisposeAsync() {
        _authClient.Dispose();
        _anonClient.Dispose();
        await _host.StopAsync();
        _host.Dispose();
    }
}
```

### Registration and Login Integration Tests (Auth Flow)

```csharp
// File: tests/Paso.Cap.IntegrationTests/Auth/AuthFlowApiTests.cs
namespace Paso.Cap.Auth;

[Collection(nameof(SharedCollection))]
public sealed class AuthFlowApiTests : IAsyncLifetime {
    private readonly DatabaseFactory _databaseFactory;
    private IHost      _host   = null!;
    private HttpClient _client = null!;

    public AuthFlowApiTests(DatabaseFactory databaseFactory) {
        _databaseFactory = databaseFactory;
    }

    [Fact]
    public async Task Register_WithValidCredentials_Returns200() {
        var dto = new RegisterRequestDto {
            Email    = $"newuser-{Guid.NewGuid():N}@example.com",
            Password = "P@ssw0rd!"
        };

        var response = await _client.PostAsJsonAsync("/api/auth/register", dto);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Login_WithValidCredentials_ReturnsJwt() {
        var email    = $"login-{Guid.NewGuid():N}@example.com";
        var password = "P@ssw0rd!";

        await _client.PostAsJsonAsync("/api/auth/register", new RegisterRequestDto { Email = email, Password = password });
        var loginResponse = await _client.PostAsJsonAsync("/api/auth/login", new LoginRequestDto { Email = email, Password = password });

        Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);
        var body = await loginResponse.Content.ReadFromJsonAsync<LoginResponseDto>();
        Assert.NotNull(body);
        Assert.False(string.IsNullOrWhiteSpace(body!.Token));
    }

    public async ValueTask InitializeAsync() {
        _host   = await ApplicationFactory.CreateHostAsync(new ApplicationFactoryOptions {
            DatabaseFactory             = _databaseFactory,
            ConfigureApplicationBuilder = x => x.AddWebApi(),
            ConfigureApplication        = x => x.MapWebApi()
        });
        _client = _host.GetTestClient();
    }

    public async ValueTask DisposeAsync() {
        _client.Dispose();
        await _host.StopAsync();
        _host.Dispose();
    }
}
```

### UserGenerator (Bogus Pattern)

```csharp
// File: tests/Paso.Cap.IntegrationTests/Auth/UserGenerator.cs
namespace Paso.Cap.Auth;

public sealed class UserGenerator {
    private readonly Faker<RegisterRequestDto> _faker;

    public UserGenerator() {
        Randomizer.Seed = new Random(77741);

        _faker = new Faker<RegisterRequestDto>()
            .RuleFor(u => u.Email,    f => f.Internet.Email())
            .RuleFor(u => u.Password, _ => "P@ssw0rd!");
    }

    public List<RegisterRequestDto> GenerateUsers(int count = 5) => _faker.Generate(count);
}
```

### Auth Test Checklist

- [ ] Authenticated happy-path test covers every protected endpoint
- [ ] 401 test exists for every protected endpoint (no token, expired token, invalid token)
- [ ] `UserGenerator` uses Bogus with a fixed seed (not hardcoded strings)
- [ ] `CreateAuthenticatedClientAsync` used — never hardcode a token
- [ ] Auth tests are in `[Collection(nameof(SharedCollection))]` (shares the Testcontainers instance)

---

## Concurrency Conflict Test Patterns

### Overview

EF Core uses `RowVersion` byte arrays for optimistic concurrency. When two requests read the same entity and then both try to save, the second save throws `DbUpdateConcurrencyException`. The API layer translates this to **409 Conflict**. Tests must reproduce this race condition deterministically.

### Service-Layer Concurrency Test

The key insight: open **two separate `DbContext` instances** (two scopes), read the entity in both, update through one scope to advance the `RowVersion`, then attempt the update through the stale scope.

```csharp
// File: tests/Paso.Cap.IntegrationTests/WeatherForecasts/WeatherForecastConcurrencyServiceTests.cs
namespace Paso.Cap.WeatherForecasts;

[Collection(nameof(SharedCollection))]
public sealed class WeatherForecastConcurrencyServiceTests : IAsyncLifetime {
    private readonly ITestOutputHelper _testOutputHelper;
    private readonly DatabaseFactory   _databaseFactory;
    private IHost _host = null!;

    private static readonly Guid SeedId = Guid.Parse("b988378b-5e80-e096-c4d9-077c47d421db");

    public WeatherForecastConcurrencyServiceTests(
        ITestOutputHelper testOutputHelper,
        DatabaseFactory databaseFactory) {
        _testOutputHelper = testOutputHelper;
        _databaseFactory  = databaseFactory;
    }

    [Fact]
    public async Task UpdateForecast_StaleRowVersion_ThrowsDbUpdateConcurrencyException() {
        // Read the entity in scope A (gets RowVersion = v1)
        await using var scopeA = _host.Services.CreateAsyncScope();
        var dbA      = scopeA.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var entityA  = await dbA.WeatherForecasts.FindAsync(SeedId);
        Assert.NotNull(entityA);

        // Update the entity through scope B — RowVersion advances to v2
        await using var scopeB = _host.Services.CreateAsyncScope();
        var dbB     = scopeB.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var entityB = await dbB.WeatherForecasts.FindAsync(SeedId);
        Assert.NotNull(entityB);
        entityB!.TemperatureC = 99;
        await dbB.SaveChangesAsync();

        // Attempt to save through the stale scope A (still has RowVersion = v1)
        entityA!.TemperatureC = -99;
        await Assert.ThrowsAsync<DbUpdateConcurrencyException>(
            async () => await dbA.SaveChangesAsync()
        );
    }

    public async ValueTask InitializeAsync() {
        _host = await ApplicationFactory.CreateHostAsync(new ApplicationFactoryOptions {
            DatabaseFactory = _databaseFactory,
            Seeder          = WeatherForecastOptions.Seeder()
        });
    }

    public async ValueTask DisposeAsync() {
        await _host.StopAsync();
        _host.Dispose();
    }
}
```

### API-Layer Concurrency Test (409 via PATCH with stale ETag/RowVersion)

When the API exposes a `RowVersion` or `ETag` header, clients must send it back on updates. A stale value returns **409 Conflict**.

```csharp
// File: tests/Paso.Cap.IntegrationTests/WeatherForecasts/WeatherForecastConcurrencyApiTests.cs
namespace Paso.Cap.WeatherForecasts;

[Collection(nameof(SharedCollection))]
public sealed class WeatherForecastConcurrencyApiTests : IAsyncLifetime {
    private readonly ITestOutputHelper _testOutputHelper;
    private readonly DatabaseFactory   _databaseFactory;
    private IHost      _host   = null!;
    private HttpClient _client = null!;

    private static readonly Guid SeedId = Guid.Parse("b988378b-5e80-e096-c4d9-077c47d421db");

    public WeatherForecastConcurrencyApiTests(
        ITestOutputHelper testOutputHelper,
        DatabaseFactory databaseFactory) {
        _testOutputHelper = testOutputHelper;
        _databaseFactory  = databaseFactory;
    }

    [Fact]
    public async Task UpdateForecast_StaleRowVersion_Returns409Conflict() {
        // Step 1: GET — capture current ETag / RowVersion from response header
        var getResponse = await _client.GetAsync($"/api/weatherforecast/{SeedId}");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
        var etag = getResponse.Headers.ETag?.Tag ?? "\"stale\"";

        // Step 2: A concurrent user updates the entity, advancing the RowVersion
        var concurrentPatch = new JsonPatchDocument<UpdateWeatherDataDto>();
        concurrentPatch.Replace(x => x.TemperatureC, 99);
        var concurrentRequest = new HttpRequestMessage(HttpMethod.Patch, $"/api/weatherforecast/{SeedId}") {
            Content = JsonContent.Create(concurrentPatch)
        };
        concurrentRequest.Headers.IfMatch.ParseAdd(etag);
        var concurrentResponse = await _client.SendAsync(concurrentRequest);
        Assert.Equal(HttpStatusCode.OK, concurrentResponse.StatusCode);

        // Step 3: Attempt a PATCH with the now-stale ETag
        var staleRequest = new HttpRequestMessage(HttpMethod.Patch, $"/api/weatherforecast/{SeedId}") {
            Content = JsonContent.Create(concurrentPatch)
        };
        staleRequest.Headers.IfMatch.ParseAdd(etag); // still the old ETag
        var staleResponse = await _client.SendAsync(staleRequest);

        Assert.Equal(HttpStatusCode.Conflict, staleResponse.StatusCode);
    }

    public async ValueTask InitializeAsync() {
        _host = await ApplicationFactory.CreateHostAsync(new ApplicationFactoryOptions {
            DatabaseFactory             = _databaseFactory,
            ConfigureApplicationBuilder = x => x.AddWebApi(),
            ConfigureApplication        = x => x.MapWebApi(),
            Seeder                      = WeatherForecastOptions.Seeder()
        });
        _client = _host.GetTestClient();
    }

    public async ValueTask DisposeAsync() {
        _client.Dispose();
        await _host.StopAsync();
        _host.Dispose();
    }
}
```

### Concurrency Test Checklist

- [ ] Two separate `DbContext` scopes used — never reuse the same `DbContext` across the simulated concurrent users
- [ ] The "winning" update is saved and its `DbUpdateConcurrencyException` does NOT propagate
- [ ] The "losing" update asserts `DbUpdateConcurrencyException` at the service layer OR `409 Conflict` at the API layer
- [ ] Test uses seeded data (entity with known ID) — `WeatherForecastOptions.Seeder()` already seeds `b988378b-5e80-e096-c4d9-077c47d421db`
- [ ] `DropDatabase = true` (default) ensures each class starts clean
