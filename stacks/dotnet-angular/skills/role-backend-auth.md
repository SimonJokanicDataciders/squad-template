---
name: "cap-template-role-backend-auth"
description: "Authentication patterns for Fenster — ASP.NET Identity + JWT"
domain: "backend"
confidence: "high"
source: "manual"
---

> **Load this module when the task involves authentication, JWT, login, register, or user management.**

---

## 13. Authentication Patterns (ASP.NET Identity + JWT)

### Required NuGet Packages

Add to `Directory.Packages.props` and reference in the appropriate `.csproj` files:

```xml
<!-- In Directory.Packages.props -->
<PackageVersion Include="Microsoft.AspNetCore.Identity.EntityFrameworkCore" Version="10.0.2" />
<PackageVersion Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="10.0.2" />
```

### ApplicationUser Entity

```csharp
// File: src/Paso.Cap.Domain/Identity/ApplicationUser.cs
namespace Paso.Cap.Domain.Identity;

/// <summary>Application user aggregate root extending ASP.NET Core Identity.</summary>
public sealed class ApplicationUser : IdentityUser<Guid>, IAggregateRoot {
    /// <summary>UTC timestamp when the user account was created.</summary>
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.MinValue;
}
```

### ApplicationRole Entity

```csharp
// File: src/Paso.Cap.Domain/Identity/ApplicationRole.cs
namespace Paso.Cap.Domain.Identity;

/// <summary>Application role extending ASP.NET Core Identity.</summary>
public sealed class ApplicationRole : IdentityRole<Guid> { }
```

### DbContext Update

Inherit from `IdentityDbContext<ApplicationUser, ApplicationRole, Guid>` instead of plain `DbContext`:

```csharp
// File: src/Paso.Cap.Domain/ApplicationDbContext.cs
namespace Paso.Cap;

public sealed class ApplicationDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid> {
    public DbSet<WeatherData> WeatherData { get; set; }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder) {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasDefaultSchema("Identity");
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
    }
}
```

**Rule:** Identity tables live in the `"Identity"` schema. Override `OnModelCreating` and call `base.OnModelCreating` BEFORE `ApplyConfigurationsFromAssembly`.

### JwtSettings Options Class

```csharp
// File: src/Paso.Cap.Domain/Identity/JwtSettings.cs
namespace Paso.Cap.Domain.Identity;

/// <summary>Configuration options for JWT token generation.</summary>
public sealed class JwtSettings {
    /// <summary>Token issuer (e.g. the API base URL).</summary>
    public required string Issuer { get; init; }

    /// <summary>Token audience (e.g. the front-end client URL).</summary>
    public required string Audience { get; init; }

    /// <summary>Signing key — must be at least 256 bits (32 chars).</summary>
    public required string Key { get; init; }

    /// <summary>Token lifetime in minutes. Defaults to 60.</summary>
    public int ExpiryMinutes { get; init; } = 60;
}
```

### TokenService

```csharp
// File: src/Paso.Cap.Domain/Identity/TokenService.cs
namespace Paso.Cap.Domain.Identity;

/// <summary>Generates JWT bearer tokens for authenticated users.</summary>
public sealed class TokenService {
    private readonly JwtSettings _jwtSettings;

    public TokenService(IOptions<JwtSettings> jwtSettings) {
        _jwtSettings = jwtSettings.Value;
    }

    /// <summary>Generates a signed JWT for the given user and roles.</summary>
    public string GenerateToken(ApplicationUser user, IList<string> roles) {
        if (user is null) throw new ArgumentNullException(nameof(user));
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Key));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim> {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var token = new JwtSecurityToken(
            issuer: _jwtSettings.Issuer,
            audience: _jwtSettings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_jwtSettings.ExpiryMinutes),
            signingCredentials: credentials
        );
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
```

### IdentityServiceExtensions

Register identity, JWT bearer, and the `TokenService` inside a dedicated extension method. Follow the same pattern as `DomainServiceExtensions.cs`.

