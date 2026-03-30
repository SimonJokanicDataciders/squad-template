---
name: "cap-template-role-ops-secure"
description: "Security domain module for Ralph — exception handling, security action classes, secrets management. Load only when task involves security concerns."
domain: "operations/secure"
confidence: "high"
source: "split from cap-template-role-operations.md"
---

## Security

### Exception Handling Strategy (StatusCodeSelector)

**Configured in:** `src/Paso.Cap.Web/Infrastructure/WebServiceExtensions.cs`

```csharp
app.UseExceptionHandler(new ExceptionHandlerOptions {
    StatusCodeSelector = ex => ex switch {
        EntityNotFoundException => StatusCodes.Status404NotFound,
        ArgumentException       => StatusCodes.Status400BadRequest,
        ConcurrencyException    => StatusCodes.Status409Conflict,
        NotImplementedException => StatusCodes.Status501NotImplemented,
        _                       => StatusCodes.Status500InternalServerError
    }
});
```

**Pattern:** Throw domain exceptions in service layer, let the global handler map to HTTP status codes. Never return raw HTTP status codes from services.

**Custom exceptions in `src/Paso.Cap.Shared/`:**
- `EntityNotFoundException` -> 404
- `ConcurrencyException` -> 409

### Security Action Classes

**Code Security:**
- No hardcoded secrets, connection strings, or API keys
- Input validated at service entry points with `ArgumentException`
- Domain exceptions used (not raw HTTP status codes)
- `ConcurrencyException` caught from `DbUpdateConcurrencyException`
- No `FromSqlRaw` with string interpolation (SQL injection risk)

**API Security:**
- `ProblemDetails` enabled (RFC 7807) via `builder.Services.AddProblemDetails()`
- Exception details not leaked to clients in production
- Request timeouts via `UseRequestTimeouts()`
- CORS not set to `AllowAnyOrigin` with credentials
- `[Authorize]` on protected endpoints when auth configured

**Frontend Security:**
- No `innerHTML` with user-controlled data (XSS)
- No `bypassSecurityTrustHtml/Script/Url` usage
- No API keys in `environment.ts`
- HTTPS enforced for all API calls

**Infrastructure Security:**
- OIDC for Azure authentication (not stored service principal secrets)
- Database firewall rules configured per environment
- Pulumi secrets encrypted with passphrase
- GitHub Secrets used for CI/CD (not committed to repo)

**Data Security:**
- Immutable records prevent accidental mutation
- Read-only collections in DTOs
- Nullable reference types enabled (null safety)
- `is null` / `is not null` pattern (not `== null`)

### Secrets Management

| Secret Type | Where | How |
|-------------|-------|-----|
| Database passwords | Pulumi config | `pulumi config set --secret` |
| Azure credentials | GitHub Secrets | OIDC (no stored secrets) |
| Connection strings | `appsettings.json` | Only dev defaults; production via environment variables |
| API keys | Never in code | Environment variables or Azure Key Vault |

## Security Checklist

- [ ] No hardcoded secrets, connection strings, or API keys
- [ ] Input validated at service entry points
- [ ] Domain exceptions used (not raw HTTP status codes in services)
- [ ] `ConcurrencyException` caught from `DbUpdateConcurrencyException`
- [ ] `ProblemDetails` enabled for standardized error responses
- [ ] OIDC for Azure authentication
- [ ] Database firewall rules configured

See also: `cap-template-role-ops-deploy.md` for OIDC pipeline configuration.