```csharp
// File: src/Paso.Cap.Domain/Identity/IdentityServiceExtensions.cs
namespace Paso.Cap.Domain.Identity;

/// <summary>Registers ASP.NET Identity and JWT authentication services.</summary>
public static class IdentityServiceExtensions {
    public static IHostApplicationBuilder AddIdentityServices(
        this IHostApplicationBuilder builder) {
        if (!Features.Authentication.IsEnabled) return builder;

        builder.Services
            .AddIdentity<ApplicationUser, ApplicationRole>(options => {
                options.Password.RequireDigit = true;
                options.Password.RequiredLength = 8;
                options.Password.RequireUppercase = true;
                options.Password.RequireNonAlphanumeric = false;
            })
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

        var jwtSettings = builder.Configuration
            .GetSection(nameof(JwtSettings))
            .Get<JwtSettings>()
            ?? throw new InvalidOperationException("JwtSettings configuration is missing.");

        builder.Services.AddSingleton(Options.Create(jwtSettings));
        builder.Services.AddScoped<TokenService>();

        builder.Services
            .AddAuthentication(options => {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options => {
                options.TokenValidationParameters = new TokenValidationParameters {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwtSettings.Issuer,
                    ValidAudience = jwtSettings.Audience,
                    IssuerSigningKey = new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes(jwtSettings.Key))
                };
            });

        builder.Services.AddAuthorization();
        return builder;
    }
}
```

### Auth DTOs

```csharp
// File: src/Paso.Cap.Domain/Identity/AuthDtos.cs
namespace Paso.Cap.Domain.Identity;

/// <summary>Payload for registering a new user account.</summary>
public sealed record RegisterDto {
    public required string Email { get; init; }
    public required string Password { get; init; }
    public required string DisplayName { get; init; }
}

/// <summary>Payload for authenticating an existing user.</summary>
public sealed record LoginDto {
    public required string Email { get; init; }
    public required string Password { get; init; }
}

/// <summary>Response returned after a successful register or login.</summary>
public sealed record AuthResponseDto {
    public required string Token { get; init; }
    public required DateTimeOffset ExpiresAt { get; init; }
    public required UserDto User { get; init; }
}

/// <summary>Public projection of a user account.</summary>
public sealed record UserDto {
    public required Guid Id { get; init; }
    public required string Email { get; init; }
    public required string DisplayName { get; init; }
    public required IReadOnlyList<string> Roles { get; init; }
}
```

### Auth Endpoint Pattern

```csharp
// File: src/Paso.Cap.Web/Endpoints/Auth.cs
namespace Paso.Cap.Endpoints;

/// <summary>Authentication endpoints: register, login, and current-user lookup.</summary>
public sealed class Auth : EndpointGroupBase {
    public override void Map(IEndpointRouteBuilder routeBuilder) {
        routeBuilder.MapPost("/register", Register).WithDefaultMetadata();
        routeBuilder.MapPost("/login", Login).WithDefaultMetadata();
        // Read-only "me" endpoint — no RequireAuthorization so it can return 401 cleanly
        routeBuilder.MapGet("/me", GetCurrentUser).WithDefaultMetadata().RequireAuthorization();
    }

    /// <summary>Registers a new user and returns a JWT token.</summary>
    private async Task<Created<AuthResponseDto>> Register(
        [FromBody] RegisterDto request,
        [FromServices] UserManager<ApplicationUser> userManager,
        [FromServices] TokenService tokenService,
        [FromServices] TimeProvider timeProvider,
        CancellationToken cancellationToken = default) {
        var user = new ApplicationUser {
            Id = Guid.NewGuid(),
            Email = request.Email,
            UserName = request.Email,
            CreatedAt = timeProvider.GetUtcNow()
        };
        var result = await userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded) throw new ArgumentException(
            string.Join(", ", result.Errors.Select(e => e.Description)));

        var roles = await userManager.GetRolesAsync(user);
        var token = tokenService.GenerateToken(user, roles);
        var response = new AuthResponseDto {
            Token = token,
            ExpiresAt = timeProvider.GetUtcNow().AddMinutes(60),
            User = new UserDto {
                Id = user.Id,
                Email = user.Email!,
                DisplayName = request.DisplayName,
                Roles = roles.ToList()
            }
        };
        return TypedResults.Created($"{this.GetPath()}/me", response);
    }

    /// <summary>Authenticates an existing user and returns a JWT token.</summary>
    private async Task<Ok<AuthResponseDto>> Login(
        [FromBody] LoginDto request,
        [FromServices] UserManager<ApplicationUser> userManager,
        [FromServices] SignInManager<ApplicationUser> signInManager,
        [FromServices] TokenService tokenService,
        [FromServices] TimeProvider timeProvider,
        CancellationToken cancellationToken = default) {
        var user = await userManager.FindByEmailAsync(request.Email)
            ?? throw new EntityNotFoundException();
        var result = await signInManager.CheckPasswordSignInAsync(user, request.Password, false);
        if (!result.Succeeded) throw new ArgumentException("Invalid credentials.");

        var roles = await userManager.GetRolesAsync(user);
        var token = tokenService.GenerateToken(user, roles);
        return TypedResults.Ok(new AuthResponseDto {
            Token = token,
            ExpiresAt = timeProvider.GetUtcNow().AddMinutes(60),
            User = new UserDto {
                Id = user.Id,
                Email = user.Email!,
                DisplayName = user.UserName ?? user.Email!,
                Roles = roles.ToList()
            }
        });
    }

    /// <summary>Returns the currently authenticated user's profile.</summary>
    private async Task<Ok<UserDto>> GetCurrentUser(
        ClaimsPrincipal principal,
        [FromServices] UserManager<ApplicationUser> userManager,
        CancellationToken cancellationToken = default) {
        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? throw new EntityNotFoundException();
        var user = await userManager.FindByIdAsync(userId)
            ?? throw new EntityNotFoundException();
        var roles = await userManager.GetRolesAsync(user);
        return TypedResults.Ok(new UserDto {
            Id = user.Id,
            Email = user.Email!,
            DisplayName = user.UserName ?? user.Email!,
            Roles = roles.ToList()
        });
    }
}
```

### Middleware Pipeline Order

Order matters. In `WebServiceExtensions.cs` or `Program.cs`:

```csharp
app.UseAuthentication();   // MUST come before UseAuthorization
app.UseAuthorization();
// ...then map endpoints
app.MapGroup("/api").MapEndpoints();
```

### Protecting Endpoints

- **Write endpoints** (`MapPost`, `MapPatch`, `MapDelete`): call `.RequireAuthorization()` after `.WithDefaultMetadata()`.
- **Read endpoints** (`MapGet`): leave open unless the resource is private.

```csharp
routeBuilder.MapPost("/", CreateOrder).WithDefaultMetadata().RequireAuthorization();
routeBuilder.MapGet("/", GetOrders).WithDefaultMetadata();  // open read
```

### Feature Flag

```csharp
// In Features.cs — add inside the Features static class
public static class Authentication {
    [FeatureSwitchDefinition("Authentication.IsEnabled")]
    public static bool IsEnabled => AppContext.TryGetSwitch("Authentication.IsEnabled", out bool isEnabled) ? isEnabled : true;
}
```

### Implementation Checklist (Auth)

- [ ] `ApplicationUser` is `sealed`, extends `IdentityUser<Guid>`, implements `IAggregateRoot`
- [ ] `ApplicationRole` is `sealed`, extends `IdentityRole<Guid>`
- [ ] `ApplicationDbContext` inherits `IdentityDbContext<ApplicationUser, ApplicationRole, Guid>`
- [ ] `HasDefaultSchema("Identity")` set on the model builder
- [ ] `base.OnModelCreating(modelBuilder)` called before `ApplyConfigurationsFromAssembly`
- [ ] `JwtSettings` bound from configuration — not hard-coded
- [ ] `TokenService` is `sealed`, registered as scoped
- [ ] Auth endpoint uses `EndpointGroupBase`, `.WithDefaultMetadata()`, typed results
- [ ] `UseAuthentication()` before `UseAuthorization()` in middleware pipeline
- [ ] `Features.Authentication.IsEnabled` gates the DI registration
- [ ] XML docs on all public methods
- [ ] `CancellationToken` accepted by all async methods
